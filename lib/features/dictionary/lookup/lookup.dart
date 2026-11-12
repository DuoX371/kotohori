import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/text_normalize.dart';
import '../data/db.dart';
import '../data/dictionary_repo.dart';
import '../deinflect/deinflector.dart';

class TermEntry {
  TermEntry(this.term, this.dict, this.reasons);
  final Term term;
  final Dictionary dict;

  /// Deinflection chain that produced this match (empty if uninflected).
  final List<String> reasons;
}

class MetaEntry {
  MetaEntry(this.dict, this.mode, this.data);
  final Dictionary dict;
  final String mode; // freq | pitch | ipa
  final Object? data; // decoded Yomitan meta payload
}

class TermGroup {
  TermGroup(this.expression, this.reading, this.matchedLength, this.entries);
  final String expression;
  final String reading;

  /// Source UTF-16 units matched, counted from the lookup index.
  int matchedLength;
  final List<TermEntry> entries;
  final frequencies = <MetaEntry>[];
  final pitches = <MetaEntry>[];

  /// Lowest numeric frequency rank across frequency dictionaries, if any.
  num? get bestFrequency {
    num? best;
    for (final f in frequencies) {
      final v = frequencyValue(f.data);
      if (v != null && (best == null || v < best)) best = v;
    }
    return best;
  }
}

class LookupResult {
  LookupResult(this.groups, this.matchedLength);
  final List<TermGroup> groups;
  final int matchedLength;
  static final empty = LookupResult(const [], 0);
}

const maxScanLength = 20;

/// Yomitan frequency payloads: number | string | {value, displayValue} | {reading, frequency}.
num? frequencyValue(Object? d) => switch (d) {
  num n => n,
  String s => num.tryParse(s.split(RegExp(r'[^0-9.]')).first),
  {'frequency': final f} => frequencyValue(f),
  {'value': final v} => frequencyValue(v),
  _ => null,
};

class Lookup {
  Lookup(this.repo, [Deinflector? deinflector])
    : _deinflector = deinflector ?? Deinflector.japanese();
  final DictionaryRepo repo;
  final Deinflector _deinflector;

  AppDb get _db => repo.db;

  Future<LookupResult> lookup(String text, int index) async {
    if (index < 0 || index >= text.length) return LookupResult.empty;
    var end = (index + maxScanLength).clamp(0, text.length);
    if (end < text.length && _isHighSurrogate(text.codeUnitAt(end - 1))) end--;
    final newline = text.indexOf(
      '\n',
      index,
    ); // a word never spans two subtitle lines
    if (newline >= 0 && newline < end) end = newline;
    final scan = text.substring(index, end);
    if (scan.trim().isEmpty) return LookupResult.empty;

    final dicts = await repo.enabled();
    if (dicts.isEmpty) return LookupResult.empty;
    final rank = {for (var i = 0; i < dicts.length; i++) dicts[i].id: i};
    final byId = {for (final d in dicts) d.id: d};

    // term → candidates that produced it
    final cands =
        <String, List<({int conditions, List<String> reasons, int srcLen})>>{};
    for (final v in lookupVariants(scan)) {
      for (var len = v.text.length; len > 0; len--) {
        if (_isHighSurrogate(v.text.codeUnitAt(len - 1))) continue;
        final srcLen = v.sourceLength(len);
        for (final d in _deinflector.deinflect(v.text.substring(0, len))) {
          (cands[d.term] ??= []).add((
            conditions: d.conditions,
            reasons: d.reasons,
            srcLen: srcLen,
          ));
        }
      }
    }

    final terms = cands.keys.toList();
    // dict_id is filtered in Dart: adding it to SQL makes SQLite pick the
    // terms_dict index and scan every row of the dictionary (~500 ms on Jitendex).
    final rows =
        (await (_db.select(_db.terms)..where(
                  (t) => t.expression.isIn(terms) | t.reading.isIn(terms),
                ))
                .get())
            .where((t) => byId.containsKey(t.dictId));

    // Keep, per term row, its best candidate: longest match, then fewest deinflection steps.
    final best = <int, (Term, int, List<String>)>{};
    for (final row in rows) {
      final flags = _deinflector.flagsForRules(row.rules);
      for (final key in {row.expression, row.reading}) {
        for (final c
            in cands[key] ??
                const <
                  ({int conditions, List<String> reasons, int srcLen})
                >[]) {
          if (!Deinflector.conditionsMatch(c.conditions, flags)) continue;
          final prev = best[row.id];
          if (prev == null ||
              c.srcLen > prev.$2 ||
              (c.srcLen == prev.$2 && c.reasons.length < prev.$3.length)) {
            best[row.id] = (row, c.srcLen, c.reasons);
          }
        }
      }
    }
    if (best.isEmpty) return LookupResult.empty;

    final groups = <(String, String), TermGroup>{};
    for (final (row, srcLen, reasons) in best.values) {
      final g = groups[(row.expression, row.reading)] ??= TermGroup(
        row.expression,
        row.reading,
        srcLen,
        [],
      );
      if (srcLen > g.matchedLength) g.matchedLength = srcLen;
      g.entries.add(TermEntry(row, byId[row.dictId]!, reasons));
    }
    final list = groups.values.toList();
    for (final g in list) {
      g.entries.sort((a, b) {
        final c = rank[a.dict.id]!.compareTo(rank[b.dict.id]!);
        return c != 0 ? c : b.term.score.compareTo(a.term.score);
      });
    }

    await _attachMeta(list, byId, rank);

    int bestRank(TermGroup g) => rank[g.entries.first.dict.id]!;
    int bestScore(TermGroup g) =>
        g.entries.map((e) => e.term.score).reduce((a, b) => a > b ? a : b);
    list.sort((a, b) {
      var c = b.matchedLength.compareTo(a.matchedLength);
      if (c != 0) return c;
      c = bestRank(a).compareTo(bestRank(b));
      if (c != 0) return c;
      final fa = a.bestFrequency, fb = b.bestFrequency;
      if (fa != null || fb != null) {
        if (fa == null) return 1;
        if (fb == null) return -1;
        c = fa.compareTo(fb);
        if (c != 0) return c;
      }
      return bestScore(b).compareTo(bestScore(a));
    });
    return LookupResult(list, list.first.matchedLength);
  }

  Future<void> _attachMeta(
    List<TermGroup> groups,
    Map<int, Dictionary> byId,
    Map<int, int> rank,
  ) async {
    final exprs = groups.map((g) => g.expression).toSet();
    final metas =
        (await (_db.select(
              _db.termMeta,
            )..where((m) => m.expression.isIn(exprs))).get())
            .where((m) => byId.containsKey(m.dictId))
            .toList();
    metas.sort((a, b) => rank[a.dictId]!.compareTo(rank[b.dictId]!));
    for (final m in metas) {
      final data = jsonDecode(m.data);
      // Reading-specific payloads ({reading, ...}) only apply to that reading.
      final reading = data is Map ? data['reading'] : null;
      for (final g in groups) {
        if (g.expression != m.expression ||
            (reading != null && reading != g.reading)) {
          continue;
        }
        final e = MetaEntry(byId[m.dictId]!, m.mode, data);
        if (m.mode == 'freq') g.frequencies.add(e);
        if (m.mode == 'pitch') g.pitches.add(e);
      }
    }
  }
}

bool _isHighSurrogate(int u) => u >= 0xd800 && u <= 0xdbff;
