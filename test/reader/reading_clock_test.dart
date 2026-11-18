import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/reading_clock.dart';

Duration s(int v) => Duration(seconds: v);

void main() {
  test('time between page turns counts; a long gap (walked away) does not', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(60), 400);
    c.at(s(100), 800);
    c.at(s(1000), 1200); // 15 min later: not reading the whole time
    c.at(s(1040), 1600);
    expect(c.takeReadMs(), (60 + 40 + 40) * 1000);
    expect(c.takeReadMs(), 0); // taken
  });

  test('pace: characters read per minute over counted time', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(60), 300);
    c.at(s(120), 600);
    expect(c.sessionPace, 300);
  });

  test('jumps (chapter list, going back) count time but not pace', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(60), 300);
    c.at(s(70), 50000); // jumped ahead via the chapter list
    c.at(s(80), 100); // jumped back
    expect(c.sessionPace, 300);
    expect(c.takeReadMs(), 80 * 1000);
  });

  test('a pause (app in the background) ends the stretch', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(30), 200);
    c.pause();
    c.at(s(100), 200); // back: starts again from here
    c.at(s(130), 400);
    expect(c.takeReadMs(), 60 * 1000);
  });

  test('no pace until there is a minute of reading', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(30), 300);
    expect(c.sessionPace, isNull);
  });

  test('time left at a pace', () {
    expect(
      timeLeft(remainingChars: 30000, charsPerMinute: 300),
      const Duration(minutes: 100),
    );
    expect(timeLeft(remainingChars: 0, charsPerMinute: 300), Duration.zero);
  });

  test('skimming (faster than anyone reads) counts time but not pace', () {
    final c = ReadingClock(idleLimit: s(180));
    c.at(s(0), 0);
    c.at(s(20), 600); // 1,800 a minute: flicking through
    c.at(s(80), 900);
    c.at(s(140), 1200);
    expect(c.sessionPace, 300);
    expect(c.takeReadMs(), 140 * 1000);
  });
}
