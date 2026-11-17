/// What a link tapped inside dictionary HTML asks for: a word to look up
/// ([query]), a web page to open ([web]), or nothing we follow (both null).
typedef DictionaryLink = ({String? query, Uri? web});

final _query = RegExp(r'[?&]query=([^&#]*)');

/// Reads the address the WebView is about to open. Dictionaries link to other
/// entries the way Yomitan does, `?query=倒す&wildcards=off`, which the
/// WebView resolves against [dictionaryPageBase]; only the `query` part is
/// read. Web links must be http(s).
DictionaryLink dictionaryLink(String url) {
  final m = _query.firstMatch(url);
  if (m != null) {
    final raw = m.group(1)!;
    String? text;
    try {
      text = Uri.decodeQueryComponent(raw);
    } on Object {
      // Not valid escaping. Plain Japanese (never escaped at all) is fine as
      // it is; a broken %-escape is not a link we can follow.
      text = raw.contains('%') ? null : raw.replaceAll('+', ' ');
    }
    text = text?.trim();
    return (query: text == null || text.isEmpty ? null : text, web: null);
  }
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.isScheme('https') || uri.isScheme('http'))) {
    return (query: null, web: uri);
  }
  return (query: null, web: null);
}

/// The address dictionary pages are loaded under. A page with no address
/// (about:blank) makes the WebView block the entries' relative links and
/// report only "about:blank#blocked", losing the word. The host never
/// resolves, and no link is ever actually opened inside the WebView.
const dictionaryPageBase = 'https://kotohori.invalid/';

/// Whether [url] is the page we loaded ourselves (never a tapped link).
bool isOwnPage(String url) =>
    url == dictionaryPageBase ||
    url == 'about:blank' ||
    url.startsWith('data:');
