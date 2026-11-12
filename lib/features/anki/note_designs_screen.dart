import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../../platform/anki_bridge.dart';
import 'anki_providers.dart';
import 'anki_settings.dart';
import 'card_builder.dart';
import 'note_designs.dart';

/// Settings → Anki → Card designs: preview the ready-made note types and add one to AnkiDroid.
class NoteDesignsScreen extends ConsumerStatefulWidget {
  const NoteDesignsScreen({super.key});

  @override
  ConsumerState<NoteDesignsScreen> createState() => _NoteDesignsScreenState();
}

class _NoteDesignsScreenState extends ConsumerState<NoteDesignsScreen> {
  var _design = noteDesigns.first;
  var _back = false;
  var _busy = false;
  // JavaScript only to measure the rendered card's height (the HTML is our own sample).
  late final _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => _measure()),
    );

  /// The preview grows to fit the whole card, so the page scrolls instead of the card being cut off.
  double _cardHeight = 360;

  Future<void> _measure() async {
    for (final wait in const [0, 300]) {
      // Second pass: images (the sample screenshot) may finish laying out a moment later.
      await Future<void>.delayed(Duration(milliseconds: wait));
      final h = await _web.runJavaScriptReturningResult(
        'document.documentElement.scrollHeight',
      );
      final v = h is num ? h.toDouble() : double.tryParse('$h');
      if (v != null && mounted && (v - _cardHeight).abs() > 1) {
        setState(() => _cardHeight = v.clamp(200, 4000));
      }
    }
  }

  Brightness? _shownBrightness;

  /// What a mined card holds, as it would arrive in each field.
  static final _sample = {
    CardSource.word: '精霊',
    CardSource.reading: 'せいれい',
    CardSource.definition:
        '<ul><li>spirit</li><li>soul</li><li>ghost</li></ul>',
    CardSource.sentence: 'あれから　<b>精霊</b>たちは　どうだ？',
    CardSource.image: '<img src="data:image/svg+xml;utf8,$_scene">',
    CardSource.wordAudio: '[sound:word.mp3]',
    CardSource.audio: '[sound:sentence.m4a]',
    CardSource.source: '[Source]',
  };

  /// A stand-in screenshot: sky, hills and a sunset, 16:9.
  static final _scene = Uri.encodeComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360">'
    '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#5b7fb5"/><stop offset="0.7" stop-color="#e8b27a"/></linearGradient></defs>'
    '<rect width="640" height="360" fill="url(#s)"/><circle cx="470" cy="210" r="46" fill="#f6d98c"/>'
    '<path d="M0 260 Q160 200 320 250 T640 230 V360 H0Z" fill="#3e5a4a"/>'
    '<path d="M0 300 Q200 260 400 300 T640 290 V360 H0Z" fill="#2b4034"/></svg>',
  );

  void _render(Brightness brightness) {
    _shownBrightness = brightness;
    final d = _design;
    final values = {
      for (final e in d.fieldMap.entries) e.key: _sample[e.value] ?? '',
    };
    final front = renderCardTemplate(d.front, values);
    final html = _back
        ? renderCardTemplate(d.back, values, frontSide: front)
        : front;
    final night = brightness == Brightness.dark ? ' nightMode' : '';
    _web.loadHtmlString(
      '<!doctype html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<style>${d.css}\n'
      '.kh-play{display:inline-flex;width:1.6em;height:1.6em;border-radius:50%;align-items:center;'
      'justify-content:center;border:1.5px solid currentColor;font-size:0.8em;margin:0.2em;opacity:.8}</style>'
      '</head><body class="card$night">$html</body></html>',
    );
  }

  Future<void> _use() async {
    final anki = ref.read(ankiBridgeProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final status = await anki.status();
      if (!status.installed) {
        throw AnkiException('Install AnkiDroid and open it once first');
      }
      if (!status.permission && !await anki.requestPermission()) {
        throw AnkiException(
          'Kotohori needs permission to add a note type to AnkiDroid',
        );
      }
      final id = await _design.ensure(anki);
      final model = (await anki.models()).firstWhere((m) => m.id == id);
      // Our field names map exactly; a same-named note type edited by hand falls back to guessing.
      final guessed = guessFieldMap(model.fields);
      final map = {
        for (final f in model.fields) f: _design.fieldMap[f] ?? guessed[f]!,
      };
      await ref
          .read(ankiSettingsProvider.notifier)
          .update((s) => s.copyWith(modelId: id, fieldMap: map));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cards now use "${_design.name}". Every field is set up.',
          ),
        ),
      );
      navigator.pop();
    } on AnkiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final brightness = t.brightness;
    if (_shownBrightness != brightness) _render(brightness);
    final current = ref.watch(ankiSettingsProvider).modelId;
    return Scaffold(
      appBar: AppBar(title: const Text('Card designs')),
      body: ListView(
        padding: pagePadding(context, maxWidth: 900, top: 8),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in noteDesigns)
                ChoiceChip(
                  label: Text(d.name.replaceFirst('Kotohori ', '')),
                  selected: d == _design,
                  onSelected: (_) {
                    setState(() => _design = d);
                    _render(brightness);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_design.name, style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Front')),
                  ButtonSegment(value: true, label: Text('Back')),
                ],
                selected: {_back},
                onSelectionChanged: (v) {
                  setState(() => _back = v.single);
                  _render(brightness);
                },
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _use,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Use this design'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: _cardHeight,
              child: WebViewWidget(controller: _web),
            ),
          ),
          if (_design.credit case final c?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 16,
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            current == null
                ? 'Adds the note type to AnkiDroid and makes new cards use it.'
                : 'Adds the note type to AnkiDroid (or reuses it if you already have it) and makes new cards use it. '
                      'Cards you already made keep their note type.',
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
