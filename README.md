<p align="center">
  <img src="assets/icons/preview_rounded_square_128.png" width="128" alt="Kotohori icon">
</p>

<h1 align="center">Kotohori (言掘り)</h1>

<p align="center">
  A portable mining application for learning Japanese.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-beta-E2B85C" alt="Status: beta">
  <img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="License: GPL-3.0">
  <img src="https://img.shields.io/badge/platform-Android-3DDC84" alt="Platform: Android">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569B" alt="Built with Flutter">
</p>

## ⛏️ What is Kotohori?

Kotohori is built for one loop: **watch/read → tap → understand → mine**. As simple as that!

### 🎬 Player
- **Play your own videos with subtitles**, straight from local files
- **Subtitles out of sync?** Sync them automatically against the video's own subtitle track
- **Keyboard support**: play, pause, skip between subtitle lines and replay a line without touching the screen (shortcuts below)

### 📖 Reader
- 🚧 Currently work in progress

### 🔍 Look up
- **Yomitan-compatible**: use the same dictionaries as the Yomitan extension, with its grammar rules built in
- **Search up words** as simple as a click
- **One-tap dictionary downloads**: install, enable, reorder and update dictionaries from inside the app

### 📇 Mine
- **One tap sends a card to AnkiDroid**, with the sentence, an audio clip, a screenshot and word audio
- **Ready-made Anki Note Types**, set up in AnkiDroid for you
- **Edit before you send**: tweak any field first

## 🚧 Status

Kotohori is **in development and in beta testing**. The player, look up and
mining work day to day, but expect rough edges and things to change between
versions. Found a bug or have an idea? Open an
[issue](https://github.com/DuoX371/kotohori/issues).

Download the latest APK from [Releases](https://github.com/DuoX371/kotohori/releases)
(most phones: the `arm64` one). Kotohori tells you when a new version is out.

## 🎞️ Screenshots

## ⌨️ Keyboard shortcuts

In the player, with a hardware keyboard:

| Key | Action |
|---|---|
| Space | Play / pause |
| ← / → | Back / forward 5 seconds |
| ↑ or A | Previous subtitle line |
| ↓ or D | Next subtitle line |
| R | Replay the current line |
| S | Show / hide subtitles |
| Esc | Close the word popup |

## 📂 Supported formats

- **Video:** anything [mpv](https://mpv.io) plays (via
  [media_kit](https://github.com/media-kit/media-kit)), such as MKV, MP4 and WebM.
- **Subtitles:** `.srt`, `.ass` / `.ssa` and `.vtt` files, plus text subtitle
  tracks inside MKV files. Image-based subtitles (PGS, VobSub) aren't supported.
- **Dictionaries:** Yomitan format (`.zip`). Recommended dictionaries can be
  installed from inside the app; they're downloaded from their original sources.

## 🔒 Privacy

No account, no analytics, no tracking. Your videos, subtitles and cards stay on
your device. Kotohori only goes online to download dictionaries you choose (from
their original sites), to fetch word audio from JapanesePod101 when you make a
card, and to check GitHub for a newer version when it starts (you can turn this
off in Settings).

## 🙏 Credits

- **[Yomitan](https://yomitan.wiki/):** dictionary format and Japanese deinflection
  rules, ported from its [source](https://github.com/yomidevs/yomitan) (GPL-3.0)
- **Word audio:** JapanesePod101, the same source Yomitan uses
- **Video playback:** [media_kit](https://github.com/media-kit/media-kit) and [mpv](https://mpv.io)
- **Heading font:** Zen Kaku Gothic New (SIL Open Font License 1.1)
- **Anki Note Template:** Template reference from [Trenton](https://www.youtube.com/@%E3%83%88%E3%83%AC%E3%83%B3%E3%83%88%E3%83%B3) in this [video](https://youtu.be/_MWtbI4IwfU)

## 📜 License

Kotohori is licensed under the [GNU General Public License v3.0](LICENSE), because
it includes rules ported from Yomitan, which is GPL-3.0.

## 👋 Why I made this

What's up fellow Japanese learners? The mining grindset never stops! I love mining new Japanese words and learning them but mining has never been convenient especially on mobile devices. At home I'd use [asbplayer](https://docs.asbplayer.dev/) + Yomitan + Anki to do my mining but when I want to watch anime while commuting, it frustrates me that I don't get to mine new words. There was this project called [jidoujisho](https://github.com/arianneorpilla/jidoujisho) which was exactly what I needed but there were a few issues and the project was discontinued. I decided to make my own open-source version, with the help of AI-assisted coding. I'm really excited to see where it goes. Let's enjoy the mining journey together! ⛏️