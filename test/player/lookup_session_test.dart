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

  test('a link in the popup shows that word and keeps the highlight', () async {
    final asked = <String>[];
    final s = LookupSession((text, i) async {
      asked.add(text);
      return LookupResult(const [], text == '倒す' ? 2 : 3);
    });
    await s.follow('倒す'); // nothing open: ignored
    expect(asked, isEmpty);

    await s.tap(cue, 0);
    expect(s.followedLink, isFalse);
    await s.follow('倒す');
    expect(asked.last, '倒す');
    expect(s.result!.matchedLength, 2);
    expect(s.highlight, (3, 0, 3), reason: 'still the tapped subtitle word');
    expect(s.followedLink, isTrue);

    await s.tap(cue, 4); // a new subtitle word is an ordinary lookup again
    expect(s.followedLink, isFalse);
    s.close();
    expect(s.followedLink, isFalse);
  });

  test('back returns through followed links, one entry at a time', () async {
    final results = {
      for (final w in ['日本語を勉強', '倒す', '転ぶ']) w: LookupResult(const [], 1),
    };
    final s = LookupSession((text, i) async => results[text]!);
    await s.tap(cue, 0);
    s.back(); // nothing followed yet: ignored
    expect(s.result, same(results['日本語を勉強']));

    await s.follow('倒す');
    await s.follow('転ぶ');
    expect(s.result, same(results['転ぶ']));
    s.back();
    expect(s.result, same(results['倒す']));
    expect(s.followedLink, isTrue);
    s.back();
    expect(s.result, same(results['日本語を勉強']));
    expect(s.followedLink, isFalse);
    expect(s.highlight, (3, 0, 1));

    // A link still loading when Back is pressed does not come back later.
    final slow = Completer<LookupResult>();
    final s2 = LookupSession(
      (text, i) => text == 'slow' ? slow.future : Future.value(results['倒す']!),
    );
    await s2.tap(cue, 0);
    await s2.follow('倒す');
    final pending = s2.follow('slow');
    s2.back();
    slow.complete(LookupResult(const [], 9));
    await pending;
    expect(s2.result!.matchedLength, isNot(9));
    expect(s2.followedLink, isFalse);
  });

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
