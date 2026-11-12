import 'package:flutter/services.dart';

class AnkiDeck {
  const AnkiDeck(this.id, this.name);
  final int id;
  final String name;
}

class AnkiModel {
  const AnkiModel(this.id, this.name, this.fields);
  final int id;
  final String name;
  final List<String> fields;
}

class AnkiStatus {
  const AnkiStatus({required this.installed, required this.permission});
  final bool installed;
  final bool permission;
}

/// Failure from AnkiDroid, with a message fit to show the user.
class AnkiException implements Exception {
  AnkiException(this.message, {this.isPermission = false});
  final String message;
  final bool isPermission;
  @override
  String toString() => message;
}

/// Platform seam for the flashcard app. Android: AnkiDroid (AnkiBridge.kt).
abstract interface class AnkiBridge {
  Future<AnkiStatus> status();
  Future<bool> requestPermission();
  Future<List<AnkiDeck>> decks();
  Future<List<AnkiModel>> models();

  /// Number of notes matching an Anki browser search (duplicate check).
  Future<int> countNotes(String search);

  /// Deck names holding the cards of notes matching an Anki search (empty: none).
  Future<List<String>> noteDecks(String search);

  /// Copies a file into Anki's media; returns the field markup (`<img …>` / `[sound:…]`).
  Future<String> addMedia(
    String path, {
    required String name,
    required bool isAudio,
  });
  Future<int> addNote({
    required int modelId,
    required int deckId,
    required List<String> fields,
    List<String> tags,
  });

  /// A note type's look: CSS and card templates (read-only).
  Future<({String css, List<({String name, String front, String back})> cards})>
  modelDesign(int id);

  /// Creates a note type; returns its id.
  Future<int> addModel({
    required String name,
    required List<String> fields,
    required String css,
    required List<({String name, String front, String back})> cards,
  });
}

class MethodChannelAnkiBridge implements AnkiBridge {
  static const _ch = MethodChannel('kotohori/anki');

  Future<T> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return (await _ch.invokeMethod<T>(method, args)) as T;
    } on PlatformException catch (e) {
      throw AnkiException(
        e.message ?? 'AnkiDroid error',
        isPermission: e.code == 'permission',
      );
    } on MissingPluginException {
      throw AnkiException('Anki export is only available on Android');
    }
  }

  @override
  Future<AnkiStatus> status() async {
    try {
      final m = await _call<Map<Object?, Object?>>('status');
      return AnkiStatus(
        installed: m['installed'] == true,
        permission: m['permission'] == true,
      );
    } on AnkiException {
      return const AnkiStatus(installed: false, permission: false);
    }
  }

  @override
  Future<bool> requestPermission() async =>
      await _call<bool>('requestPermission');

  @override
  Future<List<AnkiDeck>> decks() async => [
    for (final d in await _call<List<Object?>>('decks'))
      if (d is Map) AnkiDeck((d['id'] as num).toInt(), d['name'] as String),
  ]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<List<AnkiModel>> models() async => [
    for (final m in await _call<List<Object?>>('models'))
      if (m is Map)
        AnkiModel(
          (m['id'] as num).toInt(),
          m['name'] as String,
          (m['fields'] as List).cast<String>(),
        ),
  ]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<int> countNotes(String search) async =>
      await _call<int>('countNotes', {'search': search});

  @override
  Future<List<String>> noteDecks(String search) async => [
    for (final d in await _call<List<Object?>>('noteDecks', {'search': search}))
      '$d',
  ];

  @override
  Future<String> addMedia(
    String path, {
    required String name,
    required bool isAudio,
  }) async => await _call<String>('addMedia', {
    'path': path,
    'name': name,
    'kind': isAudio ? 'audio' : 'image',
  });

  @override
  Future<int> addNote({
    required int modelId,
    required int deckId,
    required List<String> fields,
    List<String> tags = const [],
  }) async => (await _call<num>('addNote', {
    'modelId': modelId,
    'deckId': deckId,
    'fields': fields,
    'tags': tags,
  })).toInt();

  @override
  Future<({String css, List<({String name, String front, String back})> cards})>
  modelDesign(int id) async {
    final m = await _call<Map<Object?, Object?>>('modelDesign', {'id': id});
    return (
      css: m['css'] as String? ?? '',
      cards: [
        for (final c in m['cards'] as List)
          if (c is Map)
            (
              name: '${c['name']}',
              front: '${c['front']}',
              back: '${c['back']}',
            ),
      ],
    );
  }

  @override
  Future<int> addModel({
    required String name,
    required List<String> fields,
    required String css,
    required List<({String name, String front, String back})> cards,
  }) async => (await _call<num>('addModel', {
    'name': name,
    'fields': fields,
    'css': css,
    'cards': [
      for (final c in cards) {'name': c.name, 'front': c.front, 'back': c.back},
    ],
  })).toInt();
}
