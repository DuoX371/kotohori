import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Random access to a file's bytes (a whole MKV is far too big to load).
abstract interface class ByteSource {
  int get length;

  /// Up to [count] bytes at [offset] (fewer at the end of the file).
  Uint8List read(int offset, int count);
}

class FileByteSource implements ByteSource {
  FileByteSource(this._file) : length = _file.lengthSync();
  final RandomAccessFile _file;
  @override
  final int length;

  @override
  Uint8List read(int offset, int count) {
    _file.setPositionSync(offset);
    return _file.readSync(count);
  }
}

class MemoryByteSource implements ByteSource {
  MemoryByteSource(this.bytes);
  final Uint8List bytes;
  @override
  int get length => bytes.length;
  @override
  Uint8List read(int offset, int count) => Uint8List.sublistView(
    bytes,
    offset.clamp(0, bytes.length),
    (offset + count).clamp(0, bytes.length),
  );
}

/// A subtitle track inside a Matroska file.
class MkvTrack {
  MkvTrack({
    required this.number,
    required this.codec,
    this.language,
    this.name,
    this.codecPrivate,
    this.compression,
  });
  final int number;

  /// e.g. `S_TEXT/ASS`, `S_TEXT/UTF8`, `S_HDMV/PGS` (image-based: not usable).
  final String codec;
  final String? language;
  final String? name;
  final Uint8List? codecPrivate;

  /// (algorithm, settings): 0 = zlib, 3 = header stripping.
  final (int, Uint8List)? compression;

  bool get isText => codec.startsWith('S_TEXT/');
}

class MkvBlock {
  const MkvBlock(this.start, this.duration, this.data);
  final Duration start;
  final Duration? duration;
  final Uint8List data;
}

class MkvSubtitles {
  const MkvSubtitles(this.tracks, this.blocks);

  /// Subtitle tracks only, in file order.
  final List<MkvTrack> tracks;

  /// Text-track blocks by track number (empty when read with `tracksOnly`).
  final Map<int, List<MkvBlock>> blocks;
}

// Element IDs (with their length-marker bits, as written in the file).
const _ebml = 0x1A45DFA3,
    _segment = 0x18538067,
    _info = 0x1549A966,
    _timestampScale = 0x2AD7B1;
const _tracks = 0x1654AE6B,
    _trackEntry = 0xAE,
    _trackNumber = 0xD7,
    _trackType = 0x83;
const _codecId = 0x86,
    _codecPrivate = 0x63A2,
    _language = 0x22B59C,
    _languageBcp47 = 0x22B59D,
    _name = 0x536E;
const _contentEncodings = 0x6D80,
    _contentEncoding = 0x6240,
    _contentCompression = 0x5034;
const _compAlgo = 0x4254, _compSettings = 0x4255;
const _cluster = 0x1F43B675,
    _clusterTimestamp = 0xE7,
    _simpleBlock = 0xA3,
    _blockGroup = 0xA0;
const _block = 0xA1, _blockDuration = 0x9B;
const _subtitleTrackType = 0x11;

/// Reads the subtitle tracks of a Matroska (.mkv/.mka/.webm) file and, unless
/// [tracksOnly], every block of its text subtitle tracks.
///
/// Walks the element headers only: video and audio frames are skipped, not
/// read, so a 600 MB episode costs one small read per frame.
/// Throws [FormatException] for files that aren't Matroska.
MkvSubtitles readMkvSubtitles(ByteSource src, {bool tracksOnly = false}) {
  final r = _Reader(src);
  final (id, size, start) = r.header(0);
  if (id != _ebml) throw const FormatException('Not a Matroska (MKV) file');
  var pos = start + (size ?? 0);
  final (segId, segSize, segStart) = r.header(pos);
  if (segId != _segment) {
    throw const FormatException('Not a Matroska (MKV) file');
  }
  final segEnd = segSize == null
      ? src.length
      : (segStart + segSize).clamp(0, src.length);

  var scale = 1000000; // ns per timestamp tick
  final tracks = <MkvTrack>[];
  final blocks = <int, List<MkvBlock>>{};
  var textTracks = <int, MkvTrack>{};
  var seenTracks = false;
  var clusterTime = 0;
  // A BlockGroup's Block comes before its BlockDuration.
  var groupEnd = -1;
  (int, int, Uint8List)? pending; // (track, tick, data)
  int? pendingDuration;

  void flush() {
    final p = pending;
    if (p == null) return;
    final track = textTracks[p.$1]!;
    blocks[p.$1]!.add(
      MkvBlock(
        _ticks(p.$2, scale),
        pendingDuration == null ? null : _ticks(pendingDuration!, scale),
        _decode(p.$3, track.compression),
      ),
    );
    pending = null;
    pendingDuration = null;
  }

  pos = segStart;
  while (pos < segEnd) {
    if (groupEnd >= 0 && pos >= groupEnd) {
      flush();
      groupEnd = -1;
    }
    final (id, size, data) = r.header(pos);
    if (id < 0) break; // truncated file
    switch (id) {
      case _info when size != null:
        scale = _readInfo(r, data, data + size) ?? scale;
      case _tracks when size != null:
        tracks.addAll(_readTracks(r, data, data + size));
        seenTracks = true;
        textTracks = {
          for (final t in tracks.where((t) => t.isText)) t.number: t,
        };
        for (final n in textTracks.keys) {
          blocks[n] = [];
        }
      case _cluster:
        if (tracksOnly || (seenTracks && textTracks.isEmpty)) {
          return MkvSubtitles(tracks, blocks);
        }
        pos = data; // descend: its children are read inline
        continue;
      case _blockGroup when size != null:
        flush();
        groupEnd = data + size;
        pos = data;
        continue;
      case _clusterTimestamp when size != null:
        clusterTime = r.uint(data, size);
      case (_simpleBlock || _block) when size != null:
        final b = _readBlockHeader(r, data);
        if (b != null && textTracks.containsKey(b.$1)) {
          final payload = r.bytes(data + b.$3, size - b.$3);
          if (id == _simpleBlock) {
            flush();
            pending = (b.$1, clusterTime + b.$2, payload);
            flush();
          } else {
            pending = (b.$1, clusterTime + b.$2, payload);
          }
        }
      case _blockDuration when size != null:
        pendingDuration = r.uint(data, size);
    }
    if (size == null) {
      pos = data; // unknown size: treat as a container
    } else {
      pos = data + size;
    }
  }
  flush();
  return MkvSubtitles(tracks, blocks);
}

Duration _ticks(int ticks, int scaleNs) =>
    Duration(microseconds: ticks * scaleNs ~/ 1000);

Uint8List _decode(Uint8List data, (int, Uint8List)? compression) =>
    switch (compression) {
      null => data,
      (0, _) => Uint8List.fromList(zlib.decode(data)),
      (3, final header) => Uint8List.fromList([...header, ...data]),
      _ => data,
    };

int? _readInfo(_Reader r, int pos, int end) {
  while (pos < end) {
    final (id, size, data) = r.header(pos);
    if (id < 0 || size == null) return null;
    if (id == _timestampScale) return r.uint(data, size);
    pos = data + size;
  }
  return null;
}

List<MkvTrack> _readTracks(_Reader r, int pos, int end) {
  final out = <MkvTrack>[];
  while (pos < end) {
    final (id, size, data) = r.header(pos);
    if (id < 0 || size == null) break;
    if (id == _trackEntry) {
      final t = _readTrackEntry(r, data, data + size);
      if (t != null) out.add(t);
    }
    pos = data + size;
  }
  return out;
}

MkvTrack? _readTrackEntry(_Reader r, int pos, int end) {
  int? number, type;
  String codec = '';
  String? language, bcp47, name;
  Uint8List? private;
  (int, Uint8List)? compression;
  while (pos < end) {
    final (id, size, data) = r.header(pos);
    if (id < 0 || size == null) break;
    switch (id) {
      case _trackNumber:
        number = r.uint(data, size);
      case _trackType:
        type = r.uint(data, size);
      case _codecId:
        codec = r.string(data, size);
      case _codecPrivate:
        private = r.bytes(data, size);
      case _language:
        language = r.string(data, size);
      case _languageBcp47:
        bcp47 = r.string(data, size);
      case _name:
        name = r.string(data, size);
      case _contentEncodings:
        compression = _readCompression(r, data, data + size);
    }
    pos = data + size;
  }
  if (number == null || type != _subtitleTrackType) return null;
  if (private != null && compression != null) {
    try {
      private = _decode(private, compression);
    } on FormatException {
      private = null;
    }
  }
  return MkvTrack(
    number: number,
    codec: codec,
    language:
        bcp47 ?? language ?? 'eng', // Matroska's default language is English
    name: name,
    codecPrivate: private,
    compression: compression,
  );
}

/// The first ContentCompression found (nested ContentEncoding → ContentCompression).
(int, Uint8List)? _readCompression(_Reader r, int pos, int end) {
  while (pos < end) {
    final (id, size, data) = r.header(pos);
    if (id < 0 || size == null) return null;
    if (id == _contentEncoding) return _readCompression(r, data, data + size);
    if (id == _contentCompression) {
      var algo = 0;
      var settings = Uint8List(0);
      var p = data;
      while (p < data + size) {
        final (cid, csize, cdata) = r.header(p);
        if (cid < 0 || csize == null) break;
        if (cid == _compAlgo) algo = r.uint(cdata, csize);
        if (cid == _compSettings) settings = r.bytes(cdata, csize);
        p = cdata + csize;
      }
      return (algo, settings);
    }
    pos = data + size;
  }
  return null;
}

/// (track number, relative tick, header length) — null for laced blocks,
/// which subtitle tracks don't use.
(int, int, int)? _readBlockHeader(_Reader r, int pos) {
  final h = r.bytes(pos, 12);
  if (h.isEmpty) return null;
  final len = _vintLength(h[0]);
  if (len == 0 || len + 3 > h.length) return null;
  var track = h[0] & (0xFF >> len);
  for (var i = 1; i < len; i++) {
    track = (track << 8) | h[i];
  }
  final rel = ByteData.sublistView(h, len, len + 2).getInt16(0);
  final flags = h[len + 2];
  if (flags & 0x06 != 0) return null; // laced
  return (track, rel, len + 3);
}

int _vintLength(int first) {
  for (var i = 0; i < 8; i++) {
    if (first & (0x80 >> i) != 0) return i + 1;
  }
  return 0;
}

/// Small read-ahead window: consecutive headers (e.g. audio frames) usually
/// fall inside it; big video frames are jumped over with a fresh read.
class _Reader {
  _Reader(this.src);
  final ByteSource src;
  static const _window = 4096;
  Uint8List _buf = Uint8List(0);
  int _bufStart = 0;

  Uint8List bytes(int offset, int count) {
    if (count <= 0) return Uint8List(0);
    if (offset >= _bufStart && offset + count <= _bufStart + _buf.length) {
      return Uint8List.sublistView(
        _buf,
        offset - _bufStart,
        offset - _bufStart + count,
      );
    }
    if (count > _window) return src.read(offset, count);
    _buf = src.read(offset, _window);
    _bufStart = offset;
    return Uint8List.sublistView(_buf, 0, count.clamp(0, _buf.length));
  }

  /// (id, size or null if unknown, data offset); id = -1 past the end.
  (int, int?, int) header(int pos) {
    final h = bytes(pos, 12);
    if (h.isEmpty) return (-1, null, pos);
    final idLen = _vintLength(h[0]);
    if (idLen == 0 || idLen > 4 || idLen >= h.length) return (-1, null, pos);
    var id = 0;
    for (var i = 0; i < idLen; i++) {
      id = (id << 8) | h[i];
    }
    final sizeLen = _vintLength(h[idLen]);
    if (sizeLen == 0 || idLen + sizeLen > h.length) return (-1, null, pos);
    var size = h[idLen] & (0xFF >> sizeLen);
    var allOnes = size == (0xFF >> sizeLen);
    for (var i = 1; i < sizeLen; i++) {
      final b = h[idLen + i];
      size = (size << 8) | b;
      allOnes &= b == 0xFF;
    }
    return (id, allOnes ? null : size, pos + idLen + sizeLen);
  }

  int uint(int pos, int size) {
    var v = 0;
    for (final b in bytes(pos, size)) {
      v = (v << 8) | b;
    }
    return v;
  }

  String string(int pos, int size) => utf8
      .decode(bytes(pos, size), allowMalformed: true)
      .replaceAll('\x00', '');
}
