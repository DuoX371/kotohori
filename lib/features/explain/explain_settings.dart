import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;
import 'gemini_client.dart';

/// Whether the ✨ Explain button shows in the player. Off by default: nothing is
/// sent anywhere until the user turns this on and presses the button. Can only
/// be on while the key has passed its test ([explainKeyTestedProvider]).
class ExplainEnabled extends Notifier<bool> {
  static const _key = 'explain.enabled';

  @override
  bool build() {
    final prefs = ref.watch(prefsProvider);
    return ref.watch(explainKeyTestedProvider) &&
        (prefs.getBool(_key) ?? false);
  }

  Future<void> set(bool value) async {
    final on = value && ref.read(explainKeyTestedProvider);
    await ref.read(prefsProvider).setBool(_key, on);
    state = on;
  }
}

/// Whether the saved API key passed "Test your key". The pass is remembered
/// for that exact key (as a hash): another key has not passed, and going back
/// to the one that did (say, after fixing a typo) needs no new test.
class ExplainKeyTested extends Notifier<bool> {
  static const _key = 'explain.testedKeyHash';

  static String _hash(String key) =>
      sha256.convert(utf8.encode(key)).toString();

  @override
  bool build() {
    final key = ref.watch(explainApiKeyProvider).value ?? '';
    return key.isNotEmpty &&
        ref.watch(prefsProvider).getString(_key) == _hash(key);
  }

  /// The test passed with [testedKey].
  Future<void> passed(String testedKey) async {
    await ref.read(prefsProvider).setString(_key, _hash(testedKey));
    ref.invalidateSelf();
  }
}

final explainKeyTestedProvider = NotifierProvider<ExplainKeyTested, bool>(
  ExplainKeyTested.new,
);

final explainEnabledProvider = NotifierProvider<ExplainEnabled, bool>(
  ExplainEnabled.new,
);

/// The chosen Gemini model's id (the default until one is picked, and again
/// if the saved one is no longer offered).
class ExplainModel extends Notifier<String> {
  static const _key = 'explain.geminiModel';

  @override
  String build() => geminiModelFor(ref.watch(prefsProvider).getString(_key)).id;

  Future<void> set(String id) async {
    await ref.read(prefsProvider).setString(_key, id);
    state = geminiModelFor(id).id;
  }
}

final explainModelProvider = NotifierProvider<ExplainModel, String>(
  ExplainModel.new,
);

/// Where the API key is kept. Overridden in tests.
abstract class KeyStore {
  Future<String> read();
  Future<void> write(String key);
}

class SecureKeyStore implements KeyStore {
  const SecureKeyStore();
  static const _name = 'explain.geminiKey';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String> read() async {
    try {
      return await _storage.read(key: _name) ?? '';
    } on Object {
      return ''; // unreadable (e.g. restored onto another device): ask again
    }
  }

  @override
  Future<void> write(String key) => key.isEmpty
      ? _storage.delete(key: _name)
      : _storage.write(key: _name, value: key);
}

final keyStoreProvider = Provider<KeyStore>((_) => const SecureKeyStore());

/// The user's Gemini API key (encrypted on the device, never in normal settings).
class ExplainApiKey extends AsyncNotifier<String> {
  @override
  Future<String> build() => ref.watch(keyStoreProvider).read();

  Future<void> set(String value) async {
    final key = value.trim();
    if (key == await future) return;
    await ref.read(keyStoreProvider).write(key);
    state = AsyncData(key);
  }
}

final explainApiKeyProvider = AsyncNotifierProvider<ExplainApiKey, String>(
  ExplainApiKey.new,
);

/// Why Explain can't run yet, or null when it's ready.
String? explainSetupProblem({required String apiKey}) => apiKey.trim().isEmpty
    ? 'Add your Gemini API key in settings to use Explain.'
    : null;

/// Own Dio: its timeouts must not apply to dictionary downloads.
final _explainDioProvider = Provider(
  (_) => Dio(BaseOptions(connectTimeout: const Duration(seconds: 15))),
);

/// A client for one model (by id), using the current key.
final geminiClientProvider = FutureProvider.family<GeminiClient, String>(
  (ref, model) async => GeminiClient(
    ref.watch(_explainDioProvider),
    apiKey: await ref.watch(explainApiKeyProvider.future),
    model: model,
  ),
);

/// What to tell the user about [e], in plain words.
String explainErrorMessage(ExplainException e) => switch (e.kind) {
  ExplainError.unreachable =>
    "Can't reach Gemini. Check your internet connection."
        "${e.detail == null ? '' : ' (${e.detail})'}",
  ExplainError.badKey => 'Your API key was not accepted. Check it in settings.',
  ExplainError.limit => "You've reached the free limit for this model. Try again in a minute, or choose another model in settings.",
  ExplainError.noModel =>
    'Google no longer offers this model. Choose another in settings.',
  ExplainError.busy =>
    "Gemini is busy right now and didn't answer. Try again in a moment.",
  ExplainError.other => e.detail ?? 'Something went wrong.',
};
