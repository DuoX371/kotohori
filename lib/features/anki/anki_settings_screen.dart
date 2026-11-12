import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../platform/anki_bridge.dart';
import 'anki_providers.dart';
import 'anki_settings.dart';
import 'card_builder.dart';
import 'note_designs_screen.dart';

/// Settings → Anki: deck, note type, field mapping, media options.
class AnkiSettingsScreen extends ConsumerStatefulWidget {
  const AnkiSettingsScreen({super.key});

  @override
  ConsumerState<AnkiSettingsScreen> createState() => _AnkiSettingsScreenState();
}

class _AnkiSettingsScreenState extends ConsumerState<AnkiSettingsScreen> {
  AnkiStatus? _status;
  List<AnkiDeck> _decks = const [];
  List<AnkiModel> _models = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final anki = ref.read(ankiBridgeProvider);
    final status = await anki.status();
    setState(() {
      _status = status;
      _error = null;
    });
    if (!status.installed || !status.permission) return;
    try {
      final decks = await anki.decks(), models = await anki.models();
      if (mounted) {
        setState(() {
          _decks = decks;
          _models = models;
        });
      }
    } on AnkiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _grant() async {
    await ref.read(ankiBridgeProvider).requestPermission();
    await _load();
  }

  void _pickModel(AnkiModel m) {
    ref
        .read(ankiSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(modelId: m.id, fieldMap: guessFieldMap(m.fields)),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(ankiSettingsProvider);
    final notifier = ref.read(ankiSettingsProvider.notifier);
    final model = _models.where((m) => m.id == s.modelId).firstOrNull;
    final status = _status;

    return Scaffold(
      appBar: AppBar(title: const Text('Anki')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: pagePadding(context, top: 0),
              children: [
                if (!status.installed)
                  _Banner(
                    text: 'AnkiDroid is not installed. Install it, open it once, then come back.',
                    action: 'Get AnkiDroid',
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.ichi2.anki',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  )
                else if (!status.permission)
                  _Banner(
                    text:
                        'Kotohori needs permission to add cards to AnkiDroid.',
                    action: 'Allow',
                    onPressed: _grant,
                  )
                else if (_error != null)
                  _Banner(text: _error!, action: 'Retry', onPressed: _load),
                Section(
                  title: 'Cards go to',
                  children: [
                    ListTile(
                      title: const Text('Deck'),
                      trailing: DropdownButton<int>(
                        value: _decks.any((d) => d.id == s.deckId)
                            ? s.deckId
                            : null,
                        hint: const Text('Choose'),
                        underline: const SizedBox(),
                        items: [
                          for (final d in _decks)
                            DropdownMenuItem(value: d.id, child: Text(d.name)),
                        ],
                        onChanged: (id) =>
                            notifier.update((x) => x.copyWith(deckId: id)),
                      ),
                    ),
                    ListTile(
                      title: const Text('Note type'),
                      trailing: DropdownButton<int>(
                        value: model?.id,
                        hint: const Text('Choose'),
                        underline: const SizedBox(),
                        items: [
                          for (final m in _models)
                            DropdownMenuItem(value: m.id, child: Text(m.name)),
                        ],
                        onChanged: (id) =>
                            _pickModel(_models.firstWhere((m) => m.id == id)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.style_outlined),
                      title: const Text('Card designs'),
                      subtitle: Text(
                        model == null
                            ? "Don't have a note type? Pick a ready-made one: Classic, Modern, Cinema or Focus"
                            : 'Ready-made note types: Classic, Modern, Cinema or Focus',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NoteDesignsScreen(),
                          ),
                        );
                        _load(); // a new note type may have been added
                      },
                    ),
                  ],
                ),
                if (model != null)
                  Section(
                    title: 'Fields',
                    footer: 'What goes into each field of "${model.name}".',
                    children: [
                      for (final f in model.fields)
                        // Name and choice share the row 2:3, so neither gets squeezed on a phone.
                        ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(f, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: DropdownButton<CardSource>(
                                  value: s.fieldMap[f] ?? CardSource.none,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: [
                                    for (final c in CardSource.values)
                                      DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (c) => notifier.update(
                                    (x) => x.copyWith(
                                      fieldMap: {...x.fieldMap, f: c!},
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                Section(
                  title: 'Screenshot',
                  children: [
                    SwitchListTile(
                      title: const Text('Include screenshot'),
                      value: s.includeScreenshot,
                      onChanged: (v) => notifier.update(
                        (x) => x.copyWith(includeScreenshot: v),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Show subtitle in screenshot'),
                      value: s.subtitleInScreenshot,
                      onChanged: s.includeScreenshot
                          ? (v) => notifier.update(
                              (x) => x.copyWith(subtitleInScreenshot: v),
                            )
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('Full-size screenshot'),
                      subtitle: const Text(
                        'Off: scaled to 640 px wide (~50 KB per card)',
                      ),
                      value: s.fullSizeScreenshot,
                      onChanged: s.includeScreenshot
                          ? (v) => notifier.update(
                              (x) => x.copyWith(fullSizeScreenshot: v),
                            )
                          : null,
                    ),
                  ],
                ),
                Section(
                  title: 'Word audio',
                  footer: 'Downloaded from JapanesePod101 when you add a card (needs internet).',
                  children: [
                    SwitchListTile(
                      title: const Text('Include word audio'),
                      subtitle: const Text('A native speaker saying the word'),
                      value: s.includeWordAudio,
                      onChanged: (v) => notifier.update(
                        (x) => x.copyWith(includeWordAudio: v),
                      ),
                    ),
                  ],
                ),
                Section(
                  title: 'Sentence audio',
                  children: [
                    SwitchListTile(
                      title: const Text('Include sentence audio'),
                      subtitle: const Text(
                        'Audio of the subtitle line (.m4a, ~10 KB per second)',
                      ),
                      value: s.includeAudio,
                      onChanged: (v) =>
                          notifier.update((x) => x.copyWith(includeAudio: v)),
                    ),
                    _PaddingTile(
                      label: 'Start earlier by',
                      ms: s.paddingBeforeMs,
                      enabled: s.includeAudio,
                      onChanged: (v) => notifier.update(
                        (x) => x.copyWith(paddingBeforeMs: v),
                      ),
                    ),
                    _PaddingTile(
                      label: 'End later by',
                      ms: s.paddingAfterMs,
                      enabled: s.includeAudio,
                      onChanged: (v) =>
                          notifier.update((x) => x.copyWith(paddingAfterMs: v)),
                    ),
                  ],
                ),
                Section(
                  title: 'Definition',
                  children: [
                    SwitchListTile(
                      title: const Text('First dictionary only'),
                      subtitle: const Text(
                        'Off: every enabled dictionary that has the word',
                      ),
                      value: s.firstDictionaryOnly,
                      onChanged: (v) => notifier.update(
                        (x) => x.copyWith(firstDictionaryOnly: v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.action,
    required this.onPressed,
  });
  final String text;
  final String action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 16),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          const SizedBox(width: 8),
          FilledButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    ),
  );
}

class _PaddingTile extends StatelessWidget {
  const _PaddingTile({
    required this.label,
    required this.ms,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final int ms;
  final bool enabled;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Slider(
      value: ms.toDouble(),
      max: 1000,
      divisions: 20,
      label: '${(ms / 1000).toStringAsFixed(2)} s',
      onChanged: enabled ? (v) => onChanged(v.round()) : null,
    ),
    trailing: Text('${(ms / 1000).toStringAsFixed(2)} s'),
  );
}
