import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/subtitles/mkv/mkv_cues.dart';
import 'package:kotohori/features/subtitles/mkv/mkv_reader.dart';

// Minimal Matroska writer for tests.
List<int> _id(int id) => [
  for (var shift = (id.bitLength - 1) ~/ 8 * 8; shift >= 0; shift -= 8)
    (id >> shift) & 0xFF,
];
List<int> _size(int n) => [
  0x01,
  for (var s = 48; s >= 0; s -= 8) (n >> s) & 0xFF,
]; // 8-byte size
List<int> el(int id, List<int> data) => [
  ..._id(id),
  ..._size(data.length),
  ...data,
];
List<int> uintEl(int id, int v) =>
    el(id, [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF]);
List<int> strEl(int id, String s) => el(id, utf8.encode(s));
List<int> block(int track, int rel, List<int> data) => [
  0x80 | track,
  (rel >> 8) & 0xFF,
  rel & 0xFF,
  0,
  ...data,
];

List<int> mkv({
  required List<int> tracks,
  required List<List<int>> clusters,
  bool unknownSizeSegment = false,
}) {
  final body = [
    ...el(0x1549A966, uintEl(0x2AD7B1, 1000000)), // Info: 1 ms ticks
    ...el(0x1654AE6B, tracks),
    for (final c in clusters) ...c,
  ];
  return [
    ...el(0x1A45DFA3, strEl(0x4282, 'matroska')),
    if (unknownSizeSegment) ...[
      0x18,
      0x53,
      0x80,
      0x67,
      0x01,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      ...body,
    ] else
      ...el(0x18538067, body),
  ];
}

List<int> track(
  int n,
  int type,
  String codec, {
  String? lang,
  String? name,
  List<int>? encodings,
}) => el(0xAE, [
  ...uintEl(0xD7, n),
  ...uintEl(0x83, type),
  ...strEl(0x86, codec),
  if (lang != null) ...strEl(0x22B59D, lang),
  if (name != null) ...strEl(0x536E, name),
  ...?encodings,
]);

List<int> cluster(int time, List<List<int>> children) =>
    el(0x1F43B675, [...uintEl(0xE7, time), for (final c in children) ...c]);
List<int> group(List<int> blk, int duration) =>
    el(0xA0, [...el(0xA1, blk), ...uintEl(0x9B, duration)]);

void main() {
  final file = mkv(
    tracks: [
      ...track(1, 1, 'V_MPEGH/ISO/HEVC'),
      ...track(2, 0x11, 'S_TEXT/ASS', lang: 'en', name: 'CR'),
      ...track(3, 0x11, 'S_TEXT/UTF8', lang: 'jpn'),
      ...track(4, 0x11, 'S_HDMV/PGS', lang: 'ja'),
    ],
    clusters: [
      cluster(10000, [
        el(0xA3, block(1, 0, List.filled(5000, 7))), // a "video frame" to skip
        group(
          block(
            2,
            500,
            utf8.encode(
              r'0,0,Default,,0,0,0,,{\i1}Hello,{\an8} world\Nnext line',
            ),
          ),
          1500,
        ),
        group(block(3, 600, utf8.encode('<i>こんにちは</i>')), 2000),
      ]),
      cluster(20000, [
        el(0xA3, block(3, 0, utf8.encode('さようなら'))), // SimpleBlock: no duration
        el(0xA3, block(1, 0, List.filled(9000, 1))),
      ]),
    ],
  );

  test(
    'lists subtitle tracks and reads text blocks, skipping other frames',
    () {
      final m = readMkvSubtitles(MemoryByteSource(Uint8List.fromList(file)));
      expect(
        [for (final t in m.tracks) (t.number, t.codec, mkvTrackLabel(t))],
        [
          (2, 'S_TEXT/ASS', 'English (CR)'),
          (3, 'S_TEXT/UTF8', 'Japanese'),
          (4, 'S_HDMV/PGS', 'Japanese'),
        ],
      );
      expect(m.tracks.where((t) => t.isText).map((t) => t.number), [2, 3]);
      expect(
        m.blocks.keys,
        unorderedEquals([2, 3]),
      ); // PGS (image) is not collected

      final en = mkvTrackCues(m.tracks[0], m.blocks[2]!);
      expect(en.single.start, const Duration(milliseconds: 10500));
      expect(en.single.end, const Duration(milliseconds: 12000));
      expect(
        en.single.text,
        'Hello, world\nnext line',
      ); // ASS fields and tags stripped

      final ja = mkvTrackCues(m.tracks[1], m.blocks[3]!);
      expect(
        [
          for (final c in ja)
            (c.text, c.start.inMilliseconds, c.end.inMilliseconds),
        ],
        [
          ('こんにちは', 10600, 12600),
          ('さようなら', 20000, 24000), // no duration: default length
        ],
      );
    },
  );

  test('tracksOnly stops at the first cluster', () {
    final m = readMkvSubtitles(
      MemoryByteSource(Uint8List.fromList(file)),
      tracksOnly: true,
    );
    expect(m.tracks, hasLength(3));
    expect(m.blocks.values.every((b) => b.isEmpty), isTrue);
  });

  test('zlib-compressed and header-stripped tracks, unknown-size segment', () {
    final zlibEnc = el(0x6D80, el(0x6240, el(0x5034, uintEl(0x4254, 0))));
    final stripEnc = el(
      0x6D80,
      el(
        0x6240,
        el(0x5034, [
          ...uintEl(0x4254, 3),
          ...el(0x4255, utf8.encode('0,0,Def,,0,0,0,,')),
        ]),
      ),
    );
    final m = readMkvSubtitles(
      MemoryByteSource(
        Uint8List.fromList(
          mkv(
            unknownSizeSegment: true,
            tracks: [
              ...track(5, 0x11, 'S_TEXT/UTF8', encodings: zlibEnc),
              ...track(6, 0x11, 'S_TEXT/ASS', encodings: stripEnc),
            ],
            clusters: [
              cluster(0, [
                group(block(5, 100, zlib.encode(utf8.encode('圧縮'))), 1000),
                group(block(6, 200, utf8.encode('ヘッダー')), 1000),
              ]),
            ],
          ),
        ),
      ),
    );
    expect(mkvTrackCues(m.tracks[0], m.blocks[5]!).single.text, '圧縮');
    expect(
      mkvTrackLabel(m.tracks[0]),
      'English',
    ); // Matroska's default language
    expect(mkvTrackCues(m.tracks[1], m.blocks[6]!).single.text, 'ヘッダー');
  });

  test('not an MKV file', () {
    expect(
      () => readMkvSubtitles(
        MemoryByteSource(
          Uint8List.fromList(utf8.encode('just some text file')),
        ),
      ),
      throwsFormatException,
    );
  });
}
