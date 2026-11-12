import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../platform/anki_bridge.dart';
import '../../app/theme.dart';
import 'anki_providers.dart';
import 'anki_settings.dart';
import 'card_exporter.dart';

/// Review and edit a card before sending it to AnkiDroid.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.draft});

  /// Opens at once: its media fills in while the editor is shown.
  final CardDraft draft;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  late final CardDraft _d = widget.draft;
  final _sentence = TextEditingController();
  final _word = TextEditingController();
  final _reading = TextEditingController();
  final _definition = TextEditingController();
  final _source = TextEditingController();
  final _preview = WebViewController();
  var _editHtml = false;
  var _sending = false;
  var _sent = false;
  // Read once: ref must not be used in dispose().
  late final _exporter = ref.read(cardExporterProvider);
  late final _media = ref.read(mediaToolsProvider);
  List<AnkiDeck>? _decks; // null while loading / if AnkiDroid can't be reached

  @override
  void initState() {
    super.initState();
    (_exporter, _media);
    ref.read(ankiBridgeProvider).decks().then((d) {
      if (mounted) setState(() => _decks = d);
    }, onError: (_) {});
    final d = _d;
    _sentence.text = d.sentence;
    _word.text = d.word;
    _reading.text = d.reading;
    _definition.text = d.definition;
    _source.text = d.source;
    _loadPreview();
  }

  void _loadPreview() => _preview.loadHtmlString(
    '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    '<style>body{margin:8px;font-family:system-ui,sans-serif;}</style></head><body>${_definition.text}</body></html>',
  );

  @override
  void dispose() {
    if (!_sent) {
      _exporter.discard(_d); // cancelled: remove temp media once it's made
    }
    _d.dispose();
    _media.stopAudio();
    for (final c in [_sentence, _word, _reading, _definition, _source]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _playAudio(String path) => _media.playAudio(path);

  Future<void> _send({bool allowDuplicate = false}) async {
    final d = _d
      ..sentence = _sentence.text
      ..word = _word.text
      ..reading = _reading.text
      ..definition = _definition.text
      ..source = _source.text;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(cardExporterProvider)
          .send(
            d,
            ref.read(ankiSettingsProvider),
            // Already marked in the popup: the user knows, so don't ask again.
            allowDuplicate: allowDuplicate || d.alreadyInAnki,
          );
      _sent = true;
      ref.read(cardExporterProvider).discard(d);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added "${d.word}" to Anki')),
      );
    } on DuplicateNoteException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final again = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Already in Anki'),
          content: Text(
            'A card for "${e.word}" already exists in this note type.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (again == true) await _send(allowDuplicate: true);
    } on AnkiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final settings = ref.watch(ankiSettingsProvider);
    final configured = settings.isConfigured;
    final decks = _decks;
    final narrow =
        MediaQuery.sizeOf(context).width <
        600; // phone portrait: deck + Add only
    return Scaffold(
      appBar: AppBar(
        title: narrow ? null : const Text('New card'),
        // Reads as one action: "Add to [deck ▾] [Add]". Picking a deck here also makes it the default.
        actions: [
          if (!narrow) ...[
            Text(
              'Add to',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _DeckPicker(
            decks: decks,
            selected: decks?.where((x) => x.id == settings.deckId).firstOrNull,
            onSelected: (id) => ref
                .read(ankiSettingsProvider.notifier)
                .update((s) => s.copyWith(deckId: id)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _sending || !configured ? null : _send,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: d,
        builder: (context, _) => ListView(
          padding: pagePadding(context),
          children: [
            if (!configured)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Set up Anki first'),
                  subtitle: Text(
                    'Choose a deck, note type and fields in Settings → Anki.',
                  ),
                ),
              ),
            if (d.alreadyInAnki)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Already in Anki'),
                  subtitle: Text(
                    'You have a card for "${d.word}" in '
                    '${d.existingDecks!.join(', ')}. Adding makes another one.',
                  ),
                ),
              ),
            for (final w in d.mediaWarnings)
              ListTile(
                dense: true,
                leading: const Icon(Icons.warning_amber_outlined),
                title: Text(w),
              ),
            if (d.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(d.imagePath!), fit: BoxFit.fitWidth),
              )
            else if (d.imagePending)
              const _MediaPlaceholder(),
            if (d.wordAudioPath != null ||
                d.audioPath != null ||
                d.wordAudioPending ||
                d.audioPending)
              Wrap(
                spacing: 8,
                children: [
                  if (d.wordAudioPath != null || d.wordAudioPending)
                    _AudioButton(
                      'Play word audio',
                      d.wordAudioPath,
                      onPlay: _playAudio,
                    ),
                  if (d.audioPath != null || d.audioPending)
                    _AudioButton(
                      'Play sentence audio',
                      d.audioPath,
                      onPlay: _playAudio,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            _field('Sentence', _sentence, maxLines: 3),
            _field('Word', _word),
            _field('Reading', _reading),
            Row(
              children: [
                Text(
                  'Definition',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (_editHtml) _loadPreview();
                    setState(() => _editHtml = !_editHtml);
                  },
                  child: Text(_editHtml ? 'Preview' : 'Edit HTML'),
                ),
              ],
            ),
            if (_editHtml)
              _field('Definition (HTML)', _definition, maxLines: 12)
            else
              SizedBox(height: 260, child: WebViewWidget(controller: _preview)),
            const SizedBox(height: 12),
            _field('Source', _source),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          minLines: 1,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

/// The target deck as a tappable pill with a menu of all decks.
class _DeckPicker extends StatelessWidget {
  const _DeckPicker({
    required this.decks,
    required this.selected,
    required this.onSelected,
  });
  final List<AnkiDeck>? decks;
  final AnkiDeck? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final list = decks;
    final missing = list != null && selected == null;
    // Clipped so the tap highlight is pill-shaped like the button, not a grey rectangle.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: PopupMenuButton<int>(
        tooltip: 'Choose deck',
        enabled: list != null && list.isNotEmpty,
        onSelected: onSelected,
        // Styled to belong to the pill: drops below it, same rounding, gold for the current deck.
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        color: c.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        // Never taller than the room below the button: otherwise Flutter slides the
        // growing menu up over the button mid-animation. Long deck lists scroll instead.
        constraints: BoxConstraints(
          minWidth: 260,
          maxWidth: 420,
          maxHeight: math.max(
            200,
            MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                kToolbarHeight -
                32,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.outlineVariant),
        ),
        itemBuilder: (_) => [
          for (final x in [...?list]..sort((a, b) => a.name.compareTo(b.name)))
            PopupMenuItem(
              value: x.id,
              height: 44,
              child: _deckRow(context, x, x.id == selected?.id),
            ),
        ],
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width < 600 ? 170 : 280,
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          decoration: BoxDecoration(
            // Gold like the Add button next to it: grey-on-grey made the deck easy to miss.
            color: (missing ? c.error : c.primary).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: missing ? c.error : c.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_outlined,
                size: 18,
                color: missing ? c.error : c.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  list == null
                      ? 'Loading decks…'
                      : selected?.name ?? 'Choose a deck',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: missing ? c.error : c.primary,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: missing ? c.error : c.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-decks ("Parent::Child") are indented under their parent and show only their own name.
  Widget _deckRow(BuildContext context, AnkiDeck deck, bool isSelected) {
    final c = Theme.of(context).colorScheme;
    final parts = deck.name.split('::');
    return Row(
      children: [
        SizedBox(width: 16.0 * (parts.length - 1)),
        SizedBox(
          width: 28,
          child: isSelected
              ? Icon(Icons.check, size: 18, color: c.primary)
              : null,
        ),
        Flexible(
          child: Text(
            parts.last,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? c.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Where the screenshot will appear, while it's being made.
class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Capturing screenshot…',
                style: TextStyle(color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A play button that shows a spinner (and is disabled) until its clip exists.
class _AudioButton extends StatelessWidget {
  const _AudioButton(this.label, this.path, {required this.onPlay});
  final String label;
  final String? path;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context) {
    final p = path;
    return TextButton.icon(
      onPressed: p == null ? null : () => onPlay(p),
      icon: p == null
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
      label: Text(label),
    );
  }
}
