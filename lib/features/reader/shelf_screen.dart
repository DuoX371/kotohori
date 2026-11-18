import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../dictionary/ui/providers.dart' show appPathsProvider, prefsProvider;
import '../notices/notices_button.dart';
import '../settings/settings_screen.dart';
import 'epub.dart';
import 'library_db.dart';
import 'reader_providers.dart';
import 'book_details_sheet.dart';
import 'reader_screen.dart';
import 'reading_status.dart';
import 'shelf_layout.dart';

/// The Reader tab: the user's books, most recently read first.
class ReaderShelfScreen extends ConsumerStatefulWidget {
  const ReaderShelfScreen({super.key});

  @override
  ConsumerState<ReaderShelfScreen> createState() => _ReaderShelfScreenState();
}

class _ReaderShelfScreenState extends ConsumerState<ReaderShelfScreen>
    with SingleTickerProviderStateMixin {
  Set<String>? _selected;

  static const _tabKey = 'reader.shelf.tab';

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: ShelfFilter.values.length,
      initialIndex: (ref.read(prefsProvider).getInt(_tabKey) ?? 0).clamp(
        0,
        ShelfFilter.values.length - 1,
      ),
      vsync: this,
    )..addListener(_tabChanged);
  }

  ShelfFilter get _filter => ShelfFilter.values[_tabs.index];

  void _tabChanged() {
    setState(() {}); // "Select all" works on the books shown
    ref.read(prefsProvider).setInt(_tabKey, _tabs.index);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _toggle(Book book) => setState(() {
    final s = _selected!;
    s.contains(book.hash) ? s.remove(book.hash) : s.add(book.hash);
  });

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider).value;
    final selected = _selected;
    // Back leaves selection mode first.
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Scaffold(
        appBar: selected != null
            ? AppBar(
                leading: IconButton(
                  tooltip: 'Done selecting',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selected = null),
                ),
                title: Text('${selected.length} selected'),
                actions: [
                  // Toggles: once everything shown is ticked, it unticks all.
                  if (_filter
                      .apply(books ?? const [])
                      .every((b) => selected.contains(b.hash)))
                    IconButton(
                      tooltip: 'Deselect all',
                      icon: const Icon(Icons.deselect),
                      onPressed: () => setState(() => _selected = {}),
                    )
                  else
                    IconButton(
                      tooltip: 'Select all',
                      icon: const Icon(Icons.select_all),
                      onPressed: () => setState(
                        () => _selected = {
                          for (final b in _filter.apply(books ?? <Book>[]))
                            b.hash,
                        },
                      ),
                    ),
                ],
              )
            : AppBar(
                title: const Text('Reader'),
                actions: [
                  if (books?.isNotEmpty ?? false)
                    IconButton(
                      tooltip: 'Select',
                      icon: const Icon(Icons.checklist),
                      onPressed: () => setState(() => _selected = {}),
                    ),
                  const NoticesButton(),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
        // What happens to the ticked books, in words (icons alone were
        // mistaken for "select"/"close").
        bottomNavigationBar: selected == null
            ? null
            : BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_allFinished(books ?? const [], selected))
                      TextButton.icon(
                        onPressed: () =>
                            _markFinished(context, books ?? const [], false),
                        icon: const Icon(Icons.remove_done),
                        label: const Text('Mark not completed'),
                      )
                    else
                      TextButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () => _markFinished(
                                context,
                                books ?? const [],
                                true,
                              ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark completed'),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: selected.isEmpty
                          ? null
                          : () => _removeSelected(context, books ?? const []),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ),
        floatingActionButton: (books?.isNotEmpty ?? false) && selected == null
            ? FloatingActionButton.extended(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add book'),
              )
            : null,
        body: switch (books) {
          null => const Center(child: CircularProgressIndicator()),
          [] => Center(
            child: FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add your first book'),
            ),
          ),
          final all => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  for (final f in ShelfFilter.values)
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(f.label),
                          const SizedBox(width: 6),
                          Text(
                            '${f.apply(all).length}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : 180,
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_filter),
                    child: _shelf(
                      context,
                      _filter,
                      _filter.apply(all),
                      selected,
                    ),
                  ),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }

  Widget _shelf(
    BuildContext context,
    ShelfFilter filter,
    List<Book> books,
    Set<String>? selected,
  ) {
    final t = Theme.of(context);
    return switch (books) {
      [] => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter == ShelfFilter.finished
                  ? 'No completed books yet'
                  : 'No books in progress',
              style: t.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filter == ShelfFilter.finished
                  ? 'Hold a book to mark it completed.'
                  : 'Books you have started show up here.',
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      final list => LayoutBuilder(
        builder: (context, box) {
          final layout = ShelfLayout(box.maxWidth);
          final still = MediaQuery.disableAnimationsOf(context);
          return SingleChildScrollView(
            child: SizedBox(
              height: layout.height(list.length),
              child: Stack(
                children: [
                  for (final (i, book) in list.indexed.toList().reversed)
                    AnimatedPositioned.fromRect(
                      key: ValueKey(book.hash),
                      rect: layout.slot(i),
                      duration: Duration(milliseconds: still ? 0 : 450),
                      curve: Curves.easeInOutCubic,
                      child: _BookTile(
                        book,
                        selected: selected?.contains(book.hash),
                        onOpen: () => selected != null
                            ? _toggle(book)
                            : _open(context, book),
                        onHold: (rect) async => selected != null
                            ? _toggle(book)
                            : await _menu(context, book, rect),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    };
  }

  bool _allFinished(List<Book> books, Set<String> selected) {
    final chosen = [
      for (final b in books)
        if (selected.contains(b.hash)) b,
    ];
    return chosen.isNotEmpty && chosen.every((b) => b.finishedAt != null);
  }

  Future<void> _menu(BuildContext context, Book book, Rect cover) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final red = Theme.of(context).colorScheme.error;
    final finished = statusOf(book) == ReadingStatus.finished;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromCenter(center: cover.center, width: 0, height: 0),
        Offset.zero & overlay.size,
      ),
      items: [
        if (!finished)
          const PopupMenuItem(
            value: 'finish',
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Mark as completed'),
            ),
          )
        else if (book.finishedAt != null)
          const PopupMenuItem(
            value: 'unfinish',
            child: ListTile(
              leading: Icon(Icons.remove_done),
              title: Text('Mark as not completed'),
            ),
          ),
        const PopupMenuItem(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Details'),
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: red),
            title: Text('Remove…', style: TextStyle(color: red)),
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    final repo = ref.read(bookRepoProvider);
    switch (choice) {
      case 'finish':
        await repo.setFinished([book.hash], true);
      case 'unfinish':
        await repo.setFinished([book.hash], false);
      case 'details':
        await showBookDetails(
          context,
          book,
          onContinue: () => _open(context, book),
          onRemove: () => _remove(context, ref, book),
        );
      case 'remove':
        await _remove(context, ref, book);
    }
  }

  /// Marks the ticked books finished (or not) and leaves selection mode.
  Future<void> _markFinished(
    BuildContext context,
    List<Book> books,
    bool finished,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(bookRepoProvider);
    final hashes = _selected!.toList();
    // Undo puts back only the books this changed.
    final changed = [
      for (final b in books)
        if (hashes.contains(b.hash) && (b.finishedAt != null) != finished)
          b.hash,
    ];
    await repo.setFinished(hashes, finished);
    if (mounted) setState(() => _selected = null);
    final n = hashes.length;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Marked $n book${n == 1 ? '' : 's'} '
            '${finished ? 'completed' : 'not completed'}',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.setFinished(changed, !finished),
          ),
        ),
      );
  }

  /// Asks once, then removes every ticked book and leaves selection mode.
  Future<void> _removeSelected(BuildContext context, List<Book> books) async {
    final messenger = ScaffoldMessenger.of(context);
    final chosen = [
      for (final b in books)
        if (_selected!.contains(b.hash)) b,
    ];
    final n = chosen.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          n == 1 ? 'Remove "${chosen.single.title}"?' : 'Remove $n books?',
        ),
        content: Text(
          n == 1
              ? "Kotohori deletes its copy and your reading position. "
                    "Your original file isn't touched."
              : "Kotohori deletes its copies and your reading positions. "
                    "Your original files aren't touched.",
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
    final repo = ref.read(bookRepoProvider);
    for (final b in chosen) {
      await repo.remove(b.hash);
    }
    if (mounted) setState(() => _selected = null);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Removed $n book${n == 1 ? '' : 's'}')),
      );
  }

  void _open(BuildContext context, Book book) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book)));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    void say(String text, {Duration duration = const Duration(seconds: 4)}) =>
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(text), duration: duration));
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    if (picked.isEmpty) return;

    if (picked.length == 1) {
      final r = await _addOne(ref, picked.single);
      switch (r) {
        case (book: final book?, existed: final existed, error: null):
          if (existed) say('Already on your shelf');
          if (context.mounted) _open(context, book);
        case (error: final e?, book: _, existed: _):
          say(
            e == EpubError.drm
                ? "This book is DRM-protected, so Kotohori can't open it."
                : "Couldn't open this book. It may not be a valid EPUB.",
          );
        default:
      }
      return;
    }

    var added = 0, existed = 0, failed = 0;
    for (final (i, file) in picked.indexed) {
      say(
        'Adding ${i + 1} of ${picked.length}…',
        duration: const Duration(minutes: 5),
      );
      final r = await _addOne(ref, file);
      if (r.error != null) {
        failed++;
      } else if (r.existed) {
        existed++;
      } else {
        added++;
      }
    }
    say(importSummary(added: added, existed: existed, failed: failed));
  }

  Future<({Book? book, bool existed, EpubError? error})> _addOne(
    WidgetRef ref,
    PlatformFile picked,
  ) async {
    var path = picked.path;
    File? temp;
    try {
      if (path == null) {
        // content:// URI (Android SAF): stream it to a temp file first.
        temp = File(
          p.join(
            ref.read(appPathsProvider).tempDir,
            'book_${DateTime.now().microsecondsSinceEpoch}.epub',
          ),
        );
        final sink = temp.openWrite();
        await sink.addStream(picked.readAsByteStream());
        await sink.close();
        path = temp.path;
      }
      final r = await ref.read(bookRepoProvider).addFromFile(path);
      return (book: r.book, existed: r.existed, error: null);
    } on EpubException catch (e) {
      return (book: null, existed: false, error: e.error);
    } on Object {
      return (book: null, existed: false, error: EpubError.invalid);
    } finally {
      temp?.delete().ignore();
    }
  }

  /// Asks, then removes; true if the book was removed.
  Future<bool> _remove(BuildContext context, WidgetRef ref, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove "${book.title}"?'),
        content: const Text(
          "Kotohori deletes its copy and your reading position. "
          "Your original file isn't touched.",
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
    if (ok != true) return false;
    await ref.read(bookRepoProvider).remove(book.hash);
    return true;
  }
}

class _BookTile extends StatefulWidget {
  const _BookTile(
    this.book, {
    required this.onOpen,
    required this.onHold,
    this.selected,
  });
  final Book book;
  final VoidCallback onOpen;

  final bool? selected;

  /// Long-press, with where the tile is on screen (for the menu); the cover
  /// stays lifted until it completes.
  final Future<void> Function(Rect tile) onHold;

  @override
  State<_BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<_BookTile> {
  var _pressed = false;
  var _held = false; // the long-press menu is open

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final t = Theme.of(context);
    final percent = (book.progress * 100).floor();
    final still = MediaQuery.disableAnimationsOf(context);
    // No grey highlight box: while held, the cover lifts (grows a little,
    // with a shadow), and a long-press gives a short buzz as the details open.
    return InkWell(
      onTap: widget.onOpen,
      onLongPress: () async {
        HapticFeedback.mediumImpact();
        final box = context.findRenderObject() as RenderBox;
        setState(() => _held = true);
        await widget.onHold(box.localToGlobal(Offset.zero) & box.size);
        if (mounted) setState(() => _held = false);
      },
      onHighlightChanged: (down) => setState(() => _pressed = down),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedScale(
              scale: _pressed || _held ? 1.06 : 1,
              duration: Duration(milliseconds: still ? 0 : 150),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: Duration(milliseconds: still ? 0 : 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (_pressed || _held)
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColoredBox(
                        color: t.colorScheme.surfaceContainerHighest,
                        child: book.coverPath == null
                            ? Icon(
                                Icons.menu_book_outlined,
                                size: 48,
                                color: t.colorScheme.onSurfaceVariant,
                              )
                            : Image.file(
                                File(book.coverPath!),
                                cacheWidth: 300,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.menu_book_outlined,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    if (widget.selected case final ticked?) ...[
                      if (ticked)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: t.colorScheme.primary.withValues(
                              alpha: 0.25,
                            ),
                            border: Border.all(
                              color: t.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ticked
                                ? t.colorScheme.primary
                                : Colors.black45,
                          ),
                          child: Icon(
                            ticked ? Icons.check : Icons.circle_outlined,
                            size: 24,
                            color: ticked
                                ? t.colorScheme.onPrimary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (statusOf(book) == ReadingStatus.finished)
            Text(
              'Completed',
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: book.progress)),
                const SizedBox(width: 8),
                Text('$percent%', style: t.textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

String importSummary({
  required int added,
  required int existed,
  required int failed,
}) => [
  if (added > 0) 'Added $added book${added == 1 ? '' : 's'}',
  if (existed > 0) '$existed already on your shelf',
  if (failed > 0) "$failed couldn't be opened",
].join(' · ');
