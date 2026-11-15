import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:kotohori/features/player/player_screen.dart';

void main() {
  test('pinch goes the way the fingers moved, small ones snap back', () {
    expect(pinchSnapsToFill(0, 0.3), isTrue); // pinched out from fit
    expect(pinchSnapsToFill(1, 0.7), isFalse); // pinched in from fill
    expect(pinchSnapsToFill(0, 0.05), isFalse); // barely moved: stay fit
    expect(pinchSnapsToFill(1, 0.95), isTrue); // barely moved: stay fill
  });

  test('letterbox bar under the video', () {
    const tablet = Size(1280, 800); // 16:10
    expect(letterboxBottom(tablet, 1920, 1080, 1), 40); // 16:9 → 720 tall
    expect(letterboxBottom(tablet, 1920, 1080, 800 / 720), 0); // filled
    expect(letterboxBottom(const Size(1920, 1080), 1920, 1080, 1), 0);
    expect(letterboxBottom(tablet, 1440, 1080, 1), 0); // 4:3: bars on the sides
    expect(letterboxBottom(tablet, null, null, 1), 0);
  });
}
