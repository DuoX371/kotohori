import '../../platform/anki_bridge.dart';
import 'anki_settings.dart';

/// A ready-made note type Kotohori can create in AnkiDroid.
class NoteDesign {
  const NoteDesign({
    required this.name,
    required this.fieldMap,
    required this.css,
    required this.front,
    required this.back,
    this.cardName = 'Card',
    this.credit,
  });

  /// Also the note type's name in Anki, e.g. "Kotohori Cinema".
  final String name;

  /// Who the design is based on, shown under its preview.
  final String? credit;

  /// Field name → what Kotohori fills it with, in field order.
  final Map<String, CardSource> fieldMap;
  final String css, front, back, cardName;

  List<String> get fields => fieldMap.keys.toList();

  /// Reuses a note type of the same name (e.g. made earlier or on another device)
  /// instead of creating a duplicate. Returns its id.
  Future<int> ensure(AnkiBridge anki) async {
    final existing = (await anki.models())
        .where((m) => m.name == name)
        .firstOrNull;
    if (existing != null) return existing.id;
    return anki.addModel(
      name: name,
      fields: fields,
      css: css,
      cards: [(name: cardName, front: front, back: back)],
    );
  }
}

/// The eight fields every modern design shares, so switching designs keeps cards compatible.
const _modernFields = {
  'Word': CardSource.word,
  'Reading': CardSource.reading,
  'Definition': CardSource.definition,
  'Sentence': CardSource.sentence,
  'Picture': CardSource.image,
  'WordAudio': CardSource.wordAudio,
  'SentenceAudio': CardSource.audio,
  'Source': CardSource.source,
};

/// Shared look for the modern designs: light by default, Kotohori's dark palette in
/// AnkiDroid's night mode, target word in gold.
const _modernBase = '''
.card {
  font-family: "Hiragino Sans", "Noto Sans JP", "Noto Sans CJK JP", sans-serif;
  font-size: 20px;
  line-height: 1.5;
  text-align: center;
  color: #1b1d21;
  background: #f3f4f6;
}
.card.nightMode, .nightMode .card { color: #eceae4; background: #121417; }
b { color: #8a6a1f; }
.nightMode b { color: #e2b85c; }
.def { text-align: left; max-width: 40em; margin: 0.8em auto; }
.src { font-size: 0.75em; opacity: 0.6; margin-top: 1.2em; }
hr#answer { border: none; border-top: 1px solid rgba(128, 128, 128, 0.35); margin: 1em 0; }
img { max-width: 100%; }
''';

const noteDesigns = [classicDesign, modernDesign, cinemaDesign, focusDesign];

/// The user's own "Japanese" vocab note type, unchanged, plus a SentenceAudio field
/// played under the sentence.
const classicDesign = NoteDesign(
  name: 'Kotohori Classic',
  cardName: 'Vocab',
  credit: 'Based on the vocab card template by Trenton (トレントン), with sentence audio added.',
  fieldMap: {
    'Word': CardSource.word,
    'Furigana': CardSource.reading,
    'meaning': CardSource.definition,
    'audio': CardSource.wordAudio,
    'pitch': CardSource.none,
    'image': CardSource.image,
    'sentence': CardSource.sentence,
    'SentenceAudio': CardSource.audio,
  },
  css: '''
/* Based on the vocab card template by Trenton (トレントン),
   "You Should Be Using Anki": https://youtu.be/_MWtbI4IwfU?t=859
   Kotohori Classic adds a SentenceAudio field under the sentence. */
.card {
 font-size: 23px;
 text-align: center;
 color: black;
 background-color: #FFFAF0;
 margin: 20px auto 20px auto;
 padding: 0 20px 0 20px;
 max-width: 700px;
}

#word ruby rt {visibility:hidden;}
#word ruby:hover rt {visibility:visible;}
#word ruby rt {font-size:20px;}

@font-face {font-family: noto; src: url('_NotoSerifJP.otf');}

.jp {font-family: noto, "Noto Serif JP", "Noto Serif CJK JP", serif; font-size:40px;}
.meaning {font-family: Times New Roman}
''',
  front: '''<div id="word" class="jp">{{furigana:Word}} </div>

<div style='font-family: Noto; font-size: 20px;'>{{audio}}</div>''',
  back: '''{{FrontSide}}
{{Furigana}}
<hr id=answer>


<div style='font-family: Noto; font-size: 20px;'>{{meaning}}</div>
{{pitch}}


<div style='font-family: Noto; font-size: 14px;'>{{sentence}}</div>
<div style='font-family: Noto; font-size: 20px;'>{{SentenceAudio}}</div>
<div> ----</div>
<div style='font-family: Noto; font-size: 20px;'>{{image}}</div>''',
);

/// Word and sentence up front, everything else on the back.
const modernDesign = NoteDesign(
  name: 'Kotohori Modern',
  cardName: 'Recognition',
  fieldMap: _modernFields,
  css: '''$_modernBase
.word { font-size: 2.6em; font-weight: 700; margin: 0.3em 0 0.1em; }
.sentence { font-size: 1.25em; margin: 0.4em auto; max-width: 36em; }
.reading { font-size: 1.5em; margin: 0.3em 0; }
.pic img { max-height: 45vh; border-radius: 10px; margin: 0.6em 0; }
''',
  front: '''<div class="word">{{Word}}</div>
<div class="sentence">{{Sentence}}</div>
{{WordAudio}}''',
  back: '''{{FrontSide}}
<hr id="answer">
<div class="reading">{{Reading}}</div>
{{SentenceAudio}}
{{#Picture}}<div class="pic">{{Picture}}</div>{{/Picture}}
<div class="def">{{Definition}}</div>
{{#Source}}<div class="src">{{Source}}</div>{{/Source}}''',
);

/// The scene leads: you see the moment and the line, and recall the bold word.
const cinemaDesign = NoteDesign(
  name: 'Kotohori Cinema',
  cardName: 'Scene',
  fieldMap: _modernFields,
  css: '''$_modernBase
.card { background: #121417; color: #eceae4; }
b { color: #e2b85c; }
.scene { position: relative; max-width: 900px; margin: 0 auto; }
.scene img { width: 100%; max-height: 55vh; object-fit: cover; border-radius: 14px; display: block; }
.line {
  font-size: 1.4em; margin: 0.6em auto 0; max-width: 36em;
  text-shadow: 0 0 6px #000, 0 0 2px #000;
}
.word { font-size: 2.4em; font-weight: 700; margin-top: 0.4em; }
.reading { font-size: 1.3em; color: #9a9c9f; }
.def { background: #1c1f24; border-radius: 12px; padding: 0.6em 1em; }
.src { color: #9a9c9f; }
''',
  front: '''{{#Picture}}<div class="scene">{{Picture}}</div>{{/Picture}}
<div class="line">{{Sentence}}</div>''',
  back: '''{{FrontSide}}
{{SentenceAudio}}
<hr id="answer">
<div class="word">{{Word}}</div>
<div class="reading">{{Reading}}</div>
{{WordAudio}}
<div class="def">{{Definition}}</div>
{{#Source}}<div class="src">{{Source}}</div>{{/Source}}''',
);

/// Pure vocabulary recall: nothing but the word on the front.
const focusDesign = NoteDesign(
  name: 'Kotohori Focus',
  cardName: 'Word',
  fieldMap: _modernFields,
  css: '''$_modernBase
.word { font-size: 3.4em; font-weight: 700; margin-top: 18vh; letter-spacing: 0.04em; }
.reading { font-size: 1.6em; margin-top: 0.2em; }
.def { font-size: 0.95em; }
.context {
  display: flex; flex-direction: column; align-items: center; gap: 0.5em;
  margin: 1.2em auto 0; max-width: 32em; font-size: 0.9em; opacity: 0.85;
}
.context img { max-height: 28vh; border-radius: 8px; }
''',
  front: '<div class="word">{{Word}}</div>',
  back: '''<div class="word" style="margin-top: 0.4em">{{Word}}</div>
<div class="reading">{{Reading}}</div>
{{WordAudio}}
<hr id="answer">
<div class="def">{{Definition}}</div>
<div class="context">
  {{Picture}}
  <div>{{Sentence}} {{SentenceAudio}}</div>
</div>
{{#Source}}<div class="src">{{Source}}</div>{{/Source}}''',
);

/// Fills a card template the way Anki does, for previews: `{{Field}}`,
/// `{{FrontSide}}`, `{{furigana:Field}}`, `{{#Field}}…{{/Field}}`, `{{^Field}}…{{/Field}}`.
/// `[sound:…]` becomes a play icon (previews don't play audio).
String renderCardTemplate(
  String template,
  Map<String, String> fields, {
  String frontSide = '',
}) {
  var out = template.replaceAllMapped(
    RegExp(r'\{\{([#^])([^}]+)\}\}([\s\S]*?)\{\{/\2\}\}'),
    (m) {
      final has = (fields[m[2]!.trim()] ?? '').trim().isNotEmpty;
      return (m[1] == '#') == has ? m[3]! : '';
    },
  );
  out = out.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (m) {
    final key = m[1]!.trim();
    if (key == 'FrontSide') return frontSide;
    final name = key.contains(':') ? key.split(':').last : key;
    return fields[name] ?? '';
  });
  return out.replaceAll(
    RegExp(r'\[sound:[^\]]*\]'),
    '<span class="kh-play">▶</span>',
  );
}
