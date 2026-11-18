import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/reader_preview.dart';
import 'package:kotohori/features/reader/reader_settings.dart';

void main() {
  test('the sample is styled exactly like a book page', () {
    const s = ReaderSettings(fontSize: 24, vertical: false);
    final css = readerCss(s, ReaderTheme.sepia);
    final html = readerPreviewHtml(css);
    expect(html, contains(css)); // the same styling books get
    expect(html, contains('<h2>')); // heading size shows
    expect(html, contains('<ruby>')); // furigana shows
    expect(html, contains('吾輩は猫である'));
    expect(html, startsWith('<!DOCTYPE html>'));
    expect(html, contains('charset="utf-8"'));
  });
}
