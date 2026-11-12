// ignore_for_file: avoid_print
// Dev helper: dart run tool/mkv_probe.dart <file.mkv>
import 'dart:io';

import 'package:kotohori/features/subtitles/auto_sync.dart';
import 'package:kotohori/features/subtitles/cue.dart';
import 'package:kotohori/features/subtitles/mkv/mkv_cues.dart';
import 'package:kotohori/features/subtitles/subtitle_loader.dart';
import 'package:kotohori/features/subtitles/mkv/mkv_reader.dart';

void main(List<String> args) {
  final f = File(args.first).openSync();
  final sw = Stopwatch()..start();
  final head = readMkvSubtitles(FileByteSource(f), tracksOnly: true);
  print('tracks (${sw.elapsedMilliseconds} ms):');
  for (final t in head.tracks) {
    print('  #${t.number} ${t.codec} [${t.language}] ${mkvTrackLabel(t)}');
  }
  sw.reset();
  final all = readMkvSubtitles(FileByteSource(f));
  print('full scan: ${sw.elapsedMilliseconds} ms');
  for (final t in all.tracks.where((t) => t.isText)) {
    final cues = mkvTrackCues(t, all.blocks[t.number]!);
    print(
      '  ${mkvTrackLabel(t)}: ${cues.length} lines; first: ${cues.firstOrNull}',
    );
  }
  if (args.length > 1) {
    final jp = parseSubtitleFile(File(args[1]).readAsBytesSync(), args[1]);
    final eng = all.tracks.firstWhere((t) => mkvLanguageCode(t) == 'en');
    final ref = mkvTrackCues(eng, all.blocks[eng.number]!);
    sw.reset();
    final r = autoSync(jp, ref);
    print(
      'auto sync (${sw.elapsedMilliseconds} ms): ${r?.segments} matched ${r?.matched}',
    );
    // Unrelated timings (a line every 4.3 s) must be rejected.
    final fake = [
      for (var i = 0; i < 300; i++)
        Cue(
          i,
          Duration(milliseconds: i * 4300),
          Duration(milliseconds: i * 4300 + 2000),
          'x',
        ),
    ];
    print('unrelated input -> ${autoSync(fake, ref)?.matched}');
  }
  f.closeSync();
}
