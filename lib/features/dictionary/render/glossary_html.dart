import 'dart:convert';

/// Converts Yomitan glossary JSON to sanitized HTML. Every tag, attribute and
/// style property is whitelisted and all text is escaped, so dictionary data
/// can't inject script or markup.
///
/// Mirrors Yomitan's structured-content generator: elements get
/// `class="gloss-sc-<tag>"` and `data` keys become `data-sc-<key>` so
/// dictionaries' styles.css selectors keep working.
class GlossaryRenderer {
  /// [mediaUrl] maps an image `path` inside the dictionary zip to a URL; null skips the image.
  GlossaryRenderer({this.mediaUrl});
  final String? Function(String path)? mediaUrl;

  /// Renders a term's `glossary` column (raw JSON array) as `<ul>` of items.
  String glossaryList(String glossaryJson) {
    final items = jsonDecode(glossaryJson);
    if (items is! List) return '';
    final b = StringBuffer('<ul class="glossary-list">');
    for (final item in items) {
      b.write('<li class="glossary-item">');
      _item(item, b);
      b.write('</li>');
    }
    b.write('</ul>');
    return b.toString();
  }

  void _item(Object? item, StringBuffer b) {
    switch (item) {
      case String s:
        b.write(_text(s));
      case {'type': 'text', 'text': final String t}:
        b.write(_text(t));
      case {'type': 'structured-content', 'content': final c}:
        b.write('<div class="gloss-sc">');
        _node(c, b);
        b.write('</div>');
      case {'type': 'image'}:
        _image(item as Map, b);
      case [final String uninflected, List _]:
        b.write(
          '<span class="gloss-deinflection">→ ${escape(uninflected)}</span>',
        );
      default:
        break;
    }
  }

  static const _tags = {
    'span',
    'div',
    'ol',
    'ul',
    'li',
    'ruby',
    'rt',
    'rp',
    'table',
    'thead',
    'tbody',
    'tfoot', //
    'tr', 'th', 'td', 'details', 'summary', 'br', 'a', 'img',
  };

  void _node(Object? n, StringBuffer b) {
    switch (n) {
      case String s:
        b.write(_text(s));
      case List l:
        for (final c in l) {
          _node(c, b);
        }
      case Map m:
        var tag = m['tag'];
        if (tag is! String || !_tags.contains(tag)) tag = 'span';
        if (tag == 'img') return _image(m, b);
        if (tag == 'br') return b.write('<br>');
        b.write('<$tag class="gloss-sc-$tag"');
        _attrs(m, tag, b);
        b.write('>');
        _node(m['content'], b);
        b.write('</$tag>');
      default:
        break;
    }
  }

  void _attrs(Map m, String tag, StringBuffer b) {
    final data = m['data'];
    if (data is Map) {
      data.forEach((k, v) {
        if (k is String &&
            RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(k) &&
            (v is String || v is num)) {
          b.write(' data-sc-${_kebab(k)}="${escape('$v')}"');
        }
      });
    }
    for (final a in const ['lang', 'title']) {
      if (m[a] is String) b.write(' $a="${escape(m[a] as String)}"');
    }
    if ((tag == 'td' || tag == 'th')) {
      for (final a in const ['colSpan', 'rowSpan']) {
        if (m[a] is int) b.write(' ${a.toLowerCase()}="${m[a]}"');
      }
    }
    if (tag == 'details' && m['open'] == true) b.write(' open');
    if (tag == 'a' && m['href'] is String) {
      final href = m['href'] as String;
      // Internal Yomitan links start with '?' (e.g. ?query=…); only allow those and http(s).
      if (href.startsWith('?') ||
          href.startsWith('https://') ||
          href.startsWith('http://')) {
        b.write(' href="${escape(href)}"');
      }
    }
    final style = m['style'];
    if (style is Map) {
      final css = styleToCss(style);
      if (css.isNotEmpty) b.write(' style="${escape(css)}"');
    }
  }

  void _image(Map m, StringBuffer b) {
    final path = m['path'];
    final src = path is String ? mediaUrl?.call(path) : null;
    if (src == null) return;
    final units = m['sizeUnits'] == 'em' ? 'em' : 'px';
    final style = [
      if (m['width'] is num) 'width:${m['width']}$units',
      if (m['height'] is num) 'height:${m['height']}$units',
      if (m['verticalAlign'] is String &&
          _safeValue(m['verticalAlign'] as String))
        'vertical-align:${m['verticalAlign']}',
    ].join(';');
    b.write('<img class="gloss-image" src="${escape(src)}"');
    for (final a in const ['alt', 'title']) {
      if (m[a] is String) b.write(' $a="${escape(m[a] as String)}"');
    }
    if (style.isNotEmpty) b.write(' style="$style"');
    b.write('>');
  }

  static const _styleProps = {
    'fontStyle',
    'fontWeight',
    'fontSize',
    'color',
    'background',
    'backgroundColor', //
    'textDecorationLine',
    'textDecorationStyle',
    'textDecorationColor',
    'borderColor',
    'borderStyle',
    'borderRadius',
    'borderWidth',
    'clipPath',
    'verticalAlign',
    'textAlign',
    'textEmphasis',
    'textShadow',
    'margin',
    'marginTop',
    'marginLeft',
    'marginRight',
    'marginBottom',
    'padding',
    'paddingTop',
    'paddingLeft',
    'paddingRight',
    'paddingBottom',
    'wordBreak',
    'whiteSpace',
    'cursor', 'listStyleType',
  };

  /// Yomitan structured-content style object → inline CSS (whitelisted).
  static String styleToCss(Map style) {
    final out = <String>[];
    style.forEach((k, v) {
      if (k is! String || !_styleProps.contains(k)) return;
      final value = switch (v) {
        num n when k.startsWith('margin') || k.startsWith('padding') =>
          '${n}em',
        num n => '$n',
        String s => s,
        List l => l.whereType<String>().join(' '),
        _ => null,
      };
      if (value != null && _safeValue(value)) out.add('${_kebab(k)}:$value');
    });
    return out.join(';');
  }

  static bool _safeValue(String v) => !RegExp(
    r'[;{}<>\\"]|url\s*\(|expression',
    caseSensitive: false,
  ).hasMatch(v);

  static String _kebab(String s) =>
      s.replaceAllMapped(RegExp('[A-Z]'), (m) => '-${m[0]!.toLowerCase()}');

  static String _text(String s) => escape(s).replaceAll('\n', '<br>');
}

String escape(String s) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(s);
