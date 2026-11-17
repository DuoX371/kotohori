import 'package:flutter/foundation.dart';

import '../dictionary/lookup/lookup.dart';
import '../subtitles/cue.dart';

typedef LookupFn = Future<LookupResult> Function(String text, int index);

/// The lookup popup's state: which span of which cue is highlighted and the
/// result being shown. Pure Dart so it is testable without a video player.
class LookupSession extends ChangeNotifier {
  LookupSession(this._lookup);
  final LookupFn _lookup;
  int _request = 0;

  /// (cue index, start char, length) of the tapped character, then the matched word.
  (int, int, int)? highlight;

  /// Null while the popup is closed.
  LookupResult? result;

  /// Results left behind by following links inside the popup, oldest first.
  final _trail = <LookupResult>[];

  bool get followedLink => _trail.isNotEmpty;

  bool get isOpen => result != null;

  /// Shows [text] instead: a cross-reference tapped inside the popup ("→ 倒す").
  /// The highlight stays on the subtitle word that led here; [back] returns.
  Future<void> follow(String text) async {
    final from = result;
    if (from == null) return;
    final id = ++_request;
    final r = await _lookup(text, 0);
    if (id != _request) return; // superseded by a newer tap or by close()
    _trail.add(from);
    result = r;
    notifyListeners();
  }

  /// Returns to the entry a link was followed from. Does nothing otherwise.
  void back() {
    if (_trail.isEmpty) return;
    _request++;
    result = _trail.removeLast();
    notifyListeners();
  }

  Future<void> tap(Cue cue, int index) async {
    final id = ++_request;
    _trail.clear();
    highlight = (cue.index, index, 1);
    notifyListeners();
    final r = await _lookup(cue.text, index);
    if (id != _request) return; // superseded by a newer tap or by close()
    result = r;
    if (r.matchedLength > 0) highlight = (cue.index, index, r.matchedLength);
    notifyListeners();
  }

  void close() {
    _request++;
    result = null;
    highlight = null;
    _trail.clear();
    notifyListeners();
  }
}
