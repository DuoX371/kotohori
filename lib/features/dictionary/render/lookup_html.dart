import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db.dart';
import '../lookup/lookup.dart';
import 'css_scope.dart';
import 'glossary_html.dart';

/// Builds the full results page shown in the WebView.
class LookupHtmlBuilder {
  LookupHtmlBuilder({required this.mediaRoot});
  final String mediaRoot;
  final _cssCache = <(int, String), String>{};

  /// Definition HTML for a single entry. [forAnki]: chips are styled inline
  /// and spaced apart, because some Anki screens drop the field's `<style>`.
  String entryHtml(TermEntry e, {bool forAnki = false}) {
    final r = GlossaryRenderer(
      mediaUrl: (path) => _dataUri(e.dict.id, path),
      spaceInlineSiblings: forAnki,
    );
    final tags = e.term.definitionTags.split(' ').where((t) => t.isNotEmpty);
    String chip(String cls, String text) => forAnki
        ? '<span class="$cls" style="${cls == 'dict' ? _ankiDictChip : _ankiChip}">${escape(text)}</span>'
        : '<span class="$cls">${escape(text)}</span>';
    return '<div class="entry" data-dictionary="${escape(e.dict.title)}">'
        '<div class="entry-head">${[chip('dict', e.dict.title), for (final t in tags) chip('tag', t)].join(forAnki ? ' ' : '')}</div>'
        '${r.glossaryList(e.term.glossary)}</div>';
  }

  /// Anki Definition field: the word's entries (all dictionaries, or only the
  /// highest-priority one) plus each dictionary's scoped styles.css, so the card
  /// looks like the popup (Yomitan-style).
  String ankiDefinition(TermGroup g, {required bool firstDictionaryOnly}) {
    final firstId = g.entries.first.dict.id;
    final entries = firstDictionaryOnly
        ? g.entries.where((e) => e.dict.id == firstId)
        : g.entries;
    final dicts = {for (final e in entries) e.dict.id: e.dict};
    final css = dicts.values.map(_scoped).join('\n');
    return '<div class="kotohori-definition">${entries.map((e) => entryHtml(e, forAnki: true)).join()}</div>'
        '<style>$_ankiCss\n$css</style>';
  }

  String _scoped(Dictionary d) =>
      _cssCache[(d.id, d.revision)] ??= scopeCss(d.stylesCss, d.title);

  /// [addButtons]: adds a ＋ per word that posts its group index to the
  /// `Kotohori` JavaScript channel (only our own handler; dictionary HTML is sanitized),
  /// and, with [quickAdd] (Anki set up), a quick add button (card with plus)
  /// beside it that posts "quick:index".
  /// [dark]: the app's theme (not the system's, which can differ).
  String page(
    LookupResult result, {
    String? emptyMessage,
    bool addButtons = false,
    bool quickAdd = false,
    bool dark = false,
  }) {
    final dicts = <int, Dictionary>{};
    final body = StringBuffer();
    if (result.groups.isEmpty) {
      body.write(
        '<p class="empty">${escape(emptyMessage ?? 'No results')}</p>',
      );
    }
    for (final (i, g) in result.groups.indexed) {
      body.write('<section class="group">');
      if (addButtons) {
        body.write(
          '<button class="add" data-i="$i" aria-label="Add to Anki" onclick="Kotohori.postMessage(\'$i\')">＋</button>',
        );
      }
      if (addButtons && quickAdd) {
        body.write(
          '<button class="add quick" data-i="$i" aria-label="Quick add to Anki" title="Quick add to Anki"'
          ' onclick="this.disabled=true;Kotohori.postMessage(\'quick:$i\')">$_cardPlus</button>',
        );
      }
      body.write('<h2>');
      body.write(
        g.reading == g.expression
            ? escape(g.expression)
            : '<ruby>${escape(g.expression)}<rt>${escape(g.reading)}</rt></ruby>',
      );
      body.write('</h2>');
      final reasons = g.entries.first.reasons;
      if (reasons.isNotEmpty) {
        body.write('<div class="reasons">${escape(reasons.join(' « '))}</div>');
      }
      for (final f in g.frequencies) {
        body.write(
          '<span class="freq">${escape(f.dict.title)}: ${escape(_freqLabel(f.data))}</span>',
        );
      }
      for (final pitch in g.pitches) {
        final pos =
            (pitch.data is Map ? (pitch.data as Map)['pitches'] as List? : null)
                ?.map((x) => x is Map ? '[${x['position']}]' : '')
                .join(' ') ??
            '';
        body.write(
          '<span class="freq">${escape(pitch.dict.title)}: ${escape(pos)}</span>',
        );
      }
      for (final e in g.entries) {
        dicts[e.dict.id] = e.dict;
        body.write(entryHtml(e));
      }
      body.write('</section>');
    }
    final css = dicts.values.map(_scoped).join('\n');
    return '<!doctype html><html${dark ? ' class="dark"' : ''}><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<style>$_baseCss</style><style>$css</style></head><body>$body</body></html>';
  }

  // shortcut: images are inlined as data URIs (no WebView file access needed);
  // fine for the few small images dictionaries ship, switch to file URLs if that changes.
  String? _dataUri(int dictId, String path) {
    final root = p.join(mediaRoot, '$dictId');
    final file = p.normalize(p.join(root, path));
    if (!p.isWithin(root, file)) return null;
    final f = File(file);
    if (!f.existsSync()) return null;
    final ext = p.extension(file).toLowerCase();
    final mime = switch (ext) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.svg' => 'image/svg+xml',
      '.webp' => 'image/webp',
      _ => null,
    };
    if (mime == null) return null;
    return 'data:$mime;base64,${base64Encode(f.readAsBytesSync())}';
  }
}

/// Material "library_add": a card with a plus.
const _cardPlus =
    '<svg viewBox="0 0 24 24" width="1em" height="1em" fill="currentColor" aria-hidden="true">'
    '<path d="M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9h-4v4h-2v-4H9V9h4V5h2v4h4v2z"/></svg>';

String _freqLabel(Object? d) => switch (d) {
  {'frequency': final f} => _freqLabel(f),
  {'displayValue': final String v} => v,
  {'value': final v} => '$v',
  _ => '$d',
};

const _baseCss = '''
:root { color-scheme: light; --fg:#1d1d1f; --bg:#fff; --muted:#6b6b70; --chip:#ececf0; --line:#e3e3e8; }
:root.dark { color-scheme: dark; --fg:#ececf0; --bg:#17171a; --muted:#9a9aa2; --chip:#2a2a30; --line:#2c2c33; }
body { margin:0; padding:12px 16px 32px; font-family: system-ui, "Noto Sans JP", sans-serif; color:var(--fg); background:var(--bg); line-height:1.5; }
.group { border-bottom:1px solid var(--line); padding:8px 0 12px; }
h2 { font-size:1.6em; margin:0 0 4px; font-weight:600; }
rt { font-size:.5em; color:var(--muted); }
.reasons { color:var(--muted); font-size:.85em; margin-bottom:4px; }
.freq, .tag, .dict { display:inline-block; font-size:.75em; padding:1px 6px; border-radius:4px; background:var(--chip); margin:0 4px 4px 0; }
.dict { font-weight:600; }
.entry { margin-top:6px; }
.glossary-list { margin:4px 0 0; padding-left:1.4em; }
.empty { color:var(--muted); text-align:center; margin-top:40px; }
img { max-width:100%; }
.add { float:right; font-size:1.3em; line-height:1; width:2em; height:2em; border:0; border-radius:50%;
  background:var(--chip); color:var(--fg); margin:4px 0 0 8px; }
/* Quick add: straight to Anki, no editor. Pulses while sending. */
.add.quick { display:inline-flex; align-items:center; justify-content:center; font-size:1.05em; width:2.476em; height:2.476em; }
.add.quick:disabled { animation: kh-pulse 1s ease-in-out infinite; }
@keyframes kh-pulse { 50% { opacity:.35; } }
/* Already in Anki: a book beside ＋ that opens the cards in AnkiDroid. */
.add.in-anki { background:transparent; border:1.5px solid #c9a24a; color:#c9a24a; font-size:1.05em; width:2.476em; height:2.476em;
  display:inline-flex; align-items:center; justify-content:center; }
.in-anki-note { color:#b08a35; font-size:0.85em; margin:2px 0 4px; display:flex; gap:6px; align-items:center; }
''';

/// Minimal chrome for the Anki Definition field; neutral colours so it works
/// on light and dark card themes. Dictionary styles.css does the rest.
const _ankiCss = '''
.kotohori-definition { text-align:left; }
.kotohori-definition .entry { margin-top:6px; }
.kotohori-definition .glossary-list { margin:4px 0 0; padding-left:1.4em; }
''';

/// Chip look for the Anki copy, written on each chip (see [LookupHtmlBuilder.entryHtml]).
const _ankiChip =
    'display:inline-block;font-size:.75em;padding:1px 6px;border-radius:4px;'
    'background:rgba(128,128,128,.2);margin:0 0 4px 0';
const _ankiDictChip = '$_ankiChip;font-weight:600';
