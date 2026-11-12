import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/core/text_normalize.dart';
import 'package:kotohori/features/dictionary/deinflect/deinflector.dart';

void main() {
  test('half-width katakana → full-width, merging dakuten', () {
    final m = toFullWidth('ｶﾞｷﾞｸﾞﾊﾟｳﾞｱA1');
    expect(m.text, 'ガギグパヴアＡ１');
    expect(m.sourceLength(1), 2);
    expect(m.sourceLength(5), 10);
    expect(m.sourceLength(6), 11);
  });

  test('katakana → hiragana', () {
    expect(katakanaToHiragana('タベル・ヴァ'), 'たべる・ゔぁ');
  });

  test('lookupVariants are distinct', () {
    expect(lookupVariants('たべる').map((m) => m.text), ['たべる']);
    expect(lookupVariants('ﾀﾍﾞﾙ').map((m) => m.text), ['ﾀﾍﾞﾙ', 'タベル', 'たべる']);
  });

  group('Deinflector', () {
    final d = Deinflector.japanese();
    test('produces candidates with reasons', () {
      final c = d.deinflect('食べなかった').where((x) => x.term == '食べる').toList();
      expect(c, isNotEmpty);
      expect(c.first.reasons, ['negative', '-た']); // Yomitan transform names
      expect(c.first.conditions & d.flagsForRules('v1'), isNot(0));
    });

    test('uninflected text has conditions 0', () {
      expect(d.deinflect('日本').first.conditions, 0);
    });

    test('noun ruleTypes have no flags', () {
      expect(d.flagsForRules('n'), 0);
      expect(d.flagsForRules('v5 vt'), isNot(0));
    });
  });
}
