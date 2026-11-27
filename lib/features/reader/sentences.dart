const _enders = {'。', '！', '？', '!', '?'};
const _closers = {'」', '』', '）', ')'};

/// [text] cut into sentences: after 。！？!? plus any closing brackets right
/// after them. Each is (start, end) in [text].
List<(int, int)> _spans(String text) {
  final out = <(int, int)>[];
  var start = 0, i = 0;
  while (i < text.length) {
    if (_enders.contains(text[i])) {
      var end = i + 1;
      while (end < text.length && _closers.contains(text[end])) {
        end++;
      }
      out.add((start, end));
      start = i = end;
    } else {
      i++;
    }
  }
  if (start < text.length) out.add((start, text.length));
  return out;
}

bool _blank(String s) => s.trim().isEmpty;

/// The non-blank sentences of [p], trimmed.
List<String> _split(String p) => [
  for (final (s, e) in _spans(p))
    if (!_blank(p.substring(s, e))) p.substring(s, e).trim(),
];

/// The sentence of [paragraph] that holds [offset], without leading spaces;
/// [start] is where it begins in [paragraph].
({String text, int start}) sentenceAt(String paragraph, int offset) {
  for (final (s, e) in _spans(paragraph)) {
    if (offset < e || e == paragraph.length) {
      final raw = paragraph.substring(s, e);
      final trimmed = raw.trimLeft();
      return (
        text: trimmed.trimRight(),
        start: s + raw.length - trimmed.length,
      );
    }
  }
  return (text: paragraph.trim(), start: 0);
}

/// The tapped sentence and up to [around] sentences each side of it, taken
/// across the neighbouring paragraphs; [target] is its index in [lines].
({List<String> lines, int target}) explainSentences({
  required List<String> before,
  required String paragraph,
  required int offset,
  required List<String> after,
  int around = 2,
}) {
  final prior = [for (final p in before) ..._split(p)];
  final tapped = sentenceAt(paragraph, offset);
  final own = _split(paragraph);
  final at = own.indexOf(tapped.text).clamp(0, own.length);
  final lead = [...prior, ...own.take(at)];
  final trail = [...own.skip(at + 1), for (final p in after) ..._split(p)];
  final head = lead.length > around ? lead.sublist(lead.length - around) : lead;
  return (
    lines: [...head, tapped.text, ...trail.take(around)],
    target: head.length,
  );
}

/// The whole [paragraph]'s sentences and up to [around] sentences each side;
/// the paragraph is [count] lines from [from] in [lines].
({List<String> lines, int from, int count}) explainParagraph({
  required List<String> before,
  required String paragraph,
  required List<String> after,
  int around = 2,
}) {
  final prior = [for (final p in before) ..._split(p)];
  final own = _split(paragraph);
  final trail = [for (final p in after) ..._split(p)];
  final head = prior.length > around
      ? prior.sublist(prior.length - around)
      : prior;
  return (
    lines: [...head, ...own, ...trail.take(around)],
    from: head.length,
    count: own.length,
  );
}
