import 'package:flutter/foundation.dart';

import '../explain/explain_request.dart';
import '../explain/explain_session.dart';
import '../player/lookup_session.dart';
import '../subtitles/cue.dart';
import 'reader_event.dart';
import 'sentences.dart';

/// The reader's mining state: the word popup and Explain, fed by taps on the
/// book page. Pure Dart so it is testable without a WebView.
class ReaderController extends ChangeNotifier {
  ReaderController({required LookupFn lookup, required ExplainFn explain})
    : lookup = LookupSession(lookup),
      explain = ExplainSession(explain);

  final LookupSession lookup;
  final ExplainSession explain;

  /// The last text tapped: what Add card and Explain work on.
  ReaderTap? lastTap;

  /// Looks up the tapped character; one popup at a time.
  Future<void> onTap(ReaderTap t) async {
    explain.close();
    lastTap = t;
    notifyListeners();
    await lookup.tapText(t.para, t.text, t.offset);
  }

  /// Explain for the sentence around the last tap (or its whole [paragraph]),
  /// with up to two sentences each side as context. Null before anything was
  /// tapped.
  ExplainRequest? explainRequest({
    required String title,
    required String model,
    bool paragraph = false,
  }) {
    final t = lastTap;
    if (t == null) return null;
    final List<String> texts;
    final int from, count;
    if (paragraph) {
      final s = explainParagraph(
        before: t.before,
        paragraph: t.text,
        after: t.after,
      );
      (texts, from, count) = (s.lines, s.from, s.count);
    } else {
      final s = explainSentences(
        before: t.before,
        paragraph: t.text,
        offset: t.offset,
        after: t.after,
      );
      (texts, from, count) = (s.lines, s.target, 1);
    }
    if (count == 0) return null;
    final lines = [
      for (final (i, text) in texts.indexed)
        Cue(i, Duration.zero, Duration.zero, text),
    ];
    return ExplainRequest(
      title: title,
      lines: lines,
      targets: lines.sublist(from, from + count),
      model: model,
      source: ExplainSource.book,
      paragraph: paragraph,
    );
  }

  @override
  void dispose() {
    lookup.dispose();
    explain.dispose();
    super.dispose();
  }
}
