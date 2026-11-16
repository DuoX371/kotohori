import 'dart:async';

import 'package:flutter/foundation.dart';

import 'explain_request.dart';
import 'gemini_client.dart';

/// Asks the AI service; the answer arrives in pieces. Fails with [ExplainException].
typedef ExplainFn = Stream<String> Function(ExplainRequest request);

enum ExplainStatus { waiting, writing, done, failed }

/// The Explain panel's state: which line, the answer so far, and how it's going.
/// Pure Dart so it is testable without a video player or a network.
class ExplainSession extends ChangeNotifier {
  ExplainSession(this._ask);
  final ExplainFn _ask;
  StreamSubscription<String>? _sub;

  /// Finished answers for this video, so asking again costs nothing.
  final _done = <String, String>{};

  /// Null while the panel is closed.
  ExplainRequest? request;
  String text = '';
  ExplainStatus status = ExplainStatus.done;
  ExplainException? error;

  bool get isOpen => request != null;

  /// Opens the panel on [r]. A finished answer for the same lines and model is
  /// shown again unless [fresh].
  void start(ExplainRequest r, {bool fresh = false}) {
    _sub?.cancel();
    _sub = null;
    request = r;
    error = null;
    final saved = fresh ? null : _done[r.cacheKey];
    if (saved != null) {
      text = saved;
      status = ExplainStatus.done;
      notifyListeners();
      return;
    }
    text = '';
    status = ExplainStatus.waiting;
    notifyListeners();
    _sub = _ask(r).listen(
      (piece) {
        text += piece;
        status = ExplainStatus.writing;
        notifyListeners();
      },
      onError: (Object e) {
        _sub = null;
        error = e is ExplainException
            ? e
            : ExplainException(ExplainError.other, '$e');
        status = ExplainStatus.failed;
        notifyListeners();
      },
      onDone: () {
        _sub = null;
        if (text.trim().isEmpty) {
          error = const ExplainException(
            ExplainError.other,
            'Gemini sent an empty answer.',
          );
          status = ExplainStatus.failed;
        } else {
          _done[r.cacheKey] = text;
          status = ExplainStatus.done;
        }
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  /// Asks again for the open line, ignoring the saved answer.
  void regenerate() {
    if (request case final r?) start(r, fresh: true);
  }

  /// Closes the panel and stops an answer still being written.
  void close() {
    if (!isOpen) return;
    _sub?.cancel();
    _sub = null;
    request = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
