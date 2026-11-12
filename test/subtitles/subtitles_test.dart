import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/subtitles/ass_parser.dart';
import 'package:kotohori/features/subtitles/srt_parser.dart';
import 'package:kotohori/features/subtitles/subtitle_loader.dart';
import 'package:kotohori/features/subtitles/timeline.dart';
import 'package:kotohori/features/subtitles/vtt_parser.dart';

Duration ms(int v) => Duration(milliseconds: v);

const srt =
    '﻿1\r\n00:00:01,000 --> 00:00:02,500\r\n<i>こんにちは</i>\r\n{\\an8}世界\r\n\r\n'
    '2\r\n00:00:03,000 --> 00:00:04,000\r\n食べなかった\r\n\r\n'
    'garbage block\r\n\r\n'
    '3\r\n00:00:05,00 --> 00:00:06,000\r\n\r\n';

const vtt = '''WEBVTT
Kind: captions

NOTE this is a comment
00:00:00.000 --> 00:00:09.000 is not a cue here

STYLE
::cue { color: red }

intro
00:01.000 --> 00:02.000 align:start position:10%
<c.yellow>行きました</c> &amp; <00:01.500>読んで

01:00:03.000 --> 01:00:04.250
二行目
''';

const ass = '''[Script Info]
Title: test
ScriptType: v4.00+

[V4+ Styles]
Format: Name, Fontname, Fontsize
Style: Default,Arial,20

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:02.50,Default,,0,0,0,,{\\an8\\i1}そうだ{\\i0}、行こう\\Nね
Dialogue: 1,0:00:01.00,0:00:02.50,Default,,0,0,0,,{\\an8\\i1}そうだ{\\i0}、行こう\\Nね
Comment: 0,0:00:03.00,0:00:04.00,Default,,0,0,0,,これはコメント
Dialogue: 0,0:00:02.00,0:00:05.00,Sign,,0,0,0,,{\\p1}m 0 0 l 100 0 100 100{\\p0}看板
Dialogue: 0,0:00:06.00,0:00:07.00,Default,,0,0,0,,{\\p1}m 0 0 l 1 1
Dialogue: 0,0:00:08.00,0:00:09.00,Default,,0,0,0,,a,b\\hc
''';

void main() {
  group('SRT', () {
    test('parses cues, strips tags, skips garbage and empty cues', () {
      final c = parseSrt(srt.replaceFirst('﻿', ''));
      expect(c.map((x) => x.text), ['こんにちは\n世界', '食べなかった']);
      expect(c[0].start, ms(1000));
      expect(c[0].end, ms(2500));
      expect(c.map((x) => x.index), [0, 1]);
    });
  });

  group('WebVTT', () {
    test('skips NOTE/STYLE, handles ids, settings, hours, tags, entities', () {
      final c = parseVtt(vtt);
      expect(c.map((x) => x.text), ['行きました & 読んで', '二行目']);
      expect(c[0].start, ms(1000));
      expect(c[1].start, const Duration(hours: 1, seconds: 3));
      expect(c[1].end, const Duration(hours: 1, seconds: 4, milliseconds: 250));
    });
  });

  group('ASS', () {
    test(
      'Dialogue only, override tags stripped, \\N → newline, layers deduped',
      () {
        final c = parseAss(ass);
        expect(c.map((x) => x.text), ['そうだ、行こう\nね', '看板', 'a,b c']);
        expect(c[0].start, ms(1000));
        expect(c[0].end, ms(2500));
      },
    );

    test('drawing commands are dropped', () {
      expect(cleanAssText(r'{\p1}m 0 0 l 1 1{\p0}text'), 'text');
      expect(cleanAssText(r'{\pos(1,2)\p2}m 0 0'), '');
      expect(cleanAssText(r'{\b1}bold{\b0} \n x'), 'bold\nx');
    });
  });

  group('loader', () {
    test('decodes UTF-8 BOM, UTF-16 LE/BE and Shift-JIS', () {
      expect(decodeSubtitleBytes(utf8.encode('﻿日本語')), '日本語');
      final le = [
        0xff,
        0xfe,
        for (final u in '日本語'.codeUnits) ...[u & 0xff, u >> 8],
      ];
      final be = [
        0xfe,
        0xff,
        for (final u in '日本語'.codeUnits) ...[u >> 8, u & 0xff],
      ];
      expect(decodeSubtitleBytes(le), '日本語');
      expect(decodeSubtitleBytes(be), '日本語');
      expect(decodeSubtitleBytes(shiftJis.encode('食べなかった')), '食べなかった');
    });

    test('Shift-JIS SRT end to end', () {
      final c = parseSubtitleFile(
        shiftJis.encode(srt.replaceFirst('﻿', '')),
        'ep01.srt',
      );
      expect(c[1].text, '食べなかった');
    });

    test('picks parser by extension, sniffs unknown extensions', () {
      expect(parseSubtitleFile(utf8.encode(ass), 'x.ass'), hasLength(3));
      expect(parseSubtitleFile(utf8.encode(ass), 'x.txt'), hasLength(3));
      expect(parseSubtitleFile(utf8.encode(vtt), 'x.sub'), hasLength(2));
      expect(
        () => parseSubtitleFile(utf8.encode('nothing'), 'x.srt'),
        throwsFormatException,
      );
    });
  });

  group('SubtitleTimeline', () {
    final t = SubtitleTimeline(parseAss(ass)); // 1.0–2.5, 2.0–5.0, 8.0–9.0

    test('active cues overlap', () {
      expect(t.activeAt(ms(500)), isEmpty);
      expect(t.activeAt(ms(2200)).map((c) => c.index), [0, 1]);
      expect(t.activeAt(ms(6000)), isEmpty);
    });

    test('current / next / previous', () {
      expect(t.currentAt(ms(500)), isNull);
      expect(t.nextAfter(ms(500))!.index, 0);
      expect(t.currentAt(ms(6000))!.index, 1); // gap: last started cue
      expect(t.nextAfter(ms(6000))!.index, 2);
      expect(t.previousBefore(ms(6000))!.index, 0);
      expect(t.previousBefore(ms(1500))!.index, 0); // first cue: stays on it
      expect(t.nextAfter(ms(8500)), isNull);
    });

    test('seek landing a frame before a cue start counts as that cue', () {
      // Seek to cue 2 (starts 8.0 s) lands on the frame at ~7.958 s.
      expect(t.activeAt(ms(7958)).map((c) => c.index), [2]);
      expect(t.currentAt(ms(7958))!.index, 2);
      expect(t.nextAfter(ms(7958)), isNull); // "next" must not re-jump to cue 2
      expect(t.activeAt(ms(7800)), isEmpty);
    });

    test('sync: selected line starts now, whichever line it is', () {
      final s = SubtitleTimeline(
        parseAss(ass),
        offset: ms(700),
      ); // starts 1.0, 2.0, 8.0
      // Paused at 3.0 s; the line being spoken is the one at 8.0 (two lines ahead).
      s.offset = s.offsetToStart(s.cues[2], ms(3000));
      expect(s.offset, ms(-5000));
      expect(s.activeAt(ms(3000)).map((c) => c.index), [2]);
      // Selecting a line already passed moves subtitles later instead.
      s.offset = s.offsetToStart(s.cues[0], ms(3000));
      expect(s.offset, ms(2000));
      expect(s.activeAt(ms(3000)).map((c) => c.index), [0]);
    });

    test('offset shifts everything', () {
      final s = SubtitleTimeline(parseAss(ass), offset: ms(1000));
      expect(s.activeAt(ms(1500)), isEmpty);
      expect(s.activeAt(ms(2100)).single.index, 0);
      expect(s.startOf(s.cues[2]), ms(9000));
      s.offset = ms(-1000);
      expect(s.activeAt(ms(100)).single.index, 0);
    });
  });
}
