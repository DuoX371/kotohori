import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/lookup/lookup.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  late Lookup lookup;

  setUp(() async {
    env = await TestEnv.create();
    await env.import('mini_a');
    await env.import('mini_b');
    lookup = Lookup(env.repo);
  });
  tearDown(() => env.dispose());

  Future<TermGroup> top(String text, [int index = 0]) async {
    final r = await lookup.lookup(text, index);
    expect(r.groups, isNotEmpty, reason: 'no result for $text');
    return r.groups.first;
  }

  group('deinflection through lookup', () {
    for (final (input, expected) in [
      ('食べなかった', '食べる'),
      ('行きました', '行く'),
      ('読んでいる', '読む'),
      ('高くない', '高い'),
      ('来なかった', '来る'),
    ]) {
      test('$input → $expected', () async {
        final g = await top(input);
        expect(g.expression, expected);
        expect(g.matchedLength, input.length);
        expect(g.entries.first.reasons, isNotEmpty);
      });
    }

    test('した → する', () async {
      final r = await lookup.lookup('した', 0);
      expect(r.groups.map((g) => g.reading), everyElement('する'));
      expect(r.groups.map((g) => g.expression), containsAll(['する', '為る']));
      expect(r.matchedLength, 2);
    });
  });

  test('katakana input matches a hiragana reading', () async {
    final g = await top('タベル');
    expect(g.expression, '食べる');
    expect(g.matchedLength, 3);
  });

  test('half-width katakana input maps back to source length', () async {
    final g = await top('ﾀﾍﾞﾙ'); // 4 source chars → たべる
    expect(g.expression, '食べる');
    expect(g.matchedLength, 4);
  });

  test('longest match wins: compound beats its first word', () async {
    final r = await lookup.lookup('日本語を話す', 0);
    expect(r.groups.first.expression, '日本語');
    expect(r.matchedLength, 3);
    expect(
      r.groups.map((g) => g.expression),
      contains('日本'),
    ); // shorter match still listed after
  });

  test('a match never crosses a line break', () async {
    final r = await lookup.lookup('日本\n語', 0);
    expect(r.groups.first.expression, '日本');
    expect(r.matchedLength, 2);
    expect(
      (await lookup.lookup('日本\n語', 2)).groups,
      isEmpty,
    ); // tapped the newline itself
  });

  test('scans from the tapped index', () async {
    final g = await top('私は日本語', 2);
    expect(g.expression, '日本語');
  });

  test('ruleTypes filter rejects an invalid deinflection', () async {
    // 書いた deinflects to 書く (v5), but the fixture's 書く has no verb ruleTypes.
    expect((await lookup.lookup('書いた', 0)).groups, isEmpty);
    // The uninflected form itself still matches (conditions 0 match anything).
    expect((await top('書く')).expression, '書く');
  });

  test('disabled dictionaries are excluded', () async {
    final dicts = await env.repo.installed();
    final a = dicts.firstWhere((d) => d.title == 'Mini A');
    await env.repo.setEnabled(a.id, false);
    final g = await top('日本');
    expect(g.entries.map((e) => e.dict.title), ['Mini B']);
  });

  test('priority order is respected and can be changed', () async {
    var g = await top('日本');
    expect(g.entries.map((e) => e.dict.title), ['Mini A', 'Mini B']);
    final b = (await env.repo.installed()).firstWhere(
      (d) => d.title == 'Mini B',
    );
    await env.repo.move(b.id, -1);
    g = await top('日本');
    expect(g.entries.map((e) => e.dict.title), ['Mini B', 'Mini A']);
  });

  test('frequency and pitch metadata attached', () async {
    final eat = await top('食べる');
    expect(eat.bestFrequency, 250);
    final nihon = await top('日本');
    expect(nihon.pitches, hasLength(1));
    expect(nihon.bestFrequency, 120);
  });

  test('no enabled dictionaries / no match / bad index → empty', () async {
    expect((await lookup.lookup('xyz', 0)).groups, isEmpty);
    expect((await lookup.lookup('日本', 5)).groups, isEmpty);
    await env.repo.setAllEnabled(false);
    expect((await lookup.lookup('日本', 0)).groups, isEmpty);
  });
}
