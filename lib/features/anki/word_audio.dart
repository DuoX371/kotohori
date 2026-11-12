import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// JapanesePod101 word audio, the same source and URL Yomitan uses by default.
Uri jpodAudioUrl(String word, String reading) => Uri.https(
  'assets.languagepod101.com',
  '/dictionary/japanese/audiomp3.php',
  {'kanji': word, 'kana': reading.isEmpty ? word : reading},
);

/// For words it has no recording of, JapanesePod101 answers 200 with a
/// "this audio clip is not available" MP3 (SHA-256 below, also checked by Yomitan).
const _jpodMissingSha256 =
    'ae6398b5a27bc8c0a771df6c907ade794be15518174773c58c7c7ddd17098906';

bool isJpodMissingClip(Uint8List bytes) =>
    sha256.convert(bytes).toString() == _jpodMissingSha256;
