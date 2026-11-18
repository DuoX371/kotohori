import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// What the shelf and the reader need from an EPUB file.
class EpubBook {
  const EpubBook({
    required this.title,
    required this.author,
    required this.cover,
    required this.spine,
    required this.toc,
  });
  final String title;
  final String? author;
  final Uint8List? cover;

  /// The chapters in reading order.
  final List<EpubChapter> spine;
  final List<EpubTocEntry> toc;
}

class EpubChapter {
  const EpubChapter(this.href, this.length);

  /// Path inside the zip ("OEBPS/Text/ch1.xhtml"), decoded and normalised.
  final String href;

  /// Characters of [visibleText]: what reading positions count in.
  final int length;
}

class EpubTocEntry {
  const EpubTocEntry(this.title, this.chapter, [this.fragment]);
  final String title;

  /// Index into [EpubBook.spine].
  final int chapter;
  final String? fragment;
}

enum EpubError { drm, invalid }

class EpubException implements Exception {
  const EpubException(this.error);
  final EpubError error;

  @override
  String toString() => 'EpubException($error)';
}

/// Font obfuscation (IDPF, Adobe): fonts only, the text stays readable.
const _fontObfuscation = {
  'http://www.idpf.org/2008/embedding',
  'http://ns.adobe.com/pdf/enc#RC',
};

/// Reads [bytes] as an EPUB. Throws [EpubException].
EpubBook parseEpub(Uint8List bytes) {
  final Archive zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const EpubException(EpubError.invalid);
  }
  if (_isDrm(zip)) throw const EpubException(EpubError.drm);
  try {
    return _parse(zip);
  } on EpubException {
    rethrow;
  } on Object {
    throw const EpubException(EpubError.invalid);
  }
}

bool _isDrm(Archive zip) {
  final f = zip.find('META-INF/encryption.xml');
  if (f == null) return false;
  try {
    final doc = XmlDocument.parse(utf8.decode(f.content));
    final algorithms = doc.descendantElements
        .where((e) => e.localName == 'EncryptionMethod')
        .map((e) => e.getAttribute('Algorithm'));
    return algorithms.any((a) => !_fontObfuscation.contains(a));
  } on Object {
    return true; // unreadable encryption info: assume the worst
  }
}

XmlDocument _xml(Archive zip, String path) {
  final f = zip.find(path);
  if (f == null) throw const EpubException(EpubError.invalid);
  return XmlDocument.parse(
    utf8.decode(f.content, allowMalformed: true),
    entityMapping: const XmlDefaultEntityMapping.html5(),
  );
}

Iterable<XmlElement> _named(XmlNode n, String local) =>
    n.descendantElements.where((e) => e.localName == local);

/// [href] (relative to the file at [from]) as a zip path, and its fragment.
(String, String?) _resolve(String from, String href) {
  final hash = href.indexOf('#');
  final path = hash < 0 ? href : href.substring(0, hash);
  final fragment = hash < 0 ? null : href.substring(hash + 1);
  final joined = p.posix.normalize(
    p.posix.join(p.posix.dirname(from), Uri.decodeFull(path)),
  );
  return (joined.startsWith('./') ? joined.substring(2) : joined, fragment);
}

/// The package document (OPF): where it is and its contents.
(String, XmlDocument) _opf(Archive zip) {
  final container = _xml(zip, 'META-INF/container.xml');
  final path = _named(container, 'rootfile').first.getAttribute('full-path')!;
  return (path, _xml(zip, path));
}

String? _text(XmlDocument opf, String local) {
  final t = _named(opf, local).firstOrNull?.innerText.trim();
  return t == null || t.isEmpty ? null : t;
}

/// What the book details sheet shows. Only the package document is read, so
/// it's quick even for a big book.
class EpubDetails {
  const EpubDetails({
    required this.title,
    this.author,
    this.publisher,
    this.year,
    this.language,
    this.description,
    this.series,
    this.seriesIndex,
    this.illustrators = const [],
    this.translators = const [],
    this.subjects = const [],
    this.isbn,
  });
  final String title;
  final String? author, publisher, year, language, description;
  final String? series, seriesIndex, isbn;
  final List<String> illustrators, translators;

  /// Genres/tags the publisher gave (dc:subject).
  final List<String> subjects;
}

/// People credited on the book with their MARC role ("aut", "ill", "trl"…):
/// EPUB 2 puts it in an opf:role attribute, EPUB 3 in a refining <meta>.
List<({String name, String? role})> _people(XmlDocument opf) {
  final metas = _named(opf, 'meta').toList();
  return [
    for (final e in [..._named(opf, 'creator'), ..._named(opf, 'contributor')])
      if (e.innerText.trim() case final name when name.isNotEmpty)
        (
          name: name,
          role:
              e.attributes
                  .where((a) => a.name.local == 'role')
                  .firstOrNull
                  ?.value ??
              metas
                  .where(
                    (m) =>
                        m.getAttribute('property') == 'role' &&
                        m.getAttribute('refines') == '#${e.getAttribute('id')}',
                  )
                  .firstOrNull
                  ?.innerText
                  .trim(),
        ),
  ];
}

/// An ISBN among the book's identifiers ("urn:isbn:978…", "978-4-…").
String? _isbn(XmlDocument opf) {
  for (final id in _named(opf, 'identifier')) {
    final digits = id.innerText.replaceAll(RegExp('[^0-9Xx]'), '');
    final tagged =
        id.innerText.toLowerCase().contains('isbn') ||
        id.attributes.any((a) => a.value.toUpperCase() == 'ISBN');
    if (digits.length == 13 && RegExp('^97[89]').hasMatch(digits) ||
        tagged && (digits.length == 10 || digits.length == 13)) {
      return digits.toUpperCase();
    }
  }
  return null;
}

/// The book's details. Throws [EpubException] for an unreadable file.
EpubDetails epubDetails(Uint8List bytes) {
  try {
    final (opfPath, opf) = _opf(ZipDecoder().decodeBytes(bytes));
    String? meta(String name) => _named(opf, 'meta')
        .where((m) => m.getAttribute('name') == name)
        .firstOrNull
        ?.getAttribute('content');
    // EPUB 3: <meta property="belongs-to-collection" id="c">Name</meta> and
    // <meta refines="#c" property="group-position">8</meta>.
    final collection = _named(opf, 'meta')
        .where((m) => m.getAttribute('property') == 'belongs-to-collection')
        .firstOrNull;
    final position = collection == null
        ? null
        : _named(opf, 'meta')
              .where(
                (m) =>
                    m.getAttribute('refines') ==
                        '#${collection.getAttribute('id')}' &&
                    m.getAttribute('property') == 'group-position',
              )
              .firstOrNull
              ?.innerText;
    final index = (meta('calibre:series_index') ?? position)?.trim();
    final blurb = _text(opf, 'description')
        ?.replaceAll(RegExp(r'<[^>]*>'), '') // often HTML inside the text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final people = _people(opf);
    List<String> withRole(String role) => [
      for (final x in people)
        if (x.role == role) x.name,
    ];
    return EpubDetails(
      title: _text(opf, 'title') ?? p.basenameWithoutExtension(opfPath),
      // The first creator who is an author (or has no role given).
      author: people
          .where((x) => x.role == null || x.role == 'aut')
          .firstOrNull
          ?.name,
      illustrators: withRole('ill'),
      translators: withRole('trl'),
      subjects: [
        for (final e in _named(opf, 'subject'))
          if (e.innerText.trim() case final t when t.isNotEmpty) t,
      ],
      isbn: _isbn(opf),
      publisher: _text(opf, 'publisher'),
      year: RegExp(r'^\d{4}').stringMatch(_text(opf, 'date') ?? ''),
      language: _text(opf, 'language'),
      description: blurb == null || blurb.isEmpty ? null : blurb,
      series: meta('calibre:series') ?? collection?.innerText.trim(),
      seriesIndex: index?.replaceFirst(RegExp(r'\.0+$'), ''),
    );
  } on Object {
    throw const EpubException(EpubError.invalid);
  }
}

EpubBook _parse(Archive zip) {
  final (opfPath, opf) = _opf(zip);

  final manifest = {
    for (final item in _named(opf, 'item'))
      item.getAttribute('id'): (
        href: _resolve(opfPath, item.getAttribute('href')!).$1,
        properties: item.getAttribute('properties') ?? '',
      ),
  };
  String? text(String local) => _text(opf, local);

  final spine = <EpubChapter>[];
  for (final ref in _named(opf, 'itemref')) {
    final item = manifest[ref.getAttribute('idref')];
    final file = item == null ? null : zip.find(item.href);
    if (file == null) continue;
    final xhtml = utf8.decode(file.content, allowMalformed: true);
    spine.add(EpubChapter(item!.href, visibleText(xhtml).length));
  }
  if (spine.isEmpty) throw const EpubException(EpubError.invalid);

  final coverId = _named(opf, 'meta')
      .where((m) => m.getAttribute('name') == 'cover')
      .firstOrNull
      ?.getAttribute('content');
  final coverHref =
      manifest.values
          .where((i) => i.properties.split(' ').contains('cover-image'))
          .firstOrNull
          ?.href ??
      manifest[coverId]?.href;

  return EpubBook(
    title: text('title') ?? p.basenameWithoutExtension(opfPath),
    author: text('creator'),
    cover: coverHref == null ? null : zip.find(coverHref)?.content,
    spine: spine,
    toc: _toc(zip, manifest, spine),
  );
}

List<EpubTocEntry> _toc(
  Archive zip,
  Map<String?, ({String href, String properties})> manifest,
  List<EpubChapter> spine,
) {
  final index = {for (final (i, c) in spine.indexed) c.href: i};
  final entries = <EpubTocEntry>[];
  void add(String title, String from, String? href) {
    if (href == null) return;
    final (path, fragment) = _resolve(from, href);
    final chapter = index[path];
    if (chapter != null && title.trim().isNotEmpty) {
      entries.add(EpubTocEntry(title.trim(), chapter, fragment));
    }
  }

  try {
    final nav = manifest.values
        .where((i) => i.properties.split(' ').contains('nav'))
        .firstOrNull;
    if (nav != null) {
      final doc = _xml(zip, nav.href);
      final toc =
          _named(doc, 'nav')
              .where((n) => n.attributes.any((a) => a.value == 'toc'))
              .firstOrNull ??
          _named(doc, 'nav').firstOrNull;
      for (final a in toc == null ? const <XmlElement>[] : _named(toc, 'a')) {
        add(a.innerText, nav.href, a.getAttribute('href'));
      }
    }
    if (entries.isEmpty) {
      final ncx = manifest.values
          .where((i) => i.href.toLowerCase().endsWith('.ncx'))
          .firstOrNull;
      if (ncx != null) {
        for (final point in _named(_xml(zip, ncx.href), 'navPoint')) {
          final label = _named(point, 'text').firstOrNull?.innerText ?? '';
          final src = _named(point, 'content').firstOrNull?.getAttribute('src');
          add(label, ncx.href, src);
        }
      }
    }
  } on Object {
    entries.clear(); // a broken table of contents shouldn't stop the book
  }
  if (entries.isNotEmpty) return entries;
  return [
    for (var i = 0; i < spine.length; i++) EpubTocEntry('Section ${i + 1}', i),
  ];
}

const _hidden = {'rt', 'rp', 'script', 'style'};

/// The text a reader sees in a chapter: text under `<body>`, without furigana,
/// scripts or styles. Reading positions count characters of this; the page
/// script counts the same way.
String visibleText(String xhtml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(
      xhtml,
      entityMapping: const XmlDefaultEntityMapping.html5(),
    );
  } on Object {
    return '';
  }
  final body = _named(doc, 'body').firstOrNull;
  if (body == null) return '';
  final out = StringBuffer();
  void walk(XmlNode n) {
    for (final c in n.children) {
      if (c is XmlElement) {
        if (!_hidden.contains(c.localName.toLowerCase())) walk(c);
      } else if (c is XmlText) {
        out.write(c.value);
      }
    }
  }

  walk(body);
  return out.toString();
}
