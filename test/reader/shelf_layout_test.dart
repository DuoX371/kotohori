import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/shelf_layout.dart';

void main() {
  test('tiles at most 160 wide, filling the row like the old grid', () {
    // 1204 wide: (1204 - 32 + 16) / 176 = 6.75 → 7 columns.
    final l = ShelfLayout(1204);
    expect(l.columns, 7);
    expect(l.tileWidth, closeTo((1204 - 32 - 6 * 16) / 7, 1e-9));
    expect(l.tileHeight, closeTo(l.tileWidth / 0.52, 1e-9));
  });

  test('slots run left to right, then down', () {
    final l = ShelfLayout(400); // (400 - 32 + 16) / 176 = 2.2 → 3 columns
    expect(l.columns, 3);
    expect(l.slot(0).topLeft, const Offset(16, 16));
    expect(l.slot(1).left, closeTo(16 + l.tileWidth + 16, 1e-9));
    expect(l.slot(3).left, 16);
    expect(l.slot(3).top, closeTo(16 + l.tileHeight + 16, 1e-9));
  });

  test('height fits every row plus room for the Add book button', () {
    final l = ShelfLayout(400);
    expect(l.height(4), closeTo(16 + 2 * l.tileHeight + 16 + 96, 1e-9));
    expect(l.height(0), 16 + 96);
  });
}
