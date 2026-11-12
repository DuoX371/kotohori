package com.kotohori

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/** Card media: sentence-audio clips and JPEG encoding (dart:ui has no JPEG encoder). */
class MediaTools(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "kotohori/media"
    }

    // Screenshot encoding and audio clipping for one card run side by side.
    private val io = Executors.newFixedThreadPool(3)
    private val main = Handler(Looper.getMainLooper())

    private var preview: MediaPlayer? = null

    /** Card-editor preview. Android's MediaPlayer (what AnkiDroid uses) plays very short
     *  clips like 0.6 s word audio in full; mpv clips their start while its output opens. */
    private fun playAudio(path: String) {
        preview?.release()
        preview = MediaPlayer().apply {
            setDataSource(path)
            setOnCompletionListener { it.release(); if (preview === it) preview = null }
            prepare()
            start()
        }
    }

    fun release() {
        preview?.release()
        preview = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "playAudio") {
            return try {
                playAudio(call.argument<String>("path")!!)
                result.success(null)
            } catch (e: Exception) {
                result.error("media", e.message ?: e.toString(), null)
            }
        }
        if (call.method == "stopAudio") {
            release()
            return result.success(null)
        }
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "clipAudio" -> {
                        clipAudio(
                            call.argument<String>("source")!!,
                            call.argument<Number>("startMs")!!.toLong() * 1000,
                            call.argument<Number>("endMs")!!.toLong() * 1000,
                            File(call.argument<String>("out")!!),
                            (call.argument<Number>("padEndMs")?.toLong() ?: 0) * 1000,
                        )
                        null
                    }
                    "encodeJpeg" -> {
                        val w = call.argument<Int>("width")!!
                        val h = call.argument<Int>("height")!!
                        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                        bmp.copyPixelsFromBuffer(ByteBuffer.wrap(call.argument<ByteArray>("rgba")!!))
                        FileOutputStream(call.argument<String>("out")!!).use {
                            bmp.compress(Bitmap.CompressFormat.JPEG, call.argument<Int>("quality") ?: 85, it)
                        }
                        bmp.recycle()
                        null
                    }
                    else -> throw UnsupportedOperationException(call.method)
                }
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("media", e.message ?: e.toString(), null) }
            }
        }
    }

    /**
     * Writes [startUs]..[endUs] of the first audio track of [source] (file path or
     * content:// URI) to [out] as AAC in .m4a. AAC is copied as-is (exact, instant);
     * anything else Android can decode (Opus, FLAC, Vorbis, MP3…) is re-encoded to AAC.
     */
    /** [padEndUs] > 0 appends that much silence (forces re-encoding). */
    private fun clipAudio(source: String, startUs: Long, endUs: Long, out: File, padEndUs: Long = 0) {
        out.parentFile?.mkdirs()
        val extractor = MediaExtractor()
        try {
            if (source.startsWith("content://")) extractor.setDataSource(context, Uri.parse(source), null)
            else extractor.setDataSource(source)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw IllegalStateException("This video has no audio track")
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            if (padEndUs == 0L && format.getString(MediaFormat.KEY_MIME) == MediaFormat.MIMETYPE_AUDIO_AAC) {
                copy(extractor, format, startUs, endUs, out)
            } else {
                transcode(extractor, format, startUs, endUs, out, padEndUs)
            }
        } finally {
            extractor.release()
        }
    }

    private fun copy(ex: MediaExtractor, format: MediaFormat, startUs: Long, endUs: Long, out: File) {
        val muxer = MediaMuxer(out.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            val dst = muxer.addTrack(format)
            muxer.start()
            val buf = ByteBuffer.allocate(maxOf(format.getIntOrZero(MediaFormat.KEY_MAX_INPUT_SIZE), 256 * 1024))
            val info = MediaCodec.BufferInfo()
            var wrote = false
            while (true) {
                val size = ex.readSampleData(buf, 0)
                if (size < 0 || ex.sampleTime > endUs) break
                if (ex.sampleTime >= startUs) {
                    info.set(0, size, ex.sampleTime - startUs, MediaCodec.BUFFER_FLAG_KEY_FRAME)
                    muxer.writeSampleData(dst, buf, info)
                    wrote = true
                }
                ex.advance()
            }
            if (!wrote) throw IllegalStateException("No audio in that time range")
            muxer.stop()
        } finally {
            muxer.release()
        }
    }

    private fun transcode(ex: MediaExtractor, inFormat: MediaFormat, startUs: Long, endUs: Long, out: File, padEndUs: Long) {
        val mime = inFormat.getString(MediaFormat.KEY_MIME)!!
        val decoder = try {
            MediaCodec.createDecoderByType(mime).apply { configure(inFormat, null, null, 0); start() }
        } catch (e: Exception) {
            throw IllegalStateException("This phone can't decode the video's audio ($mime)")
        }
        val muxer = MediaMuxer(out.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var encoder: MediaCodec? = null
        var track = -1
        var bytesPerSec = 0L // 16-bit PCM from the decoder
        var pcmBytes = 0L
        val decInfo = MediaCodec.BufferInfo()
        val encInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var decodeDone = false
        var eosQueued = false
        var padLeft = -1L // silence still to append, in PCM bytes; set once the format is known
        var encodeDone = false

        // Writes whatever the encoder has finished to the muxer.
        fun drainEncoder() {
            val enc = encoder ?: return
            while (true) {
                val o = enc.dequeueOutputBuffer(encInfo, 0)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    track = muxer.addTrack(enc.outputFormat)
                    muxer.start()
                } else if (o >= 0) {
                    if (encInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && encInfo.size > 0 && track >= 0) {
                        muxer.writeSampleData(track, enc.getOutputBuffer(o)!!, encInfo)
                    }
                    enc.releaseOutputBuffer(o, false)
                    if (encInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        encodeDone = true
                        return
                    }
                } else {
                    return
                }
            }
        }

        try {
            while (!encodeDone) {
                // 1. Compressed samples -> decoder.
                if (!inputDone) {
                    val i = decoder.dequeueInputBuffer(10_000)
                    if (i >= 0) {
                        val size = ex.readSampleData(decoder.getInputBuffer(i)!!, 0)
                        if (size < 0 || ex.sampleTime > endUs) {
                            decoder.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(i, 0, size, ex.sampleTime, 0)
                            ex.advance()
                        }
                    }
                }
                // 2. PCM inside the range -> AAC encoder.
                if (!decodeDone) {
                    val o = decoder.dequeueOutputBuffer(decInfo, 10_000)
                    if (o >= 0) {
                        if (encoder == null) {
                            val pcm = decoder.outputFormat
                            val rate = pcm.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            val channels = pcm.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            bytesPerSec = rate.toLong() * channels * 2
                            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).apply {
                                val f = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, rate, channels)
                                f.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                                f.setInteger(MediaFormat.KEY_BIT_RATE, 96_000)
                                configure(f, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                                start()
                            }
                        }
                        val enc = encoder!!
                        val src = decoder.getOutputBuffer(o)!!
                        if (decInfo.size > 0 && decInfo.presentationTimeUs >= startUs) {
                            src.position(decInfo.offset)
                            src.limit(decInfo.offset + decInfo.size)
                            while (src.hasRemaining()) {
                                val e = enc.dequeueInputBuffer(10_000)
                                if (e < 0) { drainEncoder(); continue }
                                val dst = enc.getInputBuffer(e)!!
                                val n = minOf(dst.remaining(), src.remaining())
                                dst.put(src.duplicate().apply { limit(position() + n) })
                                src.position(src.position() + n)
                                enc.queueInputBuffer(e, 0, n, pcmBytes * 1_000_000 / bytesPerSec, 0)
                                pcmBytes += n
                            }
                        }
                        decoder.releaseOutputBuffer(o, false)
                        if (decInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) decodeDone = true
                    }
                }
                // 3. End the encoder once decoding is done, then write its output.
                val enc = encoder
                if (enc == null) {
                    if (decodeDone) throw IllegalStateException("No audio in that time range")
                    continue
                }
                if (decodeDone && padLeft < 0) padLeft = padEndUs * bytesPerSec / 1_000_000 / 4 * 4
                if (decodeDone && padLeft > 0) {
                    val e = enc.dequeueInputBuffer(10_000)
                    if (e >= 0) {
                        val dst = enc.getInputBuffer(e)!!
                        val n = minOf(dst.remaining().toLong(), padLeft).toInt() / 4 * 4
                        dst.put(ByteArray(n))
                        enc.queueInputBuffer(e, 0, n, pcmBytes * 1_000_000 / bytesPerSec, 0)
                        pcmBytes += n
                        padLeft -= n
                    }
                    drainEncoder()
                    continue
                }
                if (decodeDone && !eosQueued) {
                    val e = enc.dequeueInputBuffer(10_000)
                    if (e >= 0) {
                        enc.queueInputBuffer(e, 0, 0, pcmBytes * 1_000_000 / bytesPerSec, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        eosQueued = true
                    }
                }
                drainEncoder()
            }
            if (track < 0) throw IllegalStateException("No audio in that time range")
            muxer.stop()
        } finally {
            decoder.release()
            encoder?.release()
            muxer.release()
        }
    }

    private fun MediaFormat.getIntOrZero(key: String) = if (containsKey(key)) getInteger(key) else 0
}
