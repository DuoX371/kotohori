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

  /// Explain for the sentence around the last tap, with up to two sentences
  /// each side as context. Null before anything was tapped.
  ExplainRequest? explainRequest({
    required String title,
    required String model,
  }) {
    final t = lastTap;
    if (t == null) return null;
    final s = explainSentences(
      before: t.before,
      paragraph: t.text,
      offset: t.offset,
      after: t.after,
    );
    final lines = [
      for (final (i, text) in s.lines.indexed)
        Cue(i, Duration.zero, Duration.zero, text),
    ];
    return ExplainRequest(
      title: title,
      lines: lines,
      targets: [lines[s.target]],
      model: model,
      source: ExplainSource.book,
    );
  }

  @override
  void dispose() {
    lookup.dispose();
    explain.dispose();
    super.dispose();
  }
}
