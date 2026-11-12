import 'dart:convert';

import 'package:dio/dio.dart';

class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.homepage,
    required this.downloadUrl,
  });
  final String id;
  final String name;
  final String description;
  final String? homepage;
  final String downloadUrl;
}

class CatalogGroup {
  CatalogGroup(this.type, this.items);
  final String type; // term | kanji | frequency
  final List<CatalogItem> items;

  String get label => switch (type) {
    'term' => 'Term dictionaries',
    'kanji' => 'Kanji dictionaries',
    'frequency' => 'Frequency',
    _ => type,
  };
}

class Catalog {
  Catalog(this.version, this.groups);
  final int version;
  final List<CatalogGroup> groups;

  factory Catalog.fromJson(Object? json) {
    if (json is! Map || json['groups'] is! List) {
      throw const FormatException('catalog: missing groups');
    }
    return Catalog(json['version'] as int? ?? 1, [
      for (final g in json['groups'] as List)
        CatalogGroup(g['type'] as String, [
          for (final i in g['items'] as List)
            CatalogItem(
              id: i['id'] as String,
              name: i['name'] as String,
              description: i['description'] as String? ?? '',
              homepage: i['homepage'] as String?,
              downloadUrl: i['downloadUrl'] as String,
            ),
        ]),
    ]);
  }
}

/// Fetches the catalog from [url]; on any failure falls back to the bundled copy.
Future<(Catalog, {bool fromFallback})> loadCatalog(
  Dio dio,
  String? url,
  Future<String> Function() bundled,
) async {
  if (url != null && url.isNotEmpty) {
    try {
      final r = await dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return (Catalog.fromJson(jsonDecode(r.data!)), fromFallback: false);
    } catch (_) {
      // fall through to bundled copy
    }
  }
  return (Catalog.fromJson(jsonDecode(await bundled())), fromFallback: true);
}
