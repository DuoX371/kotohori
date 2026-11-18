import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Where each book sits on the shelf: the same grid as a
/// `SliverGridDelegateWithMaxCrossAxisExtent` (tiles up to 160 wide, 0.52
/// aspect, 16 gaps), but as plain rectangles so tiles can glide when the
/// order changes.
class ShelfLayout {
  ShelfLayout(this.width);
  final double width;

  static const maxTile = 160.0, aspect = 0.52, gap = 16.0, pad = 16.0;

  /// Room under the last row so the Add book button never covers a book.
  static const bottom = 96.0;

  double get _usable => width - 2 * pad;
  int get columns => math.max(1, ((_usable + gap) / (maxTile + gap)).ceil());
  double get tileWidth => (_usable - gap * (columns - 1)) / columns;
  double get tileHeight => tileWidth / aspect;

  Rect slot(int index) => Rect.fromLTWH(
    pad + (index % columns) * (tileWidth + gap),
    pad + (index ~/ columns) * (tileHeight + gap),
    tileWidth,
    tileHeight,
  );

  /// Height of the shelf holding [count] books.
  double height(int count) {
    final rows = (count / columns).ceil();
    return pad +
        (rows == 0 ? 0 : rows * tileHeight + (rows - 1) * gap) +
        bottom;
  }
}
