import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../dictionary/ui/providers.dart' show appPathsProvider;
import 'reader_fonts.dart';
import '../../app/theme.dart';
import 'reader_preview.dart';
import 'reader_providers.dart';
import 'reader_settings.dart';

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key, this.preview = true});

  final bool preview;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reader')),
    body: Column(
      children: [
        if (preview)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SizedBox(height: 260, child: ReaderPreview()),
              ),
            ),
          ),
        const Expanded(child: ReaderSettingsSheet(inSheet: false)),
      ],
    ),
  );
}

class ReaderSettingsSheet extends ConsumerStatefulWidget {
  const ReaderSettingsSheet({super.key, this.inSheet = true, this.book});

  /// False: the body of [ReaderSettingsScreen] (app theme, no drag handle).
  final bool inSheet;

  /// Opened from this book (its hash): offers All books / This book.
  final String? book;

  @override
  ConsumerState<ReaderSettingsSheet> createState() =>
      _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends ConsumerState<ReaderSettingsSheet> {
  bool get inSheet => widget.inSheet;

  /// Editing the book's own settings. Starts there if it has any.
  late bool _thisBook =
      widget.book != null &&
      ref.read(bookSettingsProvider(widget.book!)).isNotEmpty;

  /// Drawn in the reading theme (live as it changes), not the app's.
  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final s = _thisBook
        ? ref.watch(bookReaderSettingsProvider(book!))
        : ref.watch(readerSettingsProvider);
    final current = effectiveTheme(s, Theme.of(context).brightness);
    if (!inSheet) return _content(context, ref, s, current);
    return Theme(
      data: buildTheme(current.isDark ? Brightness.dark : Brightness.light),
      child: Material(
        color: current.background,
        // Same colour as the page: the shadow sets it apart.
        elevation: 12,
        shadowColor: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Builder(
          builder: (context) => _content(context, ref, s, current),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    ReaderSettings s,
    ReaderTheme current,
  ) {
    final t = Theme.of(context);
    final book = widget.book;
    final own = _thisBook
        ? ref.watch(bookSettingsProvider(book!))
        : const <String, Object?>{};
    final update = _update;

    List<Widget> mark(String key) => [
      if (own.containsKey(key)) ...[
        const SizedBox(width: 6),
        Icon(Icons.circle, size: 8, color: t.colorScheme.primary),
        IconButton(
          tooltip: 'Use the global setting',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          icon: const Icon(Icons.restart_alt),
          onPressed: () =>
              ref.read(bookSettingsProvider(book!).notifier).reset(key),
        ),
      ],
    ];

    Widget heading(String label, String key) => SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(label, style: t.textTheme.titleSmall),
          ...mark(key),
        ],
      ),
    );

    Widget slider(
      String label,
      String key,
      double value,
      ({double min, double max}) range,
      double step,
      ReaderSettings Function(double) change,
    ) => Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        ...mark(key),
        Expanded(
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            divisions: ((range.max - range.min) / step).round(),
            label: step < 1 ? value.toStringAsFixed(1) : '${value.round()}',
            onChanged: (v) => update((_) => change(v)),
          ),
        ),
      ],
    );

    // On the settings page the scroll area is full width (so the margins
    // scroll too, like the other settings pages); only the content is kept
    // to a readable 760dp column.
    final side = inSheet
        ? 24.0
        : math.max(24.0, (MediaQuery.sizeOf(context).width - 760) / 2 + 24);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(side, 12, side, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inSheet)
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: t.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (book != null) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('All books')),
                  ButtonSegment(value: true, label: Text('This book')),
                ],
                selected: {_thisBook},
                onSelectionChanged: (v) => setState(() => _thisBook = v.single),
              ),
              const SizedBox(height: 16),
            ],
            heading('Theme', 'theme'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in ReaderTheme.values)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: theme.background),
                    label: Text(theme.label),
                    // Until one is picked, the reader starts in White or Dark
                    // to match the app; that one shows as chosen.
                    selected: current == theme,
                    onSelected: (_) =>
                        update((s) => s.copyWith(theme: () => theme)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            heading('Font', 'font'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label, family) in const [
                  (null, "Book's font", null),
                  (ReaderFonts.serif, 'Serif (Mincho)', 'serif'),
                  (ReaderFonts.sans, 'Sans (Gothic)', 'sans-serif'),
                  (ReaderFonts.zen, 'Zen Kaku Gothic', 'ZenKakuGothicNew'),
                ])
                  ChoiceChip(
                    label: _FontSample(label, family),
                    selected: s.font == id,
                    onSelected: (_) =>
                        update((s) => s.copyWith(font: () => id)),
                  ),
                for (final name in ref.watch(addedFontsProvider))
                  GestureDetector(
                    onLongPress: () => _removeFont(context, name),
                    child: ChoiceChip(
                      label: _FontSample(
                        p.basenameWithoutExtension(name),
                        ref.watch(addedFontFamilyProvider(name)).value,
                      ),
                      selected: s.font == ReaderFonts.fileId(name),
                      onSelected: (_) => update(
                        (s) => s.copyWith(font: () => ReaderFonts.fileId(name)),
                      ),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add font…'),
                  onPressed: () => _addFont(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            heading('Text direction', 'vertical'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Vertical')),
                ButtonSegment(value: false, label: Text('Horizontal')),
              ],
              selected: {s.vertical},
              onSelectionChanged: (v) =>
                  update((s) => s.copyWith(vertical: v.single)),
            ),
            const SizedBox(height: 16),
            heading('Reading mode', 'scroll'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Pages')),
                ButtonSegment(value: true, label: Text('Scroll')),
              ],
              selected: {s.scroll},
              onSelectionChanged: (v) =>
                  update((s) => s.copyWith(scroll: v.single)),
            ),
            const SizedBox(height: 16),
            slider(
              'Font size',
              'fontSize',
              s.fontSize,
              ReaderSettings.fontSizes,
              1,
              (v) => s.copyWith(fontSize: v),
            ),
            slider(
              'Line spacing',
              'lineSpacing',
              s.lineSpacing,
              ReaderSettings.lineSpacings,
              0.1,
              (v) => s.copyWith(lineSpacing: v),
            ),
            slider(
              'Heading size',
              'headingSize',
              s.headingSize,
              ReaderSettings.headingSizes,
              0.1,
              (v) => s.copyWith(headingSize: v),
            ),
            slider(
              'Margins',
              'margin',
              s.margin,
              ReaderSettings.margins,
              4,
              (v) => s.copyWith(margin: v),
            ),
            if (own.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: t.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Only this book')),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(bookSettingsProvider(book!).notifier).clear(),
                    child: const Text('Use global settings'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Changes the global settings, or on the This book tab the book's own.
  Future<void> _update(ReaderSettings Function(ReaderSettings) change) {
    final book = widget.book;
    if (!_thisBook || book == null) {
      return ref.read(readerSettingsProvider.notifier).update(change);
    }
    return ref
        .read(bookSettingsProvider(book).notifier)
        .change(change(ref.read(bookReaderSettingsProvider(book))));
  }

  /// Imports a font file the user picks and switches the reader to it.
  Future<void> _addFont(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFile(type: FileType.any);
    if (picked == null) return;
    File? temp;
    try {
      var path = picked.path;
      if (path == null) {
        // content:// URI (Android SAF): stream it to a temp file first.
        temp = File(p.join(ref.read(appPathsProvider).tempDir, picked.name));
        final sink = temp.openWrite();
        await sink.addStream(picked.readAsByteStream());
        await sink.close();
        path = temp.path;
      }
      final name = await ref.read(addedFontsProvider.notifier).add(path);
      await _update((s) => s.copyWith(font: () => ReaderFonts.fileId(name)));
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pick a font file: .ttf, .otf, .woff or .woff2'),
        ),
      );
    } finally {
      temp?.delete().ignore();
    }
  }

  Future<void> _removeFont(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove "${p.basenameWithoutExtension(name)}"?'),
        content: const Text(
          "Kotohori deletes its copy. Your original file isn't touched.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final settings = ref.read(readerSettingsProvider.notifier);
    if (ref.read(readerSettingsProvider).font == ReaderFonts.fileId(name)) {
      await settings.update((s) => s.copyWith(font: () => null));
    }
    await ref.read(addedFontsProvider.notifier).remove(name);
  }
}

/// A font chip's label drawn in that font: a Japanese sample, then its name.
class _FontSample extends StatelessWidget {
  const _FontSample(this.name, this.family);
  final String name;

  /// Null: the app's font (the book's own font can't be shown here).
  final String? family;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'あア字  ',
          style: TextStyle(fontSize: 18, fontFamily: family),
        ),
        TextSpan(
          text: name,
          style: TextStyle(fontFamily: family),
        ),
      ],
    ),
  );
}
