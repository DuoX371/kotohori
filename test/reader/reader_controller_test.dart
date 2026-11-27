import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/lookup/lookup.dart';
import 'package:kotohori/features/explain/explain_request.dart';
import 'package:kotohori/features/reader/reader_controller.dart';
import 'package:kotohori/features/reader/reader_event.dart';

const tap = ReaderTap(4, '一。猫だ。三。', 2, ['前の段落。'], ['次。']);

void main() {
  late List<(String, int)> asked;
  late ReaderController c;
  setUp(() {
    asked = [];
    c = ReaderController(
      lookup: (text, i) async {
        asked.add((text, i));
        return LookupResult(const [], 1);
      },
      explain: (_) => const Stream.empty(),
    );
  });
  tearDown(() => c.dispose());

  test('a tap looks up the paragraph from the tapped character', () async {
    await c.onTap(tap);
    expect(asked, [('一。猫だ。三。', 2)]);
    expect(c.lookup.highlight, (4, 2, 1));
    expect(c.lastTap, same(tap));
  });

  test('a tap closes an open explanation', () async {
    c.explain.start(
      const ExplainRequest(title: 't', lines: [], targets: [], model: 'm'),
    );
    expect(c.explain.isOpen, isTrue);
    await c.onTap(tap);
    expect(c.explain.isOpen, isFalse);
  });

  test('Explain asks about the tapped sentence with its neighbours', () async {
    expect(c.explainRequest(title: '本', model: 'm'), isNull);
    await c.onTap(tap);
    final r = c.explainRequest(title: '本', model: 'm')!;
    expect(r.source, ExplainSource.book);
    expect(r.title, '本');
    expect(r.lines.map((l) => l.text), ['前の段落。', '一。', '猫だ。', '三。', '次。']);
    expect(r.targets.map((l) => l.text), ['猫だ。']);
    expect(r.targetText, '猫だ。');
  });

  test('Explain can ask about the whole tapped paragraph', () async {
    await c.onTap(tap);
    final r = c.explainRequest(title: '本', model: 'm', paragraph: true)!;
    expect(r.paragraph, isTrue);
    expect(r.targets.map((l) => l.text), ['一。', '猫だ。', '三。']);
    expect(r.lines.map((l) => l.text), ['前の段落。', '一。', '猫だ。', '三。', '次。']);
  });

  test('a book answer is reused only for the same text', () async {
    await c.onTap(tap);
    final cat = c.explainRequest(title: '本', model: 'm')!;
    await c.onTap(const ReaderTap(5, '犬だ。', 0, ['一。', '二。'], []));
    final dog = c.explainRequest(title: '本', model: 'm')!;
    // Both sit at index 2 of their own request: the text tells them apart.
    expect(cat.targets.single.index, dog.targets.single.index);
    expect(cat.cacheKey, isNot(dog.cacheKey));
    await c.onTap(const ReaderTap(4, '一。猫だ。三。', 4, [], []));
    expect(c.explainRequest(title: '本', model: 'm')!.cacheKey, cat.cacheKey);
    final whole = c.explainRequest(title: '本', model: 'm', paragraph: true)!;
    expect(whole.cacheKey, isNot(cat.cacheKey));
  });
}
