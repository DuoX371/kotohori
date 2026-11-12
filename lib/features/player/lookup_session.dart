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

  bool get isOpen => result != null;

  Future<void> tap(Cue cue, int index) async {
    final id = ++_request;
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
    notifyListeners();
  }
}
