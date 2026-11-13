import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;

/// Dark / light / match system. Dark by default (it's a video app).
class AppThemeMode extends Notifier<ThemeMode> {
  static const _key = 'app.themeMode';

  @override
  ThemeMode build() =>
      ThemeMode.values.asNameMap()[ref.watch(prefsProvider).getString(_key)] ??
      ThemeMode.dark;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(prefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(
  AppThemeMode.new,
);

/// Whether the app is showing its dark theme (for pages drawn outside Flutter).
bool appIsDark(WidgetRef ref) => switch (ref.read(themeModeProvider)) {
  ThemeMode.dark => true,
  ThemeMode.light => false,
  ThemeMode.system =>
    WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
};
