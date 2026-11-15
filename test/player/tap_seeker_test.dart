import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/player/tap_seeker.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('double tap on a side seeks 5 s that way', () {
    final t = TapSeeker();
    expect(t.tap(ms(0), TapSide.right), isNull); // first tap: maybe a single tap
    expect(t.tap(ms(200), TapSide.right), 5);
    expect(t.total, 5);

    final b = TapSeeker();
    b.tap(ms(0), TapSide.left);
    expect(b.tap(ms(200), TapSide.left), -5);
  });

  test('more taps on the same side keep adding 5 s, like YouTube', () {
    final t = TapSeeker()
      ..tap(ms(0), TapSide.right)
      ..tap(ms(200), TapSide.right);
    expect(t.tap(ms(600), TapSide.right), 5);
    expect(t.tap(ms(1000), TapSide.right), 5);
    expect(t.total, 15);
    // A pause ends the streak: the next tap is a fresh first tap.
    expect(t.tap(ms(3000), TapSide.right), isNull);
  });

  test('slow taps, different sides and the middle are not seeks', () {
    final t = TapSeeker();
    t.tap(ms(0), TapSide.right);
    expect(t.tap(ms(500), TapSide.right), isNull); // too slow
    t.tap(ms(2000), TapSide.left);
    expect(t.tap(ms(2100), TapSide.right), isNull); // other side
    t.tap(ms(4000), TapSide.middle);
    expect(t.tap(ms(4100), TapSide.middle), isNull);
  });
}
