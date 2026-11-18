import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/book_view.dart';

// testWidgets runs on a fake clock: tester.pump(d) moves time forward by d.
void main() {
  test('covered from a chapter load until its first page is laid out', () {
    final c = PageCover();
    expect(c.value, isFalse);
    c.loading();
    expect(c.value, isTrue); // the raw chapter must not show
    c.laidOut();
    expect(c.value, isFalse);
    c.dispose();
  });

  testWidgets('never stuck: uncovers by itself if no page is reported', (
    t,
  ) async {
    final c = PageCover()..loading();
    await t.pump(const Duration(milliseconds: 1900));
    expect(c.value, isTrue);
    await t.pump(const Duration(milliseconds: 200));
    expect(c.value, isFalse);
    c.dispose();
  });

  testWidgets('an old limit does not cut a newer load short', (t) async {
    final c = PageCover()..loading();
    await t.pump(const Duration(milliseconds: 1500));
    c.loading(); // the next chapter
    await t.pump(const Duration(milliseconds: 1000));
    expect(c.value, isTrue, reason: 'the first timer must not uncover it');
    c.laidOut();
    expect(c.value, isFalse);
    c.dispose();
  });

  testWidgets('laid out: uncovers a moment later, once the WebView shows it', (
    t,
  ) async {
    final c = PageCover()..loading();
    c.laidOutSoon();
    expect(c.value, isTrue); // the WebView still shows its previous frame
    await t.pump(PageCover.settle);
    expect(c.value, isFalse);
    c.dispose();
  });

  testWidgets('a late uncover never uncovers the next chapter', (t) async {
    final c = PageCover()..loading();
    c.laidOutSoon();
    c.loading(); // another chapter before the first one was shown
    await t.pump(PageCover.settle);
    expect(c.value, isTrue);
    c.dispose();
  });
}
