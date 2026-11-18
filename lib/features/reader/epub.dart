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

EpubBook _parse(Archive zip) {
  final container = _xml(zip, 'META-INF/container.xml');
  final opfPath = _named(
    container,
    'rootfile',
  ).first.getAttribute('full-path')!;
  final opf = _xml(zip, opfPath);

  final manifest = {
    for (final item in _named(opf, 'item'))
      item.getAttribute('id'): (
        href: _resolve(opfPath, item.getAttribute('href')!).$1,
        properties: item.getAttribute('properties') ?? '',
      ),
  };
  String? text(String local) {
    final e = _named(opf, local).firstOrNull;
    final t = e?.innerText.trim();
    return t == null || t.isEmpty ? null : t;
  }

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
