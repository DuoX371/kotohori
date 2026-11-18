import 'dart:io';

import 'package:path/path.dart' as p;

/// Fonts for the reader: a few built in, plus font files the user added
/// (Kotohori keeps its own copy, so the original can move).
class ReaderFonts {
  ReaderFonts(this.dir);
  final String dir;

  /// Font choices stored in [ReaderSettings.font]. Null is the book's own.
  static const serif = 'serif', sans = 'sans', zen = 'zen';

  /// An added font's choice id.
  static String fileId(String name) => 'file:$name';

  static const _extensions = {'.ttf', '.otf', '.woff', '.woff2'};

  /// The app's bundled font, as the WebView can load it from the APK.
  static const zenUrl =
      'file:///android_asset/flutter_assets/assets/fonts/ZenKakuGothicNew-Medium.ttf';

  String path(String name) => p.join(dir, name);

  /// Added fonts' file names, A–Z.
  List<String> list() {
    final d = Directory(dir);
    if (!d.existsSync()) return const [];
    return [for (final f in d.listSync().whereType<File>()) p.basename(f.path)]
      ..sort();
  }

  /// Copies the font at [from]; returns its name. Throws [FormatException]
  /// for anything that isn't a font file.
  Future<String> add(String from) async {
    final name = p.basename(from);
    if (!_extensions.contains(p.extension(name).toLowerCase())) {
      throw FormatException('Not a font file', name);
    }
    await Directory(dir).create(recursive: true);
    await File(from).copy(path(name));
    return name;
  }

  Future<void> remove(String name) async {
    final f = File(path(name));
    if (f.existsSync()) await f.delete();
  }

  /// Where the page loads the chosen [font] from (null: a family name only).
  String? urlFor(String? font) {
    if (font == zen) return zenUrl;
    if (font != null && font.startsWith('file:')) {
      return Uri.file(path(font.substring(5))).toString();
    }
    return null;
  }
}
