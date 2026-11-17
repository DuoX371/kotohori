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

Launcher icons and the in-app icon (`assets/icons/app_icon_128.png`) are
generated from `assets/icons/foreground.png`, `monochrome.png` (Android 13+
themed icons) and `icon.png`, all 1024 px on a 108dp adaptive-icon canvas. The
background colour is in `android/app/src/main/res/values/ic_launcher_background.xml`.
`playstore.png` (512 px) and `icon-full.svg` are kept for store listings.

```
python tool/make_launcher_icons.py
```

## Release signing

Release builds are signed with the key named in `android/key.properties`
(git-ignored; never commit it or the key file):

```
storePassword=...
keyPassword=...
keyAlias=kotohori
storeFile=C:/path/to/kotohori-release.jks
```

Without that file, release builds fall back to the debug key (fine for
testing, but they can't update an installed release). Back up the key and its
password: without them, no update can install over an existing install.

## Releasing

Needs the [GitHub CLI](https://cli.github.com) (`winget install --id GitHub.cli`,
then `gh auth login` once). Run everything in PowerShell from the project folder.

Each release goes in its own folder, `releases\v<version>\` (git-ignored, and
outside `build\` so `flutter clean` can't delete it). Start by setting the
version, and set it again if you open a new terminal partway:

```powershell
$v = "0.1.2"            # the new version
$out = "releases\v$v"
```

1. **Version:** in `pubspec.yaml`, set `version: <$v>+<build>`, e.g. `0.1.2+3`.
   The build number after `+` must go up every release, or phones refuse the
   update.
2. **Check:** `flutter analyze` and `flutter test`.
3. **Build:** `flutter build apk --release --split-per-abi`
4. **Name the APKs:**
   ```powershell
   New-Item -ItemType Directory -Force $out | Out-Null
   Copy-Item build\app\outputs\flutter-apk\app-arm64-v8a-release.apk   "$out\kotohori-v$v-arm64.apk"
   Copy-Item build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk "$out\kotohori-v$v-armv7.apk"
   Copy-Item build\app\outputs\flutter-apk\app-x86_64-release.apk      "$out\kotohori-v$v-x86_64.apk"
   ```
5. **Changelog and release notes:**
   - In `docs/CHANGELOG.md`, rename **Unreleased** to `[$v] - <date>`, add a fresh
     empty **Unreleased** above it, and update the compare links at the bottom.
     `git log v<previous>..HEAD --oneline` lists what changed.
   - Make the notes from the template (fills in the version):
     ```powershell
     # -Encoding UTF8: without it Windows PowerShell garbles emoji (📥 → ðŸ“¥)
     (Get-Content docs\release-notes-template.md -Raw -Encoding UTF8).Replace('VERSION', $v) |
       Set-Content -Encoding utf8 "$out\release-notes.md"
     ```
     Then paste this version's changelog section under "What's changed" and
     delete the comments at the top.
6. **Commit and push:** `git add -A`, `git commit -m "Release $v"`, `git push`
7. **Tag:** the tag is `v` + the version; the app's update check compares them.
   ```powershell
   git tag -a "v$v" -m "Kotohori $v"
   git push origin "v$v"
   ```
8. **Publish:**
   ```powershell
   gh release create "v$v" (Get-ChildItem "$out\*.apk").FullName `
     --title "Kotohori $v" --notes-file "$out\release-notes.md"
   ```
   Add `--draft` to check it first, then `gh release edit "v$v" --draft=false`.
   Don't use `--prerelease`: GitHub leaves those out of "latest", so the app's
   update check wouldn't see them.
9. **Check:** `gh release view "v$v" --web`

Fixing mistakes:

| Problem | Fix |
|---|---|
| Wrong APK | `gh release upload "v$v" <file> --clobber` |
| Wrong title or notes | `gh release edit "v$v" --title "..."` or `--notes-file ...` |
| Start over | `gh release delete "v$v" --cleanup-tag --yes`, then `git tag -d "v$v"` |
