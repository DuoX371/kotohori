package com.kotohori

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Opens videos/subtitles in place via the system document picker and keeps a
 * persistable read grant, so "Continue" can reopen them after a restart.
 * (file_picker copies every picked file into the cache — 600 MB+ per episode.)
 */
class Documents(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "kotohori/documents"
        const val REQUEST_CODE = 4022
    }

    private val io = Executors.newSingleThreadExecutor()
    private var pending: Pair<MethodChannel.Result, Set<String>>? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> {
                pending?.first?.success(null)
                pending = result to (call.argument<List<String>>("keep") ?: emptyList()).toSet()
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, call.argument<List<String>>("mimeTypes")!!.toTypedArray())
                }
                activity.startActivityForResult(intent, REQUEST_CODE)
            }
            "read" -> io.execute {
                try {
                    val bytes = activity.contentResolver.openInputStream(Uri.parse(call.argument<String>("uri")!!))!!
                        .use { it.readBytes() }
                    activity.runOnUiThread { result.success(bytes) }
                } catch (e: Exception) {
                    activity.runOnUiThread { result.error("read", e.message ?: e.toString(), null) }
                }
            }
            // Raw read-only fd + size for Dart, which reads it with pread (e.g. to scan an MKV's subtitles).
            "openFd" -> io.execute {
                try {
                    val pfd = activity.contentResolver.openFileDescriptor(Uri.parse(call.argument<String>("uri")!!), "r")!!
                    val size = pfd.statSize
                    val fd = pfd.detachFd()
                    activity.runOnUiThread { result.success(mapOf("fd" to fd, "size" to size)) }
                } catch (e: Exception) {
                    activity.runOnUiThread { result.error("open", e.message ?: e.toString(), null) }
                }
            }
            "closeFd" -> {
                ParcelFileDescriptor.adoptFd(call.argument<Int>("fd")!!).close()
                result.success(null)
            }
            // False once the file was moved, renamed, deleted or its grant is gone.
            "canOpen" -> io.execute {
                val ok = try {
                    activity.contentResolver.openFileDescriptor(Uri.parse(call.argument<String>("uri")!!), "r")?.close() != null
                } catch (_: Exception) {
                    false
                }
                activity.runOnUiThread { result.success(ok) }
            }
            else -> result.notImplemented()
        }
    }

    /** Called from MainActivity.onActivityResult. */
    fun onResult(resultCode: Int, data: Intent?) {
        val (result, keep) = pending ?: return
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) return result.success(null)
        val resolver = activity.contentResolver
        try {
            resolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
            // Provider doesn't offer persistable grants: works now, "Continue" may not later.
        }
        // Android caps persisted grants per app; drop the ones nothing refers to any more.
        for (p in resolver.persistedUriPermissions) {
            val s = p.uri.toString()
            if (p.uri != uri && s !in keep) resolver.releasePersistableUriPermission(p.uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        var name = uri.lastPathSegment ?: "file"
        var size = -1L
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                c.getString(0)?.let { name = it }
                if (!c.isNull(1)) size = c.getLong(1)
            }
        }
        result.success(mapOf("uri" to uri.toString(), "name" to name, "size" to size))
    }
}
