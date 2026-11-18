import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../../platform/web_view.dart';
import '../dictionary/ui/providers.dart' show appPathsProvider;
import 'reader_providers.dart';
import 'reader_settings.dart';

String readerPreviewHtml(String css) =>
    '''<!DOCTYPE html>
<html lang="ja"><head><meta charset="utf-8">
<style>html, body { overflow: hidden !important; }</style>
<style>$css</style></head>
<body>
<h2>吾輩は猫である</h2>
<p>吾輩は<ruby>猫<rt>ねこ</rt></ruby>である。名前はまだ無い。</p>
<p>どこで生れたかとんと<ruby>見当<rt>けんとう</rt></ruby>がつかぬ。何でも薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。</p>
<p>吾輩はここで始めて人間というものを見た。しかもあとで聞くとそれは<ruby>書生<rt>しょせい</rt></ruby>という人間中で一番<ruby>獰悪<rt>どうあく</rt></ruby>な種族であったそうだ。</p>
</body></html>
''';

class ReaderPreview extends ConsumerStatefulWidget {
  const ReaderPreview({super.key});

  @override
  ConsumerState<ReaderPreview> createState() => _ReaderPreviewState();
}

class _ReaderPreviewState extends ConsumerState<ReaderPreview> {
  final _web = WebViewController()..enableZoom(false);

  /// Loaded from a file, like a book chapter, so added fonts (file URLs)
  /// load the same way they do in a book.
  late final _file = File(
    p.join(ref.read(appPathsProvider).tempDir, 'reader_preview.html'),
  );
  String? _shown;

  Future<void> _show(ReaderSettings s, ReaderTheme theme) async {
    final html = readerPreviewHtml(
      readerCss(
        s,
        theme,
        fontUrl: ref.read(readerFontsProvider).urlFor(s.font),
      ),
    );
    if (html == _shown) return;
    _shown = html;
    await _web.setBackgroundColor(theme.background);
    await _file.writeAsString(html);
    await _web.loadFile(_file.path);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(readerSettingsProvider);
    final theme = effectiveTheme(s, Theme.of(context).brightness);
    _show(s, theme);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(child: appWebView(_web)),
    );
  }
}
