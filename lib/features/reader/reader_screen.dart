import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../anki/anki_providers.dart';
import '../anki/anki_settings.dart';
import '../anki/card_editor_screen.dart';
import '../dictionary/ui/providers.dart'
    show htmlBuilderProvider, lookupProvider, prefsProvider;
import '../explain/explain_request.dart';
import '../explain/explain_settings.dart';
import '../explain/explain_settings_screen.dart';
import '../player/explain_panel.dart';
import '../player/lookup_panel.dart';
import 'book_view.dart';
import 'library_db.dart';
import 'position.dart';
import 'reader_controller.dart';
import 'reader_event.dart';
import 'reader_providers.dart';
import 'reader_settings.dart';
import 'reader_settings_sheet.dart';
import 'sentences.dart';
import 'tap_hint.dart';
import 'tap_zones.dart';

/// Reads one book: paged text, tap a word to look it up, mine it.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final c = ReaderController(
    lookup: ref.read(lookupProvider).lookup,
    explain: _askAi,
  );
  late final List<int> _lengths =
      (jsonDecode(widget.book.chapterLengths) as List).cast<int>();
  final _keys = FocusNode(debugLabel: 'reader keys');
  final _ankiChanged = ValueNotifier(0);
  late final _lifecycle = AppLifecycleListener(onPause: _save);
  // Read once: ref can't be used in dispose(), where the last save happens.
  late final _repo = ref.read(bookRepoProvider);
  BookViewController? _view;
  Object? _error;
  var _bar = false;

  var _panelLeft = false;

  /// Showing where to tap to turn pages (once per text direction, ever).
  var _hint = false;

  /// Shows the page-turn hint if it hasn't been shown for this direction.
  /// Not while something covers the page (the settings sheet, where the
  /// direction is switched): it would play unseen and be used up. It's tried
  /// again when the sheet closes.
  void _maybeHint() {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final prefs = ref.read(prefsProvider);
    final vertical = ref.read(readerSettingsProvider).vertical;
    if (!tapHintDue(prefs, vertical: vertical)) return;
    markTapHintSeen(prefs, vertical: vertical).ignore();
    setState(() => _hint = true);
  }

  ReaderPos? _pos;
  double? _charsPerPage;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _repo;
    _lifecycle;
    c.lookup.addListener(_onLookup);
    c.explain.addListener(_rebuild);
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = _repo;
      final hash = widget.book.hash;
      final path = repo.epubPath(hash);
      final epub = await loadEpub(path);
      await extractEpub(path, repo.extractedDir(hash));
      if (!mounted) return;
      final s = ref.read(readerSettingsProvider);
      final view = BookViewController(
        epub: epub,
        extractedDir: repo.extractedDir(hash),
        settings: s,
        fonts: ref.read(readerFontsProvider),
        theme: effectiveTheme(s, Theme.of(context).brightness),
        onEvent: _onEvent,
      );
      setState(() => _view = view);
      await view.open(widget.book.chapter, offset: widget.book.offset);
    } on Object catch (e, s) {
      debugPrint('Reader: could not open ${widget.book.title}: $e\n$s');
      if (mounted) setState(() => _error = e);
    }
  }

  Stream<String> _askAi(ExplainRequest r) async* {
    final client = await ref.read(geminiClientProvider(r.model).future);
    final prompt = explainPrompt(r);
    yield* client.ask(system: prompt.system, user: prompt.user);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// The looked-up word is highlighted in the page while the popup is open.
  void _onLookup() {
    final h = c.lookup.highlight;
    if (c.lookup.isOpen && h != null) {
      _view?.highlight(h.$1, h.$2, h.$3);
    } else if (!c.lookup.isOpen) {
      _view?.clearHighlight();
      _keys.requestFocus(); // keyboard back from the popup's WebView
    }
    _rebuild();
  }

  void _onEvent(ReaderEvent e) {
    switch (e) {
      case ReaderTap():
        setState(() => _panelLeft = e.x > 0.5);
        c.onTap(e);
      case ReaderBlank():
        if (c.lookup.isOpen) {
          c.lookup.close();
        } else if (c.explain.isOpen) {
          c.explain.close();
        } else {
          final vertical = ref.read(readerSettingsProvider).vertical;
          switch (blankTapAction(
            e.x,
            e.width,
            y: e.y,
            height: e.height,
            vertical: vertical,
          )) {
            case BlankTapAction.next:
              _view?.next();
            case BlankTapAction.previous:
              _view?.prev();
            case BlankTapAction.menu:
              setState(() => _bar = !_bar);
          }
        }
      case ReaderPos():
        // Characters per page, learnt from a chapter long enough to tell:
        // the basis of the whole-book page estimate.
        final chapter = _view?.chapter;
        if (chapter != null && e.pages >= 3) {
          _charsPerPage = _lengths[chapter] / e.pages;
        }
        setState(() => _pos = e);
        _maybeHint(); // the first page is on screen
        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(seconds: 1), _save);
      case ReaderEdge():
    }
  }

  /// "p. 45 of ~380 · 12%"; just "12%" until the page size is known. The %
  /// is how much of the book's text is read, the same as on the shelf.
  String _progressLabel(double progress, BookViewController v, ReaderPos pos) {
    final percent = '${(progress * 100).floor()}%';
    final cpp = _charsPerPage;
    if (cpp == null) return percent;
    final p = bookPages(
      _lengths,
      chapter: v.chapter,
      page: pos.page,
      chapterPages: pos.pages,
      charsPerPage: cpp,
    );
    return 'p. ${p.page} of ~${p.total} · $percent';
  }

  void _save() {
    final v = _view;
    if (v == null || _pos == null) return;
    _repo
        .savePosition(widget.book.hash, chapter: v.chapter, offset: v.offset)
        .ignore();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    _lifecycle.dispose();
    c.lookup.removeListener(_onLookup);
    c.explain.removeListener(_rebuild);
    c.dispose();
    _keys.dispose();
    _ankiChanged.dispose();
    super.dispose();
  }

  Future<void> _addCard(int groupIndex, List<String>? existingDecks) async {
    final result = c.lookup.result, h = c.lookup.highlight, t = c.lastTap;
    if (result == null ||
        h == null ||
        t == null ||
        groupIndex >= result.groups.length) {
      return;
    }
    final group = result.groups[groupIndex];
    final (_, start, highlighted) = h;
    final sentence = sentenceAt(t.text, start);
    final settings = ref.read(ankiSettingsProvider);
    final draft = ref
        .read(cardExporterProvider)
        .prepare(
          settings: settings,
          cueText: sentence.text,
          matchStart: start - sentence.start,
          matchLength: c.lookup.followedLink
              ? highlighted
              : group.matchedLength,
          word: group.expression,
          reading: group.reading,
          definitionHtml: ref
              .read(htmlBuilderProvider)
              .ankiDefinition(
                group,
                firstDictionaryOnly: settings.firstDictionaryOnly,
              ),
          videoTitle: widget.book.title,
        );
    draft.existingDecks = existingDecks;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CardEditorScreen(draft: draft)),
    );
    _ankiChanged.value++;
  }

  Future<void> _explain() async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = explainSetupProblem(
      apiKey: await ref.read(explainApiKeyProvider.future),
    );
    if (!mounted) return;
    if (problem != null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set up Explain'),
          content: Text(problem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (go == true) _openExplainSettings();
      return;
    }
    final r = c.explainRequest(
      title: widget.book.title,
      model: ref.read(explainModelProvider),
    );
    if (r == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tap a sentence first to explain it')),
        );
      return;
    }
    c.lookup.close();
    c.explain.start(r);
  }

  void _openExplainSettings() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExplainSettingsScreen()),
    );
  }

  void _showChapters() {
    final v = _view;
    if (v == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: [
          for (final e in v.epub.toc)
            ListTile(
              title: Text(e.title),
              selected: e.chapter == v.chapter,
              onTap: () {
                Navigator.of(context).pop();
                v.open(e.chapter, fragment: e.fragment);
              },
            ),
        ],
      ),
    );
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final v = _view;
    final vertical = ref.read(readerSettingsProvider).vertical;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        vertical ? v?.next() : v?.prev();
      case LogicalKeyboardKey.arrowRight:
        vertical ? v?.prev() : v?.next();
      case LogicalKeyboardKey.escape when c.lookup.isOpen:
        c.lookup.close();
      case LogicalKeyboardKey.escape when c.explain.isOpen:
        c.explain.close();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// The popup slides in from the edge it docks to, like in the player. It
  /// is drawn in the app's theme ([app]), not the reading theme.
  Widget _panel(ThemeData app, Offset from) {
    final still = MediaQuery.disableAnimationsOf(context);
    final dark = app.brightness == Brightness.dark;
    final panel = AnimatedSwitcher(
      duration: Duration(milliseconds: still ? 0 : 260),
      reverseDuration: Duration(milliseconds: still ? 0 : 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, t) => SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(t),
        child: FadeTransition(opacity: t, child: child),
      ),
      child: c.explain.isOpen
          ? ExplainPanel(
              key: const ValueKey('explain'),
              c.explain,
              onClose: c.explain.close,
              onOpenSettings: _openExplainSettings,
            )
          : c.lookup.isOpen
          ? LookupPanel(
              key: const ValueKey('lookup'),
              c.lookup,
              onClose: c.lookup.close,
              onAdd: _addCard,
              ankiChanged: _ankiChanged,
              dark: dark,
            )
          : const SizedBox.shrink(),
    );
    return Theme(data: app, child: panel);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);
    final app = Theme.of(context);
    final theme = effectiveTheme(settings, app.brightness);
    ref.listen(readerSettingsProvider, (_, s) {
      _charsPerPage = null; // a new font or margin changes the page size
      _view?.applySettings(s, effectiveTheme(s, Theme.of(context).brightness));
    });
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    final v = _view, pos = _pos;
    final progress = v == null || pos == null
        ? null
        : bookProgress(_lengths, v.chapter, pos.offset);
    final showBar = _bar || v == null;
    final still = MediaQuery.disableAnimationsOf(context);
    return Theme(
      data: buildTheme(
        theme.isDark ? Brightness.dark : Brightness.light,
        snackWidth: snackBarWidth(size),
      ),
      child: Focus(
        focusNode: _keys,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Stack(
              children: [
                if (v != null)
                  Positioned.fill(
                    // Any touch hides the hint; the touch still reaches the page.
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (_) {
                        if (_hint) setState(() => _hint = false);
                      },
                      child: BookView(v),
                    ),
                  )
                else
                  Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Text(
                            "Couldn't open this book. It may not be a valid EPUB.",
                            style: TextStyle(color: theme.text),
                          ),
                  ),
                if (progress != null) ...[
                  // The whole book at a glance: a thin line along the bottom.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor: theme.text.withValues(alpha: 0.08),
                        color: theme.text.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 6,
                    child: IgnorePointer(
                      child: Text(
                        _progressLabel(progress, v!, pos!),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
                // Always in the list (empty when off), so showing it doesn't
                // shift the bar and popup below and rebuild them.
                Positioned.fill(
                  child: _hint
                      ? TapHint(
                          key: ValueKey(settings.vertical),
                          vertical: settings.vertical,
                          color: theme.text,
                          background: theme.background,
                          onDone: () {
                            if (mounted) setState(() => _hint = false);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  // Clipped: slid up, the bar vanishes instead of covering
                  // the status bar.
                  child: ClipRect(
                    child: IgnorePointer(
                      ignoring: !showBar,
                      // Slides down from the top edge, and back up to hide.
                      child: AnimatedSlide(
                        offset: showBar ? Offset.zero : const Offset(0, -1),
                        duration: Duration(milliseconds: still ? 0 : 200),
                        curve: Curves.easeOutCubic,
                        child: Material(
                          color: theme.background.withValues(alpha: 0.95),
                          elevation: 2,
                          child: IconTheme(
                            data: IconThemeData(color: theme.text),
                            child: Row(
                              children: [
                                BackButton(color: theme.text),
                                Expanded(
                                  child: Text(
                                    widget.book.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.text,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (ref.watch(explainEnabledProvider))
                                  IconButton(
                                    tooltip: 'Explain',
                                    icon: const Icon(
                                      Icons.auto_awesome_rounded,
                                    ),
                                    onPressed: _explain,
                                  ),
                                IconButton(
                                  tooltip: 'Chapters',
                                  icon: const Icon(Icons.format_list_bulleted),
                                  onPressed: _showChapters,
                                ),
                                IconButton(
                                  tooltip: 'Reader settings',
                                  icon: const Icon(Icons.text_fields),
                                  onPressed: () async {
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      barrierColor: Colors.transparent,
                                      // The sheet paints itself in the reading
                                      // theme, which can change while it's
                                      // open.
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      builder: (_) =>
                                          const ReaderSettingsSheet(),
                                    );
                                    // A direction switched in the sheet: show
                                    // its hint now that the page is visible.
                                    if (_view != null) _maybeHint();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (wide)
                  Positioned(
                    top: 8,
                    bottom: 8,
                    left: _panelLeft ? 8 : null,
                    right: _panelLeft ? null : 8,
                    width: size.width * 0.42,
                    child: _panel(app, Offset(_panelLeft ? -1.05 : 1.05, 0)),
                  )
                else
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: size.height * 0.5,
                    child: _panel(app, const Offset(0, 1)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
