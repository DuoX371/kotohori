/// Scopes a dictionary's styles.css so every selector only matches inside
/// `[data-dictionary="<title>"]`, like Yomitan.
///
/// shortcut: handles plain rules plus @media/@supports blocks; other at-rules
/// (@import, @font-face, @keyframes, …) are dropped. Upgrade if a dictionary needs them.
String scopeCss(String css, String dictionaryTitle) {
  final scope =
      '[data-dictionary="${dictionaryTitle.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"]';
  // '<' never needs to be literal in CSS; escaping it stops `</style>` breakouts.
  final src = css
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll('<', r'\3C ');
  final out = StringBuffer();
  _scopeBlock(src, scope, out);
  return out.toString();
}

void _scopeBlock(String src, String scope, StringBuffer out) {
  var i = 0;
  while (i < src.length) {
    final open = src.indexOf('{', i);
    if (open < 0) break;
    final prelude = src.substring(i, open).trim();
    final close = _matchingBrace(src, open);
    final body = src.substring(open + 1, close);
    i = close + 1;
    if (prelude.startsWith('@media') || prelude.startsWith('@supports')) {
      out.write('$prelude{');
      _scopeBlock(body, scope, out);
      out.write('}');
    } else if (prelude.startsWith('@') || prelude.isEmpty) {
      continue;
    } else {
      final selectors = _splitTopLevel(prelude)
          .map((s) => '$scope ${s.trim()}')
          .join(',');
      out.write('$selectors{$body}\n');
    }
  }
}

int _matchingBrace(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '{') depth++;
    if (s[i] == '}' && --depth == 0) return i;
  }
  return s.length - 1 < open ? open : s.length - 1;
}

List<String> _splitTopLevel(String selectorList) {
  final parts = <String>[];
  var depth = 0, start = 0;
  for (var i = 0; i < selectorList.length; i++) {
    final c = selectorList[i];
    if (c == '(' || c == '[') depth++;
    if (c == ')' || c == ']') depth--;
    if (c == ',' && depth == 0) {
      parts.add(selectorList.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(selectorList.substring(start));
  return parts.where((p) => p.trim().isNotEmpty).toList();
}
