import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../dictionary/ui/providers.dart' show appPathsProvider;
import '../notices/notices_button.dart';
import '../settings/settings_screen.dart';
import 'epub.dart';
import 'library_db.dart';
import 'reader_providers.dart';
import 'book_details_sheet.dart';
import 'reader_screen.dart';

/// The Reader tab: the user's books, most recently read first.
class ReaderShelfScreen extends ConsumerWidget {
  const ReaderShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          const NoticesButton(),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: (books?.isNotEmpty ?? false)
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
        final list => GridView.builder(
          // Room at the bottom so the Add book button never hides a book.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 0.52,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => _BookTile(
            list[i],
            onOpen: () => _open(context, list[i]),
            onDetails: () => showBookDetails(
              context,
              list[i],
              onContinue: () => _open(context, list[i]),
              onRemove: () => _remove(context, ref, list[i]),
            ),
          ),
        ),
      },
    );
  }

  void _open(BuildContext context, Book book) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book)));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    if (picked == null) return;
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
      if (r.existed) say('Already on your shelf');
      if (context.mounted) _open(context, r.book);
    } on EpubException catch (e) {
      say(
        e.error == EpubError.drm
            ? "This book is DRM-protected, so Kotohori can't open it."
            : "Couldn't open this book. It may not be a valid EPUB.",
      );
    } on Object {
      say("Couldn't open this book. It may not be a valid EPUB.");
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
  const _BookTile(this.book, {required this.onOpen, required this.onDetails});
  final Book book;
  final VoidCallback onOpen;

  /// Long-press: the book's details, with Continue and Remove.
  final VoidCallback onDetails;

  @override
  State<_BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<_BookTile> {
  var _pressed = false;

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
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onDetails();
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
              scale: _pressed ? 1.06 : 1,
              duration: Duration(milliseconds: still ? 0 : 150),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: Duration(milliseconds: still ? 0 : 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (_pressed)
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                  ],
                ),
                child: ClipRRect(
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
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.menu_book_outlined, size: 48),
                          ),
                  ),
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
