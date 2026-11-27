import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/sentences.dart';

void main() {
  const para = '「行くよ！」と彼は言った。そうだね。';

  test('the sentence around a tap, closing quotes kept with it', () {
    expect(sentenceAt(para, 3), (text: '「行くよ！」', start: 0));
    expect(sentenceAt(para, 7), (text: 'と彼は言った。', start: 6));
    expect(sentenceAt(para, 13), (text: 'そうだね。', start: 13));
  });

  test('leading spaces are not part of a sentence', () {
    expect(sentenceAt('　本だ。', 2), (text: '本だ。', start: 1));
  });

  test('a paragraph without an ending is one sentence', () {
    expect(sentenceAt('終わらない', 0), (text: '終わらない', start: 0));
  });

  test('Explain gets the tapped sentence with up to two each side', () {
    final r = explainSentences(
      before: ['一。二。'],
      paragraph: '三。四。',
      offset: 2,
      after: ['五。'],
    );
    expect(r.lines, ['二。', '三。', '四。', '五。']);
    expect(r.target, 2);
  });

  test('blank paragraphs around the tap are skipped', () {
    final r = explainSentences(
      before: ['  '],
      paragraph: '本。',
      offset: 0,
      after: const [],
    );
    expect(r.lines, ['本。']);
    expect(r.target, 0);
  });

  test('a paragraph Explain gets every sentence of it, with neighbours', () {
    final r = explainParagraph(
      before: ['一。二。三。'],
      paragraph: '四。五。',
      after: ['六。七。八。'],
    );
    expect(r.lines, ['二。', '三。', '四。', '五。', '六。', '七。']);
    expect((r.from, r.count), (2, 2));
  });
}
