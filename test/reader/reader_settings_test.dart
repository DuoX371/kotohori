import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/reader_settings.dart';

void main() {
  test('settings survive a JSON round trip', () {
    const s = ReaderSettings(
      theme: ReaderTheme.sepia,
      fontSize: 24,
      lineSpacing: 2,
      margin: 10,
      vertical: false,
    );
    final back = ReaderSettings.fromJson(s.toJson());
    expect(
      (back.theme, back.fontSize, back.lineSpacing, back.margin, back.vertical),
      (ReaderTheme.sepia, 24.0, 2.0, 10.0, false),
    );
  });

  test('heading size: relative to the text, default 1.3×, kept in JSON', () {
    expect(const ReaderSettings().headingSize, 1.3);
    final s = ReaderSettings.fromJson(
      const ReaderSettings(headingSize: 1.8).toJson(),
    );
    expect(s.headingSize, 1.8);
    expect(ReaderSettings.fromJson({'headingSize': 9}).headingSize, 2.0);
    expect(
      readerCss(const ReaderSettings(), ReaderTheme.white),
      contains('h1, h2, h3, h4, h5, h6 { font-size: 1.30em !important; }'),
    );
  });

  test('garbage or missing values fall back to the defaults', () {
    final s = ReaderSettings.fromJson({'theme': 'neon', 'fontSize': 'big'});
    expect(
      (s.theme, s.fontSize, s.lineSpacing, s.margin, s.vertical),
      (null, 20.0, 1.8, 24.0, true),
    );
  });

  test('no theme chosen follows the app', () {
    const s = ReaderSettings();
    expect(effectiveTheme(s, Brightness.dark), ReaderTheme.dark);
    expect(effectiveTheme(s, Brightness.light), ReaderTheme.white);
    expect(
      effectiveTheme(
        const ReaderSettings(theme: ReaderTheme.black),
        Brightness.light,
      ),
      ReaderTheme.black,
    );
  });

  test('page CSS carries direction, size, spacing and colours', () {
    final v = readerCss(const ReaderSettings(), ReaderTheme.white);
    expect(v, contains('vertical-rl'));
    expect(v, contains('font-size: 20px'));
    expect(v, contains('line-height: 1.8'));
    expect(v, isNot(contains('font-family')));
    final h = readerCss(
      const ReaderSettings(vertical: false),
      ReaderTheme.sepia,
    );
    expect(h, contains('horizontal-tb'));
    expect(h, contains('#F4ECD8'));
  });
}
