# Development notes

## Checks

```
flutter analyze
flutter test
```

Optional: benchmark a real dictionary (download `jitendex-yomitan.zip` first):

```
# PowerShell
$env:JITENDEX_ZIP="C:\path\to\jitendex-yomitan.zip"; flutter test test/dictionary/large_import_test.dart
```

## Emulator

The video picture stays black on the Android emulator (audio, subtitles and
controls work): its OpenGL can't create the context mpv needs
(`eglCreateContext … EGL_BAD_ATTRIBUTE` in logcat). Use a real device to see video.

## After changing the database schema

```
dart run build_runner build
```

## Regenerating the Japanese deinflection table

`lib/features/dictionary/deinflect/ja_transforms.dart` is generated from Yomitan's
`japanese-transforms.js` (needs Node). See `tool/gen_ja_transforms.mjs` for usage.

## App icon

Launcher icons are generated from `assets/icons/adaptive_master.png` (a 108dp
adaptive-icon canvas with guide lines, which the script removes):

```
python tool/make_launcher_icons.py
```
