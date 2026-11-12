/// Japanese text normalization for lookup.
library;

/// A converted string plus, for each prefix length `i+1`, how many source
/// UTF-16 units it consumed. Lets the UI highlight the right source span.
class Mapped {
  Mapped(this.text, this.srcEnd);
  final String text;
  final List<int> srcEnd;

  int sourceLength(int convertedLength) =>
      convertedLength == 0 ? 0 : srcEnd[convertedLength - 1];
}

// Half-width katakana U+FF61..U+FF9F → full-width.
const _hw = '｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ';
const _fw = '。「」、・ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜';
const _dakuten = 'ｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾊﾋﾌﾍﾎｳ';
const _dakutenOut = 'ガギグゲゴザジズゼゾダヂヅデドバビブベボヴ';
const _handakuten = 'ﾊﾋﾌﾍﾎ';
const _handakutenOut = 'パピプペポ';

/// Half-width katakana and ASCII → full-width, merging ﾞ/ﾟ into the preceding kana.
Mapped toFullWidth(String s) {
  final out = StringBuffer();
  final ends = <int>[];
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final next = i + 1 < s.length ? s[i + 1] : '';
    final u = c.codeUnitAt(0);
    var di = next == 'ﾞ' ? _dakuten.indexOf(c) : -1;
    var hi = next == 'ﾟ' ? _handakuten.indexOf(c) : -1;
    if (di >= 0) {
      out.write(_dakutenOut[di]);
      i++;
    } else if (hi >= 0) {
      out.write(_handakutenOut[hi]);
      i++;
    } else if (_hw.contains(c)) {
      out.write(_fw[_hw.indexOf(c)]);
    } else if (u >= 0x21 && u <= 0x7e) {
      out.writeCharCode(u + 0xfee0);
    } else {
      out.write(c);
    }
    ends.add(i + 1);
  }
  return Mapped(out.toString(), ends);
}

/// Katakana (ァ..ヶ) → hiragana. Length-preserving.
String katakanaToHiragana(String s) => String.fromCharCodes(
  s.codeUnits.map((u) => u >= 0x30a1 && u <= 0x30f6 ? u - 0x60 : u),
);

/// Distinct lookup variants of [s]: original, full-width, full-width hiragana.
List<Mapped> lookupVariants(String s) {
  final orig = Mapped(s, [for (var i = 1; i <= s.length; i++) i]);
  final fw = toFullWidth(s);
  final hira = Mapped(katakanaToHiragana(fw.text), fw.srcEnd);
  final seen = <String>{};
  return [
    for (final m in [orig, fw, hira])
      if (seen.add(m.text)) m,
  ];
}
