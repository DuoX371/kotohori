import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/lookup/lookup.dart';
import 'package:kotohori/features/player/lookup_session.dart';
import 'package:kotohori/features/subtitles/cue.dart';

const cue = Cue(3, Duration.zero, Duration(seconds: 2), '日本語を勉強');

void main() {
  test(
    'tap highlights the character, then the matched word; close clears',
    () async {
      final s = LookupSession((text, i) async => LookupResult(const [], 3));
      final pending = s.tap(cue, 0);
      expect(s.highlight, (
        3,
        0,
        1,
      )); // immediate feedback before the lookup finishes
      expect(s.isOpen, isFalse);
      await pending;
      expect(s.highlight, (3, 0, 3));
      expect(s.isOpen, isTrue);
      s.close();
      expect(s.isOpen, isFalse);
      expect(s.highlight, isNull);
    },
  );

  test(
    'no match keeps the single-character highlight and shows the (empty) popup',
    () async {
      final s = LookupSession((text, i) async => LookupResult.empty);
      await s.tap(cue, 4);
      expect(s.highlight, (3, 4, 1));
      expect(s.isOpen, isTrue);
    },
  );

  test(
    'a slow earlier lookup cannot overwrite a newer tap or reopen after close',
    () async {
      final slow = Completer<LookupResult>();
      var calls = 0;
      final s = LookupSession(
        (text, i) => ++calls == 1
            ? slow.future
            : Future.value(LookupResult(const [], 2)),
      );
      final first = s.tap(cue, 0);
      await s.tap(cue, 4); // newer tap finishes first
      slow.complete(LookupResult(const [], 3));
      await first;
      expect(s.highlight, (3, 4, 2));

      final slow2 = Completer<LookupResult>();
      final s2 = LookupSession((text, i) => slow2.future);
      final pending = s2.tap(cue, 0);
      s2.close();
      slow2.complete(LookupResult(const [], 3));
      await pending;
      expect(s2.isOpen, isFalse);
    },
  );
}
