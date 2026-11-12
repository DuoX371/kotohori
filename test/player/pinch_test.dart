import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/player/player_screen.dart';

void main() {
  test('pinch goes the way the fingers moved, small ones snap back', () {
    expect(pinchSnapsToFill(0, 0.3), isTrue); // pinched out from fit
    expect(pinchSnapsToFill(1, 0.7), isFalse); // pinched in from fill
    expect(pinchSnapsToFill(0, 0.05), isFalse); // barely moved: stay fit
    expect(pinchSnapsToFill(1, 0.95), isTrue); // barely moved: stay fill
  });
}
