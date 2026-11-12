import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;

/// What a note-type field is filled with.
enum CardSource {
  none('Nothing'),
  sentence('Sentence (text)'),
  word('Word'),
  reading('Reading'),
  definition('Definition'),
  image('Screenshot'),
  wordAudio('Word audio'),
  audio('Sentence audio (clip)'), // name kept: stored in saved field maps
  source('Source (episode title)');

  const CardSource(this.label);
  final String label;
}

/// Settings → Anki. Stored as one JSON value.
class AnkiSettings {
  const AnkiSettings({
    this.deckId,
    this.modelId,
    this.fieldMap = const {},
    this.includeScreenshot = true,
    this.subtitleInScreenshot = true,
    this.fullSizeScreenshot = false,
    this.includeWordAudio = true,
    this.includeAudio = false,
    this.paddingBeforeMs = 250,
    this.paddingAfterMs = 250,
    this.firstDictionaryOnly = false,
  });

  final int? deckId;
  final int? modelId;

  /// Note-type field name → source.
  final Map<String, CardSource> fieldMap;
  final bool includeScreenshot;
  final bool subtitleInScreenshot;
  final bool fullSizeScreenshot;
  final bool includeWordAudio;
  final bool includeAudio;
  final int paddingBeforeMs;
  final int paddingAfterMs;
  final bool firstDictionaryOnly;

  bool get isConfigured =>
      deckId != null &&
      modelId != null &&
      fieldMap.values.any((s) => s != CardSource.none);

  AnkiSettings copyWith({
    int? deckId,
    int? modelId,
    Map<String, CardSource>? fieldMap,
    bool? includeScreenshot,
    bool? subtitleInScreenshot,
    bool? fullSizeScreenshot,
    bool? includeWordAudio,
    bool? includeAudio,
    int? paddingBeforeMs,
    int? paddingAfterMs,
    bool? firstDictionaryOnly,
  }) => AnkiSettings(
    deckId: deckId ?? this.deckId,
    modelId: modelId ?? this.modelId,
    fieldMap: fieldMap ?? this.fieldMap,
    includeScreenshot: includeScreenshot ?? this.includeScreenshot,
    subtitleInScreenshot: subtitleInScreenshot ?? this.subtitleInScreenshot,
    fullSizeScreenshot: fullSizeScreenshot ?? this.fullSizeScreenshot,
    includeWordAudio: includeWordAudio ?? this.includeWordAudio,
    includeAudio: includeAudio ?? this.includeAudio,
    paddingBeforeMs: paddingBeforeMs ?? this.paddingBeforeMs,
    paddingAfterMs: paddingAfterMs ?? this.paddingAfterMs,
    firstDictionaryOnly: firstDictionaryOnly ?? this.firstDictionaryOnly,
  );

  Map<String, Object?> toJson() => {
    'deckId': deckId,
    'modelId': modelId,
    'fieldMap': {for (final e in fieldMap.entries) e.key: e.value.name},
    'includeScreenshot': includeScreenshot,
    'subtitleInScreenshot': subtitleInScreenshot,
    'fullSizeScreenshot': fullSizeScreenshot,
    'includeWordAudio': includeWordAudio,
    'includeAudio': includeAudio,
    'paddingBeforeMs': paddingBeforeMs,
    'paddingAfterMs': paddingAfterMs,
    'firstDictionaryOnly': firstDictionaryOnly,
  };

  /// Unknown or malformed values fall back to defaults instead of throwing.
  factory AnkiSettings.fromJson(Object? json) {
    if (json is! Map) return const AnkiSettings();
    const d = AnkiSettings();
    final map = json['fieldMap'];
    T? opt<T>(String k) => json[k] is T ? json[k] as T : null;
    return AnkiSettings(
      deckId: opt<int>('deckId'),
      modelId: opt<int>('modelId'),
      fieldMap: {
        if (map is Map)
          for (final e in map.entries)
            if (e.key is String)
              e.key as String:
                  CardSource.values.asNameMap()[e.value] ?? CardSource.none,
      },
      includeScreenshot: opt<bool>('includeScreenshot') ?? d.includeScreenshot,
      subtitleInScreenshot:
          opt<bool>('subtitleInScreenshot') ?? d.subtitleInScreenshot,
      fullSizeScreenshot:
          opt<bool>('fullSizeScreenshot') ?? d.fullSizeScreenshot,
      includeWordAudio: opt<bool>('includeWordAudio') ?? d.includeWordAudio,
      includeAudio: opt<bool>('includeAudio') ?? d.includeAudio,
      paddingBeforeMs: opt<int>('paddingBeforeMs') ?? d.paddingBeforeMs,
      paddingAfterMs: opt<int>('paddingAfterMs') ?? d.paddingAfterMs,
      firstDictionaryOnly:
          opt<bool>('firstDictionaryOnly') ?? d.firstDictionaryOnly,
    );
  }
}

class AnkiSettingsNotifier extends Notifier<AnkiSettings> {
  static const _key = 'anki.settings';

  @override
  AnkiSettings build() {
    final raw = ref.watch(prefsProvider).getString(_key);
    if (raw == null) return const AnkiSettings();
    try {
      return AnkiSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return const AnkiSettings();
    }
  }

  Future<void> update(AnkiSettings Function(AnkiSettings) change) async {
    state = change(state);
    await ref.read(prefsProvider).setString(_key, jsonEncode(state.toJson()));
  }
}

final ankiSettingsProvider =
    NotifierProvider<AnkiSettingsNotifier, AnkiSettings>(
      AnkiSettingsNotifier.new,
    );
