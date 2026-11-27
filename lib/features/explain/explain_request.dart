import '../subtitles/cue.dart';

enum ExplainSource { show, book }

/// What one press of Explain asks for: the [targets] to explain, shown inside
/// [lines] (the targets plus nearby dialogue, in order).
class ExplainRequest {
  const ExplainRequest({
    required this.title,
    required this.lines,
    required this.targets,
    required this.model,
    this.source = ExplainSource.show,
    this.paragraph = false,
  });

  /// A whole paragraph of a book: a lighter answer (see [explainPrompt]).
  final bool paragraph;

  /// The video's display name ("Show - 02"), or the book's title.
  final String title;

  /// Subtitle lines of a show, or sentences of a book (changes the wording).
  final ExplainSource source;
  final List<Cue> lines;
  final List<Cue> targets;

  /// The Gemini model's id.
  final String model;

  /// The text being explained, one subtitle per line.
  String get targetText => targets.map((c) => _oneLine(c.text)).join('\n');

  /// Same lines and model = same answer (used to reuse a finished one). A
  /// show's lines are numbered through the episode; a book's are numbered only
  /// within the request, so a book's are matched by their text.
  String get cacheKey => switch (source) {
    ExplainSource.show => '$model ${targets.map((c) => c.index).join(',')}',
    ExplainSource.book => '$model ${paragraph ? 'p' : 's'} $targetText',
  };
}

/// Longest silence between two lines that still counts as the same scene.
const explainSceneGap = Duration(seconds: 10);

/// [targets] plus up to [max] lines before and after, stopping in each direction
/// at the first silence longer than [gap] (so a line minutes away is never sent).
/// [cues] must be sorted by start; [targets] must come from it.
List<Cue> explainContext(
  List<Cue> cues,
  List<Cue> targets, {
  int max = 3,
  Duration gap = explainSceneGap,
}) {
  if (targets.isEmpty) return const [];
  var first = cues.indexOf(targets.first), last = cues.indexOf(targets.last);
  if (first < 0 || last < 0) return targets;
  final (from, to) = (first, last);
  // Overlapping lines give a negative silence, which always counts as close.
  while (first > 0 &&
      from - first < max &&
      cues[first].start - cues[first - 1].end <= gap) {
    first--;
  }
  while (last < cues.length - 1 &&
      last - to < max &&
      cues[last + 1].start - cues[last].end <= gap) {
    last++;
  }
  return cues.sublist(first, last + 1);
}

String _oneLine(String text) => text.replaceAll('\n', ' ').trim();

const _showIntro = '''
You help an English-speaking learner of Japanese who is watching a show with Japanese subtitles.
You are given a few subtitle lines in order. Explain only the line or lines marked with ">". The other lines are there only so you understand the scene; do not explain them.
''';

const _bookIntro = '''
You help an English-speaking learner of Japanese who is reading a Japanese light novel.
You are given a few sentences in order. Explain only the sentence or sentences marked with ">". The other sentences are there only so you understand the scene; do not explain them.
''';

const _instructions = '''

Answer in English, in Markdown, with exactly these three sections and nothing else:

## Translation
One natural English sentence for the marked line.

## Breakdown
One bullet for each word or grammar piece worth explaining in the marked line, in order, in exactly this form:
- **Japanese** (reading): meaning. Role.

Rules for the bullets:
- Copy the Japanese exactly as it is written in the line. Never list a word or particle that is not there.
- Skip punctuation and symbols (、。！？… and the like). They never get a bullet.
- Do not give a basic particle doing its ordinary job (が, を, に, は, の, で, と, も, へ) a bullet of its own: the learner knows these. Give a particle a bullet only when it adds tone or meaning: sentence endings (ね, よ, ぞ, からね, っけ), casual or contracted forms (って, じゃ, んだ), combinations with their own meaning (のに, には, ても), or a basic particle used in an unusual way.
- Give the reading in hiragana only for pieces that contain kanji, and read only the kanji part that way: katakana stays katakana. Leave out "(reading)" when there is no kanji.
- Keep words that belong together in one bullet: a noun with the の or counter that is part of it (もう一人, 昨日の試合), a verb with its endings, and grammar that works as one unit (わけじゃない, なのね). Never split a word into single kanji.
- Role is a few words: noun, verb in passive past form, and so on.

Example of a good Breakdown, for the line 私、昨日の試合には行けなかったんだよね:
- **私** (わたし): I. Pronoun.
- **昨日の試合** (きのうのしあい): yesterday's match. Noun phrase.
- **には**: to (the match), as the topic. に marks where, は adds a hint of contrast.
- **行けなかった** (いけなかった): couldn't go. Potential form of 行く, negative past.
- **んだよね**: explains, then seeks agreement. Explanatory んだ softened by よね.

## Nuance
One to three sentences on tone, politeness, and anything implied, idiomatic or slangy. Use the surrounding lines to judge what is meant, and say only what the lines support.

Be brief and accurate. Never use romaji.''';

const _paragraphIntro = '''
You help an English-speaking learner of Japanese who is reading a Japanese light novel.
You are given a few sentences in order. Explain only the paragraph made of the sentences marked with ">". The other sentences are there only so you understand the scene; do not explain them.

Answer in English, in Markdown, with exactly these three sections and nothing else:

## Translation
A natural English translation of the marked paragraph.

## Hard parts
Up to six bullets, only for the words, grammar or expressions in the marked paragraph that a learner is most likely to stumble on, in order, in exactly this form:
- **Japanese** (reading): meaning. Why it matters here.
Copy the Japanese exactly as written. Give the reading in hiragana only for pieces with kanji. Skip anything easy: basic particles, common words, punctuation.

## Nuance
One to three sentences on tone, what is implied, and how the paragraph fits the scene. Say only what the sentences support.

Be brief and accurate. Never use romaji.''';

/// The standing instructions and the question for [r].
({String system, String user}) explainPrompt(ExplainRequest r) {
  final marked = {for (final c in r.targets) c.index};
  final dialogue = [
    for (final c in r.lines)
      '${marked.contains(c.index) ? '>' : ' '} ${_oneLine(c.text)}',
  ].join('\n');
  return switch (r.source) {
    ExplainSource.show => (
      system: _showIntro + _instructions,
      user: 'Show: ${r.title}\n\nSubtitle lines:\n$dialogue',
    ),
    ExplainSource.book when r.paragraph => (
      system: _paragraphIntro,
      user: 'Book: ${r.title}\n\nSentences:\n$dialogue',
    ),
    ExplainSource.book => (
      system: _bookIntro + _instructions,
      user: 'Book: ${r.title}\n\nSentences:\n$dialogue',
    ),
  };
}
