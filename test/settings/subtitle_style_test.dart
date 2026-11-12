import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/settings/subtitle_style.dart';

void main() {
  test('round-trips through JSON', () {
    const s = SubtitleStyle(
      size: 34,
      color: SubtitleStyle.yellow,
      bold: true,
      backdrop: SubtitleBackdrop.box,
      boxOpacity: 0.7,
    );
    expect(SubtitleStyle.fromJson(jsonDecode(jsonEncode(s.toJson()))), s);
  });

  test('bad or missing values fall back to defaults, sizes are clamped', () {
    expect(SubtitleStyle.fromJson('nonsense'), const SubtitleStyle());
    final s = SubtitleStyle.fromJson({
      'size': 500,
      'backdrop': 'sparkles',
      'bold': 'yes',
      'boxOpacity': -3,
    });
    expect(s.size, SubtitleStyle.maxSize);
    expect(s.backdrop, SubtitleBackdrop.outline);
    expect(s.bold, isFalse);
    expect(s.boxOpacity, 0);
  });
}
