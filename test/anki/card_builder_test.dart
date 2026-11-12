import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/anki/anki_settings.dart';
import 'package:kotohori/features/anki/card_builder.dart';

void main() {
  test('boldSentence bolds the matched span, escapes, keeps line breaks', () {
    expect(boldSentence('昨日は何も食べなかった', 5, 6), '昨日は何も<b>食べなかった</b>');
    expect(boldSentence('東京に<行き>\n本', 3, 1), '東京に<b>&lt;</b>行き&gt;<br>本');
    expect(boldSentence('abc', 1, 0), 'abc');
    expect(boldSentence('abc', 2, 10), 'ab<b>c</b>'); // clamped
  });

  test('clock', () {
    expect(clock(const Duration(minutes: 12, seconds: 34)), '12:34');
    expect(clock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  test('audioRange applies offset and padding, clamps at zero', () {
    const s = Duration(seconds: 5), e = Duration(seconds: 8);
    expect(audioRange(s, e, Duration.zero, 250, 250), (
      const Duration(milliseconds: 4750),
      const Duration(milliseconds: 8250),
    ));
    expect(audioRange(s, e, const Duration(seconds: -2), 0, 0), (
      const Duration(seconds: 3),
      const Duration(seconds: 6),
    ));
    expect(
      audioRange(Duration.zero, e, Duration.zero, 500, 0).$1,
      Duration.zero,
    );
  });

  test('guessFieldMap recognises common note-type field names', () {
    final m = guessFieldMap([
      'Expression',
      'Reading',
      'Meaning',
      'Sentence',
      'SentFurigana',
      'SentAudio',
      'WordAudio',
      'Picture',
      'Notes',
      'Source',
    ]);
    expect(m, {
      'Expression': CardSource.word,
      'Reading': CardSource.reading,
      'Meaning': CardSource.definition,
      'Sentence': CardSource.sentence,
      'SentFurigana': CardSource.none,
      'SentAudio': CardSource.audio,
      'WordAudio': CardSource.wordAudio,
      'Picture': CardSource.image,
      'Notes': CardSource.none,
      'Source': CardSource.source,
    });
    expect(guessFieldMap(['Front', 'Back']), {
      'Front': CardSource.word,
      'Back': CardSource.definition,
    });
    expect(guessFieldMap(['audio', 'SentenceAudio', '例文音声']), {
      'audio': CardSource.wordAudio,
      'SentenceAudio': CardSource.audio,
      '例文音声': CardSource.audio,
    });
  });

  test(
    'noteFields follows the model field order and leaves missing values empty',
    () {
      final fields = noteFields(
        ['Word', 'Audio', 'Extra', 'Sentence'],
        {
          'Word': CardSource.word,
          'Audio': CardSource.audio,
          'Sentence': CardSource.sentence,
        },
        {CardSource.word: '食べる', CardSource.sentence: '<b>食べ</b>た'},
      );
      expect(fields, ['食べる', '', '', '<b>食べ</b>た']);
    },
  );

  test('ankiSearchEscape', () {
    expect(ankiSearchEscape(r'a"b*c_d\e:f'), r'a\"b\*c\_d\\e\:f');
  });

  test('settings JSON round-trip and tolerant parsing', () {
    const s = AnkiSettings(
      deckId: 1,
      modelId: 2,
      fieldMap: {'Word': CardSource.word},
      includeAudio: true,
      paddingAfterMs: 400,
    );
    final back = AnkiSettings.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
    expect(back.isConfigured, isTrue);
    final junk = AnkiSettings.fromJson({
      'fieldMap': {'X': 'bogus'},
      'includeAudio': 'yes',
    });
    expect(junk.fieldMap['X'], CardSource.none);
    expect(junk.includeAudio, isFalse);
    expect(junk.includeScreenshot, isTrue);
    expect(junk.subtitleInScreenshot, isTrue);
    expect(junk.isConfigured, isFalse);
  });
}
