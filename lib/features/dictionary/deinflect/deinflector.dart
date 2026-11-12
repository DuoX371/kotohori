// Port of Yomitan's LanguageTransformer (ext/js/language/language-transformer.js).
// Copyright (C) 2024-2026  Yomitan Authors. GPL-3.0-or-later.

import 'ja_transforms.dart';

class ConditionDef {
  const ConditionDef(this.isDictionaryForm, [this.subConditions]);
  final bool isDictionaryForm;
  final List<String>? subConditions;
}

class RuleDef {
  const RuleDef.suffix(
    this.inflected,
    this.deinflected,
    this.conditionsIn,
    this.conditionsOut,
  ) : isWholeWord = false;
  const RuleDef.whole(
    this.inflected,
    this.deinflected,
    this.conditionsIn,
    this.conditionsOut,
  ) : isWholeWord = true;
  final String inflected;
  final String deinflected;
  final List<String> conditionsIn;
  final List<String> conditionsOut;
  final bool isWholeWord;
}

class TransformDef {
  const TransformDef(this.id, this.name, this.rules);
  final String id;
  final String name;
  final List<RuleDef> rules;
}

/// A deinflection candidate. [conditions] == 0 means "uninflected, matches any entry".
class Deinflection {
  const Deinflection(this.term, this.conditions, this.reasons);
  final String term;
  final int conditions;

  /// Yomitan transform names, last-applied first (食べなかった → [negative, -た]).
  final List<String> reasons;
}

class _Rule {
  _Rule(this.def, this.condIn, this.condOut);
  final RuleDef def;
  final int condIn;
  final int condOut;
}

class Deinflector {
  Deinflector._(this._transforms, this._posFlags);

  factory Deinflector.japanese() =>
      _ja ??= Deinflector.fromDefs(jaConditions, jaTransforms);
  static Deinflector? _ja;

  factory Deinflector.fromDefs(
    Map<String, ConditionDef> conditions,
    List<TransformDef> transforms,
  ) {
    final flags = <String, int>{};
    var next = 0;
    var pending = conditions.entries.toList();
    while (pending.isNotEmpty) {
      final retry = <MapEntry<String, ConditionDef>>[];
      for (final e in pending) {
        final subs = e.value.subConditions;
        if (subs == null) {
          if (next >= 32) throw StateError('too many conditions');
          flags[e.key] = 1 << next++;
        } else if (subs.every(flags.containsKey)) {
          flags[e.key] = subs.fold(0, (a, s) => a | flags[s]!);
        } else {
          retry.add(e);
        }
      }
      if (retry.length == pending.length) {
        throw StateError('cycle in subConditions');
      }
      pending = retry;
    }
    int strict(List<String> names) => names.fold(0, (a, n) {
      final f = flags[n];
      if (f == null) throw StateError('unknown condition $n');
      return a | f;
    });
    final compiled = [
      for (final t in transforms)
        (
          t,
          [
            for (final r in t.rules)
              _Rule(r, strict(r.conditionsIn), strict(r.conditionsOut)),
          ],
        ),
    ];
    final pos = {
      for (final e in conditions.entries)
        if (e.value.isDictionaryForm) e.key: flags[e.key]!,
    };
    return Deinflector._(compiled, pos);
  }

  final List<(TransformDef, List<_Rule>)> _transforms;
  final Map<String, int> _posFlags;

  static bool conditionsMatch(int current, int next) =>
      current == 0 || (current & next) != 0;

  /// Flags for a dictionary entry's space-separated `ruleTypes` (e.g. "v1 vt").
  int flagsForRules(String ruleTypes) {
    var f = 0;
    for (final r in ruleTypes.split(' ')) {
      f |= _posFlags[r] ?? 0;
    }
    return f;
  }

  List<Deinflection> deinflect(String source) {
    final results = [_Traced(source, 0, const [])];
    for (var i = 0; i < results.length; i++) {
      final cur = results[i];
      for (final (t, rules) in _transforms) {
        for (var j = 0; j < rules.length; j++) {
          final rule = rules[j];
          if (!conditionsMatch(cur.conditions, rule.condIn)) continue;
          final d = rule.def;
          final hit = d.isWholeWord
              ? cur.text == d.inflected
              : cur.text.endsWith(d.inflected);
          if (!hit) continue;
          if (cur.trace.any(
            (f) => f.$1 == t && f.$2 == j && f.$3 == cur.text,
          )) {
            continue; // cycle
          }
          final out = d.isWholeWord
              ? d.deinflected
              : cur.text.substring(0, cur.text.length - d.inflected.length) +
                    d.deinflected;
          results.add(
            _Traced(out, rule.condOut, [(t, j, cur.text), ...cur.trace]),
          );
        }
      }
    }
    return [
      for (final r in results)
        Deinflection(r.text, r.conditions, [
          for (final f in r.trace) f.$1.name,
        ]),
    ];
  }
}

class _Traced {
  _Traced(this.text, this.conditions, this.trace);
  final String text;
  final int conditions;
  final List<(TransformDef, int, String)> trace;
}
