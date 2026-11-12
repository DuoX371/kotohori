import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../anki/anki_providers.dart';
import '../anki/anki_settings.dart';
import '../dictionary/lookup/lookup.dart' show LookupResult;
import '../dictionary/ui/providers.dart'
    show emptyLookupMessageProvider, htmlBuilderProvider;
import 'player_controller.dart';

/// Dictionary popup over the video. Renders the same results page as
/// Settings → Look up a word, so dictionary styles apply.
class LookupPanel extends ConsumerStatefulWidget {
  const LookupPanel(this.c, {super.key, required this.onAdd, this.ankiChanged});
  final PlayerController c;

  /// ＋ tapped on the word at this index of the current result; [decks]: where
  /// its existing cards are (null: no card yet).
  final void Function(int index, List<String>? decks) onAdd;

  /// Fires after a card was added, to re-check which words are in Anki.
  final Listenable? ankiChanged;

  @override
  ConsumerState<LookupPanel> createState() => _LookupPanelState();
}

class _LookupPanelState extends ConsumerState<LookupPanel> {
  // JavaScript is on only for our ＋ buttons; dictionary HTML is sanitized
  // (no scripts, no event attributes), so nothing else can run.
  late final _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel(
      'Kotohori',
      onMessageReceived: (m) {
        final i = int.tryParse(m.message);
        if (i != null) widget.onAdd(i, _inAnki[i]);
      },
    )
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          _pageReady = true;
          _markInAnki();
        },
      ),
    );
  LookupResult? _shown;
  var _pageReady = false;

  /// Word index → decks of its existing cards (its ＋ becomes a book).
  Map<int, List<String>> _inAnki = {};

  Future<void> _checkAnki() async {
    final r = _shown;
    if (r == null) return;
    final found = await ref.read(cardExporterProvider).wordsInAnki([
      for (final g in r.groups) g.expression,
    ], ref.read(ankiSettingsProvider));
    if (!mounted || !identical(r, _shown)) return; // a newer lookup replaced it
    _inAnki = {for (final (i, g) in r.groups.indexed) i: ?found[g.expression]};
    _markInAnki();
  }

  /// Still tappable (adds another card); only the look and label change, plus a
  /// line under the word saying which deck it's in.
  void _markInAnki() {
    if (!_pageReady || _inAnki.isEmpty) return;
    final marks = {
      for (final e in _inAnki.entries)
        '${e.key}': e.value.map(_deckLabel).join(', '),
    };
    _web.runJavaScript('''
const book = '<svg viewBox="0 0 24 24" width="1em" height="1em" fill="currentColor" aria-hidden="true"><path d="M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z"/></svg>';
for (const [i, decks] of Object.entries(${jsonEncode(marks)})) {
  const b = document.querySelector('button.add[data-i="' + i + '"]');
  if (!b || b.classList.contains('in-anki')) continue;
  b.classList.add('in-anki');
  b.innerHTML = book;
  b.title = 'Already in Anki (' + decks + '). Tap to add another card';
  b.setAttribute('aria-label', b.title);
  const note = document.createElement('div');
  note.className = 'in-anki-note';
  note.innerHTML = book + ' In Anki: ';
  note.appendChild(document.createTextNode(decks));
  b.parentElement.querySelector('h2').after(note);
}''');
  }

  /// "Real Mining::Test" → "Real Mining › Test".
  static String _deckLabel(String deck) => deck.replaceAll('::', ' › ');

  @override
  void initState() {
    super.initState();
    widget.c.lookup.addListener(_load);
    widget.ankiChanged?.addListener(_checkAnki);
    _load();
  }

  @override
  void dispose() {
    widget.c.lookup.removeListener(_load);
    widget.ankiChanged?.removeListener(_checkAnki);
    super.dispose();
  }

  void _load() {
    final r = widget.c.lookup.result;
    if (r == null || identical(r, _shown)) return;
    _shown = r;
    _pageReady = false;
    _inAnki = {};
    _checkAnki(); // runs alongside the page load; marks apply whichever finishes last
    _web.loadHtmlString(
      ref
          .read(htmlBuilderProvider)
          .page(
            r,
            emptyMessage: ref.read(emptyLookupMessageProvider),
            addButtons: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(emptyLookupMessageProvider); // keeps the dictionary list loaded
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: widget.c.closeLookup,
            ),
          ),
          Expanded(child: WebViewWidget(controller: _web)),
        ],
      ),
    );
  }
}
