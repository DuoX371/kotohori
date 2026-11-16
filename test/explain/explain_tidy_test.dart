import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/explain/explain_tidy.dart';

void main() {
  test('drops lone basic particles and punctuation, keeps the rest', () {
    const answer = '''
## Translation
The other hero is quite plain, isn't he?

## Breakdown
- **もう一人** (もうひとり): one more person. Noun phrase.
- **の** (の): connects noun to noun. Particle.
- **ヒーロー** (ヒーロー): hero. Noun.
- **は** (は): marks the topic. Particle.
- **、**: punctuation
- **地味** (じみ): plain. Na-adjective.
- **なのね**: explains, seeking agreement. Sentence ending.
- **ね** (ね): seeking agreement. Sentence-ending particle.

## Nuance
A casual remark; は here is the topic.''';
    expect(tidyExplanation(answer), '''
## Translation
The other hero is quite plain, isn't he?

## Breakdown
- **もう一人** (もうひとり): one more person. Noun phrase.
- **ヒーロー**: hero. Noun.
- **地味** (じみ): plain. Na-adjective.
- **なのね**: explains, seeking agreement. Sentence ending.
- **ね**: seeking agreement. Sentence-ending particle.

## Nuance
A casual remark; は here is the topic.''');
  });

  test('other bullet styles, full-width brackets, and half-written lines', () {
    expect(
      tidyExplanation('* **が**：subject\n• **ラガン**（らがん）：Lagann.'),
      '• **ラガン**：Lagann.',
    );
  });

  test('while streaming, a bullet shows only once it is known to stay', () {
    const before = '## Breakdown\n- **俺** (おれ): I.';
    // The bold word is still being written: could become a lone particle.
    for (final tail in ['-', '- ', '- *', '- **', '- **の', '- **の*']) {
      expect(tidyExplanation('$before\n$tail'), before, reason: tail);
    }
    expect(tidyExplanation('$before\n- **の**'), before);
    expect(tidyExplanation('$before\n- **の** (の): conn'), before);
    // A reading still being written never flashes for a word with no kanji.
    expect(tidyExplanation('$before\n- **ヒーロー** (ひー'), '$before\n- **ヒーロー**');
    expect(
      tidyExplanation('$before\n- **獣人** (じゅう'),
      '$before\n- **獣人** (じゅう)',
    );
    // The same half-written line is left alone once it is not the last one.
    expect(tidyExplanation('- **引っ剥\n'), '- **引っ剥\n');
    expect(
      tidyExplanation('- plain bullet, no bold word'),
      '- plain bullet, no bold word',
    );
  });
}
