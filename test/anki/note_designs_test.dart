import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/anki/card_builder.dart';
import 'package:kotohori/features/anki/note_designs.dart';

import 'card_exporter_test.dart' show FakeAnki;

void main() {
  test('creates a design once, then reuses it', () async {
    final anki = FakeAnki();
    expect(await cinemaDesign.ensure(anki), 99);
    expect(await cinemaDesign.ensure(anki), 99);
    expect(anki.created, hasLength(1));
    expect(anki.created.single.$1, 'Kotohori Cinema');
    expect(anki.created.single.$2, cinemaDesign.fields);
  });

  for (final d in noteDesigns) {
    test(
      '${d.name}: templates only use its own fields; guessing agrees with its field map',
      () {
        final used = RegExp(r'\{\{[#/^]?(?:\w+:)?(\w+)\}\}')
            .allMatches(d.front + d.back)
            .map((m) => m[1]!)
            .where((f) => f != 'FrontSide')
            .toSet();
        expect(d.fields, containsAll(used));
        expect(guessFieldMap(d.fields), d.fieldMap);
      },
    );
  }

  test('Classic is the Japanese vocab note type plus sentence audio under the sentence', () {
    expect(classicDesign.fields, [
      'Word',
      'Furigana',
      'meaning',
      'audio',
      'pitch',
      'image',
      'sentence',
      'SentenceAudio',
    ]);
    expect(
      classicDesign.back.indexOf('{{SentenceAudio}}'),
      greaterThan(classicDesign.back.indexOf('{{sentence}}')),
    );
  });

  test('renderCardTemplate handles fields, sections, FrontSide, furigana and sound tags', () {
    final html = renderCardTemplate(
      '{{FrontSide}}|{{furigana:Word}}|{{#Picture}}P{{/Picture}}{{^Picture}}none{{/Picture}}|{{Audio}}',
      {'Word': '東京', 'Picture': '', 'Audio': '[sound:a.mp3]'},
      frontSide: 'F',
    );
    expect(html, 'F|東京|none|<span class="kh-play">▶</span>');
  });
}
