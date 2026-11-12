import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/subtitles/auto_sync.dart';
import 'package:kotohori/features/subtitles/cue.dart';

/// An irregular "dialogue" timeline: 300 lines with random gaps and lengths.
List<Cue> dialogue(int seed) {
  final r = Random(seed);
  var t = 20000;
  return [
    for (var i = 0; i < 300; i++)
      () {
        t += 300 + r.nextInt(4000);
        final len = 800 + r.nextInt(3500);
        final c = Cue(
          i,
          Duration(milliseconds: t),
          Duration(milliseconds: t + len),
          'line $i',
        );
        t += len;
        return c;
      }(),
  ];
}

/// The same lines as another release times them: [shiftMs] later, with jitter.
List<Cue> retimed(List<Cue> ref, int Function(Cue) shiftMs, {int seed = 7}) {
  final r = Random(seed);
  return [
    for (final c in ref)
      Cue(
        c.index,
        c.start + Duration(milliseconds: shiftMs(c) + r.nextInt(161) - 80),
        c.end + Duration(milliseconds: shiftMs(c) + r.nextInt(161) - 80),
        c.text,
      ),
  ];
}

void main() {
  final ref = dialogue(1);

  test('finds a single shift', () {
    final target = retimed(ref, (_) => 31500);
    final r = autoSync(target, ref)!;
    expect(r.segments, hasLength(1));
    expect(r.segments.single.shift.inMilliseconds, closeTo(-31500, 100));
    expect(r.matched, greaterThan(0.9));
  });

  test('splits where the releases differ (e.g. a TV recording with an extra 10 s sponsor card)', () {
    final splitAt = ref[60].start;
    final target = retimed(ref, (c) => c.start < splitAt ? 32500 : 42500);
    final r = autoSync(target, ref)!;
    expect(r.segments, hasLength(2));
    expect(r.segments[0].shift.inMilliseconds, closeTo(-32500, 100));
    expect(r.segments[1].shift.inMilliseconds, closeTo(-42500, 100));
    expect(r.segments[1].from, target[60].start);

    final fixed = applySync(target, r.segments);
    for (final (i, c) in fixed.indexed) {
      expect((c.start - ref[i].start).inMilliseconds.abs(), lessThan(250));
    }
  });

  test('unrelated subtitles are rejected', () {
    expect(autoSync(dialogue(2), ref), isNull);
    expect(autoSync(dialogue(2).take(3).toList(), ref), isNull);
  });

  test('describeSync uses video times', () {
    expect(
      describeSync(const [
        SyncSegment(Duration(seconds: 40), Duration(milliseconds: -32650)),
      ]),
      'Shifted −32.6 s',
    );
    expect(
      describeSync(const [
        SyncSegment(Duration(seconds: 40), Duration(milliseconds: -32500)),
        SyncSegment(Duration(seconds: 334), Duration(milliseconds: -42500)),
      ]),
      'Shifted −32.5 s, then −42.5 s from 4:51',
    );
  });
}
