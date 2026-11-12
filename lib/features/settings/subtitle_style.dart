import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;

/// What sits behind the subtitle text so it stays readable on any frame.
enum SubtitleBackdrop {
  outline('Outline'),
  box('Dark box'),
  shadow('Shadow only');

  const SubtitleBackdrop(this.label);
  final String label;
}

/// How the player draws subtitles. Saved as one JSON value.
class SubtitleStyle {
  const SubtitleStyle({
    this.size = 28,
    this.color = SubtitleStyle.white,
    this.bold = true,
    this.backdrop = SubtitleBackdrop.outline,
    this.boxOpacity = 0.5,
  });

  static const white = Color(0xFFFFFFFF), yellow = Color(0xFFFFE45C);
  static const minSize = 16.0, maxSize = 48.0;

  final double size;
  final Color color;
  final bool bold;
  final SubtitleBackdrop backdrop;

  /// 0–1, only used with [SubtitleBackdrop.box].
  final double boxOpacity;

  SubtitleStyle copyWith({
    double? size,
    Color? color,
    bool? bold,
    SubtitleBackdrop? backdrop,
    double? boxOpacity,
  }) => SubtitleStyle(
    size: size ?? this.size,
    color: color ?? this.color,
    bold: bold ?? this.bold,
    backdrop: backdrop ?? this.backdrop,
    boxOpacity: boxOpacity ?? this.boxOpacity,
  );

  Map<String, Object?> toJson() => {
    'size': size,
    'color': color.toARGB32(),
    'bold': bold,
    'backdrop': backdrop.name,
    'boxOpacity': boxOpacity,
  };

  /// Unknown or malformed values fall back to defaults.
  factory SubtitleStyle.fromJson(Object? j) {
    if (j is! Map) return const SubtitleStyle();
    const d = SubtitleStyle();
    double clamped(String k, double def, double lo, double hi) =>
        (j[k] is num ? (j[k] as num).toDouble() : def).clamp(lo, hi);
    return SubtitleStyle(
      size: clamped('size', d.size, minSize, maxSize),
      color: j['color'] is int ? Color(j['color'] as int) : d.color,
      bold: j['bold'] is bool ? j['bold'] as bool : d.bold,
      backdrop:
          SubtitleBackdrop.values.asNameMap()[j['backdrop']] ?? d.backdrop,
      boxOpacity: clamped('boxOpacity', d.boxOpacity, 0, 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubtitleStyle &&
      other.size == size &&
      other.color == color &&
      other.bold == bold &&
      other.backdrop == backdrop &&
      other.boxOpacity == boxOpacity;

  @override
  int get hashCode => Object.hash(size, color, bold, backdrop, boxOpacity);
}

class SubtitleStyleNotifier extends Notifier<SubtitleStyle> {
  static const _key = 'subtitles.style';

  @override
  SubtitleStyle build() {
    try {
      final raw = ref.watch(prefsProvider).getString(_key);
      return raw == null
          ? const SubtitleStyle()
          : SubtitleStyle.fromJson(jsonDecode(raw));
    } on FormatException {
      return const SubtitleStyle();
    }
  }

  Future<void> update(SubtitleStyle Function(SubtitleStyle) change) async {
    state = change(state);
    await ref.read(prefsProvider).setString(_key, jsonEncode(state.toJson()));
  }
}

final subtitleStyleProvider =
    NotifierProvider<SubtitleStyleNotifier, SubtitleStyle>(
      SubtitleStyleNotifier.new,
    );
