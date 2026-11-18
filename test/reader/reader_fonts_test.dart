import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/reader_fonts.dart';
import 'package:kotohori/features/reader/reader_settings.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late ReaderFonts fonts;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kotohori_fonts');
    fonts = ReaderFonts(p.join(tmp.path, 'fonts'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  File file(String name) =>
      File(p.join(tmp.path, name))..writeAsBytesSync([0, 1, 0, 0]);

  test('an added font is copied, listed and removable', () async {
    final name = await fonts.add(file('Noto Serif JP.otf').path);
    expect(name, 'Noto Serif JP.otf');
    expect(fonts.list(), ['Noto Serif JP.otf']);
    expect(File(fonts.path(name)).existsSync(), isTrue);
    await fonts.remove(name);
    expect(fonts.list(), isEmpty);
  });

  test('only font files are accepted', () async {
    await expectLater(fonts.add(file('book.epub').path), throwsFormatException);
    expect(fonts.list(), isEmpty);
  });

  test('the font choice survives JSON; unknown values mean the book font', () {
    const s = ReaderSettings(font: 'file:Noto Serif JP.otf');
    expect(ReaderSettings.fromJson(s.toJson()).font, 'file:Noto Serif JP.otf');
    expect(const ReaderSettings().font, isNull);
  });

  test('CSS: the book font adds nothing; a chosen font applies everywhere', () {
    expect(
      readerCss(const ReaderSettings(), ReaderTheme.white),
      isNot(contains('font-family')),
    );
    final serif = readerCss(
      const ReaderSettings(font: ReaderFonts.serif),
      ReaderTheme.white,
    );
    expect(serif, contains('font-family: serif !important'));
    expect(serif, isNot(contains('@font-face')));
    final own = readerCss(
      const ReaderSettings(font: 'file:x.otf'),
      ReaderTheme.white,
      fontUrl: 'file:///fonts/x.otf',
    );
    expect(
      own,
      contains(
        "@font-face { font-family: 'KhFont'; src: url('file:///fonts/x.otf'); }",
      ),
    );
    expect(own, contains("font-family: 'KhFont' !important"));
  });
}
