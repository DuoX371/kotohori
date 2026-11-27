import 'dart:convert';

/// A message from the book page's script (`assets/reader/reader.js`).
sealed class ReaderEvent {
  const ReaderEvent();

  /// Null for anything malformed (the page is the book's, not ours).
  static ReaderEvent? parse(String json) {
    try {
      final m = jsonDecode(json);
      if (m is! Map<String, Object?>) return null;
      List<String> strings(Object? v) => (v as List).cast<String>();
      return switch (m['t']) {
        'tap' => ReaderTap(
          m['para']! as int,
          m['text']! as String,
          m['offset']! as int,
          strings(m['before']),
          strings(m['after']),
          (m['x'] as num?)?.toDouble() ?? 0.5,
        ),
        'blank' => ReaderBlank(
          m['x'] is num ? (m['x']! as num).toDouble() : 0.5,
          m['w'] is num ? (m['w']! as num).toDouble() : 0,
          m['y'] is num ? (m['y']! as num).toDouble() : 0.5,
          m['h'] is num ? (m['h']! as num).toDouble() : 0,
        ),
        'pos' => ReaderPos(
          m['offset']! as int,
          m['page']! as int,
          m['pages']! as int,
          m['ch'] as int?,
        ),
        'image' => ReaderImage(m['src']! as String),
        'imageHold' => ReaderImage(m['src']! as String, held: true),
        'edge' => switch (m['dir']) {
          'next' => const ReaderEdge(true),
          'prev' => const ReaderEdge(false),
          _ => null,
        },
        _ => null,
      };
    } on Object {
      return null;
    }
  }
}

class ReaderTap extends ReaderEvent {
  const ReaderTap(
    this.para,
    this.text,
    this.offset,
    this.before,
    this.after, [
    this.x = 0.5,
  ]);
  final int para;
  final String text;
  final int offset;
  final List<String> before;
  final List<String> after;
  final double x;
}

/// Blank space was tapped (margins, between lines), at ([x], [y]) (0..1
/// across and down the page, 0.5 when unknown) on a page [width] × [height]
/// dp (0 when unknown).
class ReaderBlank extends ReaderEvent {
  const ReaderBlank([
    this.x = 0.5,
    this.width = 0,
    this.y = 0.5,
    this.height = 0,
  ]);
  final double x;
  final double width;
  final double y;
  final double height;
}

/// The page shown now: [offset] is the chapter character position of its
/// first character; [page] is 0-based out of the chapter's [pages].
/// [chapter]: which chapter that is, when the page holds the whole book
/// (scroll mode); null when it holds one chapter.
class ReaderPos extends ReaderEvent {
  const ReaderPos(this.offset, this.page, this.pages, [this.chapter]);
  final int offset;
  final int page;
  final int pages;
  final int? chapter;
}

/// Paged past the end ([forward]) or the start of the chapter.
/// A picture was tapped, or [held] (still, finger down: drag it out): [src]
/// is its URL (a file:// one for book pictures).
class ReaderImage extends ReaderEvent {
  const ReaderImage(this.src, {this.held = false});
  final String src;
  final bool held;
}

class ReaderEdge extends ReaderEvent {
  const ReaderEdge(this.forward);
  final bool forward;
}
