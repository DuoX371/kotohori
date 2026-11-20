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

  test('where a pinch settles: near Fit or Fill it snaps, beyond it stays', () {
    const fill = 1.11; // 16:9 on a 16:10 tablet
    expect(zoomTarget(1, 1.08, fill), fill); // pinched out a bit: fill
    expect(zoomTarget(fill, 1.02, fill), 1); // pinched in: fit
    expect(zoomTarget(1, 1.01, fill), 1); // barely moved: stays fit
    expect(zoomTarget(1, 3, fill), 3); // free zoom stays where it is
    expect(zoomTarget(3, 1.2, fill), fill); // back down near fill: fill
    expect(zoomTarget(1, 1.1, 1), 1); // same shape as the screen: only fit
  });

  test('picture size and how far it can be moved', () {
    const tablet = Size(1280, 800);
    final fitted = fittedSize(tablet, 1920, 1080);
    expect(fitted, const Size(1280, 720));
    expect(fittedSize(tablet, null, null), tablet);
    // At fit it can't move at all.
    expect(clampPan(const Offset(50, 50), tablet, fitted, 1), Offset.zero);
    // At 2x: 2560x1440, so up to 640 sideways and 320 up or down.
    expect(
      clampPan(const Offset(1000, -1000), tablet, fitted, 2),
      const Offset(640, -320),
    );
    expect(
      clampPan(const Offset(100, 50), tablet, fitted, 2),
      const Offset(100, 50),
    );
  });
}
