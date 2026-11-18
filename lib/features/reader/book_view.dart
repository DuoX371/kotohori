import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../../platform/web_view.dart';
import 'epub.dart';
import 'reader_event.dart';
import 'reader_fonts.dart';
import 'reader_settings.dart';

/// Reads the stored EPUB at [path] in a background isolate. Top-level on
/// purpose: a closure made inside a widget method would drag that widget's
/// state (database, WebView) into the isolate message and fail.
Future<EpubBook> loadEpub(String path) =>
    Isolate.run(() => parseEpub(File(path).readAsBytesSync()));

/// Unpacks the stored EPUB into [dir] once (via a temporary folder, so a
/// half-finished unpack is never mistaken for a whole one).
Future<void> extractEpub(String epubPath, String dir) async {
  if (Directory(dir).existsSync()) return;
  await Isolate.run(() {
    final part = Directory('$dir.part');
    if (part.existsSync()) part.deleteSync(recursive: true);
    final root = p.normalize(part.absolute.path);
    final zip = ZipDecoder().decodeBytes(File(epubPath).readAsBytesSync());
    for (final f in zip.files) {
      if (!f.isFile) continue;
      final out = p.normalize(p.joinAll([root, ...f.name.split('/')]));
      if (!p.isWithin(root, out)) continue; // never write outside the folder
      File(out)
        ..createSync(recursive: true)
        ..writeAsBytesSync(f.content);
    }
    part.renameSync(dir);
  });
}

class PageCover extends ValueNotifier<bool> {
  PageCover() : super(false);

  static const limit = Duration(seconds: 2);

  static const settle = Duration(milliseconds: 150);
  Timer? _limit, _settle;

  void loading() {
    _limit?.cancel();
    _settle?.cancel();
    _limit = Timer(limit, laidOut);
    value = true;
  }

  void laidOut() {
    _limit?.cancel();
    _settle?.cancel();
    value = false;
  }

  void laidOutSoon() {
    if (!value) return;
    _settle?.cancel();
    _settle = Timer(settle, laidOut);
  }

  @override
  void dispose() {
    _limit?.cancel();
    _settle?.cancel();
    super.dispose();
  }
}

class BookViewController {
  BookViewController({
    required this.epub,
    required this.extractedDir,
    required this.settings,
    required this.fonts,
    required this.theme,
    required this.onEvent,
  }) {
    web
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(theme.background)
      ..addJavaScriptChannel(
        'Kotohori',
        onMessageReceived: (m) {
          final e = ReaderEvent.parse(m.message);
          if (e != null) _handle(e);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _start(),
          onNavigationRequest: (r) {
            _follow(r.url);
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  final EpubBook epub;
  final String extractedDir;
  final ReaderFonts fonts;
  ReaderSettings settings;
  ReaderTheme theme;
  final void Function(ReaderEvent) onEvent;
  final web = WebViewController();

  final cover = PageCover();

  /// The chapter shown (index into the spine) and where its page starts.
  int chapter = 0;
  int offset = 0;
  Object _at = 0; // where to land once the page has loaded

  /// A chapter is loading: the old page's late messages and page turns are
  /// ignored, so an edge can't open chapters twice or mix up the position.
  bool _loading = false;
  static Future<String>? _script;

  Future<void> open(
    int chapter, {
    int offset = 0,
    bool atEnd = false,
    String? fragment,
  }) async {
    if (chapter < 0 || chapter >= epub.spine.length) return;
    this.chapter = chapter;
    this.offset = offset;
    _at = atEnd ? 'end' : (fragment != null ? '#$fragment' : offset);
    _loading = true;
    cover.loading();
    await web.loadFile(_chapterFile(chapter));
  }

  String _chapterFile(int i) =>
      p.joinAll([extractedDir, ...epub.spine[i].href.split('/')]);

  Future<void> _start() async {
    final js = await (_script ??= rootBundle.loadString(
      'assets/reader/reader.js',
    ));
    await web.runJavaScript(js);
    _loading = false;
    await _init(_at);
  }

  Future<void> _init(Object at) => web.runJavaScript(
    'kh.init(${jsonEncode(readerCss(settings, theme, fontUrl: fonts.urlFor(settings.font)))}, ${settings.vertical}, '
    '${settings.margin}, ${jsonEncode(at)})',
  );

  /// Restyles the page and keeps the same text on screen.
  Future<void> applySettings(ReaderSettings s, ReaderTheme t) async {
    settings = s;
    theme = t;
    await web.setBackgroundColor(t.background);
    await _init(offset);
  }

  Future<void> next() async {
    if (!_loading) await web.runJavaScript('kh.next()');
  }

  Future<void> prev() async {
    if (!_loading) await web.runJavaScript('kh.prev()');
  }

  Future<void> highlight(int para, int start, int length) =>
      web.runJavaScript('kh.highlight($para, $start, $length)');

  Future<void> clearHighlight() => web.runJavaScript('kh.clearHighlight()');

  void _handle(ReaderEvent e) {
    if (_loading && (e is ReaderPos || e is ReaderEdge)) return;
    switch (e) {
      case ReaderPos(:final offset):
        this.offset = offset;
        cover.laidOutSoon(); // the new chapter is laid out: show it
      case ReaderEdge(forward: true):
        open(chapter + 1);
      case ReaderEdge(forward: false):
        open(chapter - 1, atEnd: true);
      default:
    }
    onEvent(e);
  }

  /// A link inside the book: open the chapter it points to.
  void _follow(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'file') return;
    final path = p.normalize(uri.toFilePath());
    for (final (i, _) in epub.spine.indexed) {
      if (p.equals(p.normalize(_chapterFile(i)), path)) {
        open(i, fragment: uri.fragment.isEmpty ? null : uri.fragment);
        return;
      }
    }
  }
}

class BookView extends StatelessWidget {
  const BookView(this.controller, {super.key});
  final BookViewController controller;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      appWebView(controller.web),
      ValueListenableBuilder(
        valueListenable: controller.cover,
        builder: (_, covered, _) => covered
            ? ColoredBox(color: controller.theme.background)
            : const SizedBox.shrink(),
      ),
    ],
  );
}
