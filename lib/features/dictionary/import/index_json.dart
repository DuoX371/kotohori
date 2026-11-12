import '../../../core/errors.dart';

/// Yomitan `index.json`.
class DictionaryIndex {
  DictionaryIndex({
    required this.title,
    required this.revision,
    required this.format,
    this.author,
    this.attribution,
    this.description,
    this.sourceLanguage,
    this.isUpdatable = false,
    this.indexUrl,
    this.downloadUrl,
  });

  factory DictionaryIndex.fromJson(Object? json) {
    if (json is! Map) {
      throw InvalidDictionaryException('index.json is not an object');
    }
    final title = json['title'];
    final revision = json['revision'];
    final format = json['format'] ?? json['version'];
    if (title is! String ||
        title.isEmpty ||
        revision is! String ||
        format is! int) {
      throw InvalidDictionaryException(
        'index.json missing title/revision/format',
      );
    }
    if (format != 3) {
      throw InvalidDictionaryException(
        'Unsupported dictionary format $format (need 3)',
      );
    }
    return DictionaryIndex(
      title: title,
      revision: revision,
      format: format,
      author: json['author'] as String?,
      attribution: json['attribution'] as String?,
      description: json['description'] as String?,
      sourceLanguage: json['sourceLanguage'] as String?,
      isUpdatable: json['isUpdatable'] == true,
      indexUrl: json['indexUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  final String title;
  final String revision;
  final int format;
  final String? author;
  final String? attribution;
  final String? description;
  final String? sourceLanguage;
  final bool isUpdatable;
  final String? indexUrl;
  final String? downloadUrl;
}

/// Compares revisions like "2025.03.04.0" segment by segment numerically;
/// falls back to string comparison for non-numeric segments.
int compareRevisions(String a, String b) {
  final pa = a.split(RegExp(r'[.\-_]'));
  final pb = b.split(RegExp(r'[.\-_]'));
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : '0';
    final y = i < pb.length ? pb[i] : '0';
    final nx = int.tryParse(x), ny = int.tryParse(y);
    final c = nx != null && ny != null ? nx.compareTo(ny) : x.compareTo(y);
    if (c != 0) return c;
  }
  return 0;
}
