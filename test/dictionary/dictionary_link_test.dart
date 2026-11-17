import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/render/dictionary_link.dart';

void main() {
  test('a link to another entry gives the word, however the URL is reported', () {
    for (final url in [
      '?query=倒す&wildcards=off',
      'https://kotohori.invalid/?query=%E5%80%92%E3%81%99&wildcards=off',
      'about:blank?query=%E5%80%92%E3%81%99&wildcards=off',
      'data:text/html;charset=utf-8,?wildcards=off&query=%E5%80%92%E3%81%99#x',
    ]) {
      expect(dictionaryLink(url), (query: '倒す', web: null), reason: url);
    }
    expect(dictionaryLink('?query=to+fall').query, 'to fall');
  });

  test('web links must be http(s); anything else is not followed', () {
    expect(
      dictionaryLink('https://www.edrdg.org/jmdict/j_jmdict.html').web,
      Uri.parse('https://www.edrdg.org/jmdict/j_jmdict.html'),
    );
    const nothing = (query: null, web: null);
    expect(dictionaryLink('intent://evil#Intent;end'), nothing);
    expect(dictionaryLink('file:///data/secret'), nothing);
    expect(dictionaryLink('?query='), nothing);
    expect(dictionaryLink('?query=%E5%80'), nothing); // badly escaped
  });

  test('our own page is told apart from a tapped link', () {
    expect(isOwnPage('about:blank'), isTrue);
    expect(isOwnPage(dictionaryPageBase), isTrue);
    // What the WebView reports for a relative link on a page with no address.
    expect(dictionaryLink('about:blank#blocked'), (query: null, web: null));
    expect(isOwnPage('data:text/html;base64,AAAA'), isTrue);
    expect(isOwnPage('about:blank?query=x'), isFalse);
  });
}
