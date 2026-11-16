# Changelog

All notable changes to Kotohori. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

While working, add lines under **Unreleased**. At release time, rename it to the
new version and date, and start a fresh **Unreleased** above it.

## [Unreleased]

## [0.1.5] - 2026-11-17

### Added

- Explain: a ✨ button in the player that pauses the video and explains the
  subtitle line on screen (translation, word-by-word breakdown, nuance) using
  Google's Gemini. Off by default; turn it on in Settings → AI explain with
  your own Gemini API key (free to create), and choose between faster and
  more accurate models.

## [0.1.4] - 2026-11-16

### Changed

- New app icon, with a themed version for Android 13+ themed icons

### Fixed

- "Playback error: Could not open codec" no longer stays on screen on some
  devices while the video plays fine

## [0.1.3] - 2026-11-15

### Added

- Copy scene button in the player: copies the frame on screen, with its
  subtitle, so you can paste it into a chat

### Changed

- The word popup in the player slides in and out instead of appearing and
  disappearing at once
- Pressing "Use this design" on the card design you already use no longer
  resets your field setup

### Fixed

- Subtitles sit on the picture instead of on the black bar under it when the
  video doesn't fill the screen
- Keyboard shortcuts such as Space work straight away after closing the word
  popup, instead of the first key press being lost
- The subtitle appearance preview shows the text at the size it will have
  next to the video, instead of looking bigger than in the player

## [0.1.2] - 2026-11-15

### Added

- Double-tap the left or right side of the video to skip 5 seconds back or
  forward; keep tapping to skip further

### Fixed

- Dictionary tags on cards no longer run together ("nounadverb") on Anki
  screens that drop the card's styling, such as AnkiDroid's card preview on
  some phones

## [0.1.1] - 2026-11-13

### Fixed

- Card editor shows the looked-up word in bold instead of raw `<b>` tags

## [0.1.0] - 2026-11-13

First beta.

### Added

- 🎬 **Player:** play your own videos with subtitle files or the subtitle tracks
  inside MKVs; automatic subtitle sync; keyboard shortcuts; pinch to fill the
  screen; a mini player when you press Home; resume where you left off
- 🔍 **Look up:** tap any subtitle word to look it up in Yomitan-format
  dictionaries; download Jitendex and others in the app
- 📇 **Mine:** one tap sends a card to AnkiDroid with the sentence, an audio
  clip, a screenshot and word audio; ready-made card designs
- 🔔 **Notifications:** the bell walks you through installing a dictionary and
  connecting AnkiDroid, and tells you when a new version is out

[Unreleased]: https://github.com/DuoX371/kotohori/compare/v0.1.5...HEAD
[0.1.5]: https://github.com/DuoX371/kotohori/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/DuoX371/kotohori/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/DuoX371/kotohori/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/DuoX371/kotohori/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/DuoX371/kotohori/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/DuoX371/kotohori/releases/tag/v0.1.0
