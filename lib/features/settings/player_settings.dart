import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;

/// Whether a video starts playing as soon as the player opens. On by default.
class Autoplay extends Notifier<bool> {
  static const _key = 'player.autoplay';

  @override
  bool build() => ref.watch(prefsProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    await ref.read(prefsProvider).setBool(_key, value);
    state = value;
  }
}

final autoplayProvider = NotifierProvider<Autoplay, bool>(Autoplay.new);

/// Whether tapping a word pauses the video (resumed when the popup closes). Off by default.
class PauseOnLookup extends Notifier<bool> {
  static const _key = 'player.pauseOnLookup';

  @override
  bool build() => ref.watch(prefsProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    await ref.read(prefsProvider).setBool(_key, value);
    state = value;
  }
}

final pauseOnLookupProvider = NotifierProvider<PauseOnLookup, bool>(
  PauseOnLookup.new,
);
