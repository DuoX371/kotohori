import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;
import 'reader_fonts.dart';

enum ReaderTheme {
  white('White', Color(0xFFFFFFFF), Color(0xFF1A1A1A)),
  sepia('Sepia', Color(0xFFF4ECD8), Color(0xFF5B4636)),
  gray('Gray', Color(0xFFD9D9D6), Color(0xFF262626)),
  dark('Dark', Color(0xFF1E1F22), Color(0xFFDADADA)),
  black('Black', Color(0xFF000000), Color(0xFFBDBDBD));

  const ReaderTheme(this.label, this.background, this.text);
  final String label;
  final Color background;
  final Color text;

  bool get isDark => background.computeLuminance() < 0.3;
}

/// How books look. Global, not per book.
class ReaderSettings {
  const ReaderSettings({
    this.theme,
    this.fontSize = 20,
    this.lineSpacing = 1.8,
    this.margin = 24,
    this.vertical = true,
    this.headingSize = 1.3,
    this.font,
  });

  /// Null: follow the app (White in light mode, Dark in dark mode).
  final ReaderTheme? theme;
  final double fontSize;
  final double lineSpacing;
  final double margin;
  final bool vertical;

  /// Headings' size relative to the text (books often make them 2×).
  final double headingSize;

  /// Null: the book's own font. Otherwise a [ReaderFonts] choice.
  final String? font;

  static const fontSizes = (min: 12.0, max: 40.0);
  static const lineSpacings = (min: 1.2, max: 2.6);
  static const margins = (min: 0.0, max: 64.0);
  static const headingSizes = (min: 1.0, max: 2.0);

  ReaderSettings copyWith({
    ReaderTheme? Function()? theme,
    double? fontSize,
    double? lineSpacing,
    double? margin,
    bool? vertical,
    double? headingSize,
    String? Function()? font,
  }) => ReaderSettings(
    theme: theme == null ? this.theme : theme(),
    fontSize: fontSize ?? this.fontSize,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    margin: margin ?? this.margin,
    vertical: vertical ?? this.vertical,
    headingSize: headingSize ?? this.headingSize,
    font: font == null ? this.font : font(),
  );

  Map<String, Object?> toJson() => {
    'theme': theme?.name,
    'fontSize': fontSize,
    'lineSpacing': lineSpacing,
    'margin': margin,
    'vertical': vertical,
    'headingSize': headingSize,
    'font': font,
  };

  factory ReaderSettings.fromJson(Map<String, Object?> j) {
    const d = ReaderSettings();
    double read(String k, double fallback, ({double min, double max}) range) {
      final v = j[k];
      return v is num ? v.toDouble().clamp(range.min, range.max) : fallback;
    }

    return ReaderSettings(
      theme: ReaderTheme.values.where((t) => t.name == j['theme']).firstOrNull,
      fontSize: read('fontSize', d.fontSize, fontSizes),
      lineSpacing: read('lineSpacing', d.lineSpacing, lineSpacings),
      margin: read('margin', d.margin, margins),
      vertical: j['vertical'] is bool ? j['vertical']! as bool : d.vertical,
      headingSize: read('headingSize', d.headingSize, headingSizes),
      font: j['font'] is String ? j['font']! as String : null,
    );
  }
}

ReaderTheme effectiveTheme(ReaderSettings s, Brightness app) =>
    s.theme ?? (app == Brightness.dark ? ReaderTheme.dark : ReaderTheme.white);

/// 20.0 → "20", 1.85 → "1.85" (CSS doesn't need the trailing .0).
String _n(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Styling laid over the book's own CSS. Direction is forced on every element
/// so a book styled horizontally can still be read vertically. The book's
/// own font is kept unless one is chosen. Pagination is the page script's job.
/// [fontUrl]: where an added or bundled font file is ([ReaderFonts.urlFor]).
String readerCss(ReaderSettings s, ReaderTheme theme, {String? fontUrl}) {
  final mode = s.vertical ? 'vertical-rl' : 'horizontal-tb';
  final family = switch (s.font) {
    null => null,
    ReaderFonts.serif => 'serif',
    ReaderFonts.sans => 'sans-serif',
    _ => fontUrl == null ? null : "'KhFont'",
  };
  final face = fontUrl == null
      ? ''
      : "@font-face { font-family: 'KhFont'; src: url('$fontUrl'); }\n";
  final font = family == null
      ? ''
      : '${face}html, body, body * { font-family: $family !important; }\n';
  return '''$font
html {
  writing-mode: $mode !important;
  background: ${_hex(theme.background)} !important;
  color: ${_hex(theme.text)} !important;
}
body {
  writing-mode: $mode !important;
  margin: 0 !important;
  padding: ${_n(s.margin)}px !important;
  font-size: ${_n(s.fontSize)}px !important;
  line-height: ${_n(s.lineSpacing)} !important;
  background: transparent !important;
  color: inherit !important;
}
body * { writing-mode: $mode !important; color: inherit !important; }
p, div { line-height: inherit !important; }
h1, h2, h3, h4, h5, h6 { font-size: ${s.headingSize.toStringAsFixed(2)}em !important; }
img, svg, image { max-width: 100% !important; max-height: 100% !important; }
''';
}

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  static const key = 'reader.settings';

  @override
  ReaderSettings build() {
    try {
      final raw = ref.watch(prefsProvider).getString(key);
      return raw == null
          ? const ReaderSettings()
          : ReaderSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const ReaderSettings();
    }
  }

  Future<void> update(ReaderSettings Function(ReaderSettings) change) async {
    state = change(state);
    await ref.read(prefsProvider).setString(key, jsonEncode(state.toJson()));
  }
}

final readerSettingsProvider =
    NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
      ReaderSettingsNotifier.new,
    );
