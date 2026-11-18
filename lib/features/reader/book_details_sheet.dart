import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../anki/anki_providers.dart' show cardExporterProvider;
import '../anki/anki_settings.dart' show ankiSettingsProvider;
import 'book_stats.dart';

import 'library_db.dart';
import 'reader_providers.dart';
import 'reading_clock.dart' show timeLeft;

/// "ja" / "ja-JP" → "Japanese"; codes not listed are shown as written.
String languageName(String code) =>
    const {
      'ja': 'Japanese',
      'en': 'English',
      'zh': 'Chinese',
      'ko': 'Korean',
      'fr': 'French',
      'de': 'German',
      'es': 'Spanish',
    }[code.split(RegExp('[-_]')).first.toLowerCase()] ??
    code.toUpperCase();

/// Opens [book]'s details as a bottom sheet. Without [onContinue]/[onRemove]
/// (inside the reader) those buttons are left out. [onRemove] asks first and
/// says whether the book went; the sheet stays open if it didn't.
Future<void> showBookDetails(
  BuildContext context,
  Book book, {
  VoidCallback? onContinue,
  Future<bool> Function()? onRemove,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    child: BookDetails(
      book,
      onContinue: onContinue == null
          ? null
          : () {
              Navigator.of(context).pop();
              onContinue();
            },
      onRemove: onRemove == null
          ? null
          : () async {
              final navigator = Navigator.of(context);
              if (await onRemove()) navigator.pop();
            },
    ),
  ),
);

/// Cover, title, author, publisher, series, blurb and reading progress.
class BookDetails extends ConsumerStatefulWidget {
  const BookDetails(this.book, {super.key, this.onContinue, this.onRemove});
  final Book book;
  final VoidCallback? onContinue;
  final VoidCallback? onRemove;

  @override
  ConsumerState<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends ConsumerState<BookDetails> {
  var _fullBlurb = false;

  /// Opens AnkiDroid's card browser on the cards mined from [book].
  Future<void> _browseCards(Book book) async {
    final uri = await ref
        .read(cardExporterProvider)
        .browseSourceUri(book.title, ref.read(ankiSettingsProvider));
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodyMedium?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    // The shelf's row may be newer than the one we were given (in the reader).
    final book =
        ref
            .watch(booksProvider)
            .value
            ?.where((b) => b.hash == widget.book.hash)
            .firstOrNull ??
        widget.book;
    final d = ref.watch(bookDetailsProvider(book.hash)).value;
    final dates = MaterialLocalizations.of(context);
    String date(int ms) =>
        dates.formatMediumDate(DateTime.fromMillisecondsSinceEpoch(ms));
    final published = [
      ?d?.publisher,
      ?d?.year,
      if (d?.language case final l?) languageName(l),
    ].join(' · ');
    final read = (book.progress * 100).floor();
    final lengths = (jsonDecode(book.chapterLengths) as List).cast<int>();
    final chars = lengths.fold(0, (a, b) => a + b);
    final remaining =
        chars - charsRead(lengths, chapter: book.chapter, offset: book.offset);
    final pace = ref.watch(readerPaceProvider);
    final cards = ref.watch(cardsMinedProvider(book.title)).value;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 96,
                    height: 136,
                    child: ColoredBox(
                      color: t.colorScheme.surfaceContainerHighest,
                      child: book.coverPath == null
                          ? const Icon(Icons.menu_book_outlined, size: 40)
                          : Image.file(
                              File(book.coverPath!),
                              cacheWidth: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.menu_book_outlined),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: t.textTheme.titleLarge),
                      if (book.author ?? d?.author case final a?) ...[
                        const SizedBox(height: 4),
                        Text(a, style: t.textTheme.titleSmall),
                      ],
                      for (final (label, names) in [
                        ('Illustration', d?.illustrators ?? const <String>[]),
                        ('Translation', d?.translators ?? const <String>[]),
                      ])
                        if (names.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('$label: ${names.join(', ')}', style: muted),
                        ],
                      if (published.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(published, style: muted),
                      ],
                      if (d?.series case final series?) ...[
                        const SizedBox(height: 4),
                        Text(
                          d?.seriesIndex == null
                              ? series
                              : '$series #${d!.seriesIndex}',
                          style: muted,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (d?.description case final blurb?) ...[
              const SizedBox(height: 16),
              // Long blurbs start folded; a tap shows all of it.
              InkWell(
                onTap: () => setState(() => _fullBlurb = !_fullBlurb),
                child: Text(
                  blurb,
                  maxLines: _fullBlurb ? null : 6,
                  overflow: _fullBlurb ? null : TextOverflow.ellipsis,
                  style: t.textTheme.bodyMedium,
                ),
              ),
            ],
            if (d?.subjects case final genres? when genres.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final g in genres)
                    Chip(label: Text(g), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _Stat(
              'Length',
              '${lengths.length} chapter${lengths.length == 1 ? '' : 's'} · '
                  '${grouped(chars)} characters',
            ),
            if (book.readingMs > 0)
              _Stat(
                'Time spent',
                durationLabel(Duration(milliseconds: book.readingMs)),
              ),
            if (remaining > 0)
              _Stat(
                'Time left',
                '~${durationLabel(timeLeft(remainingChars: remaining, charsPerMinute: pace ?? typicalPace))} '
                    '${pace == null ? 'at a typical pace' : 'at your pace'}',
              ),
            if (cards != null)
              _Stat('Cards mined', '$cards', onTap: () => _browseCards(book)),
            if (d?.isbn case final isbn?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('ISBN $isbn', style: t.textTheme.bodySmall),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: book.progress),
            const SizedBox(height: 8),
            Text(
              [
                '$read% read',
                'Added ${date(book.addedAt)}',
                if (book.lastReadAt case final last?) 'Last read ${date(last)}',
              ].join(' · '),
              style: muted,
            ),
            if (widget.onContinue != null || widget.onRemove != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (widget.onRemove case final remove?)
                    TextButton.icon(
                      onPressed: remove,
                      style: TextButton.styleFrom(
                        foregroundColor: t.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                  const Spacer(),
                  if (widget.onContinue case final open?)
                    FilledButton.icon(
                      onPressed: open,
                      icon: const Icon(Icons.menu_book),
                      label: Text(
                        read == 0 && book.lastReadAt == null
                            ? 'Start reading'
                            : 'Continue reading',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One "label  value" row of the reading numbers; tappable when [onTap].
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.onTap});
  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: t.textTheme.bodyMedium)),
          if (onTap != null)
            Icon(Icons.open_in_new, size: 18, color: t.colorScheme.primary),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
