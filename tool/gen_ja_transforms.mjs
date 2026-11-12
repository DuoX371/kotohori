// Usage: copy Yomitan's ext/js/language/{language-transforms.js, ja/japanese-transforms.js}
// into a folder keeping that layout, add {"type":"module"} as package.json there, then:
//   node tool/gen_ja_transforms.mjs <folder>/ja/japanese-transforms.js lib/features/dictionary/deinflect/ja_transforms.dart
import {pathToFileURL} from 'node:url';
import {writeFileSync} from 'node:fs';
const [, , modPath, outPath] = process.argv;
const {japaneseTransforms: d} = await import(pathToFileURL(modPath).href);
const q = (s) => JSON.stringify(s).replace(/\$/g, '\$');
const ql = (a) => '[' + a.map(q).join(', ') + ']';
let o = `// GENERATED from Yomitan ext/js/language/ja/japanese-transforms.js — do not edit by hand.
//
// Copyright (C) 2024-2026  Yomitan Authors
// Ported to Dart for Kotohori. Licensed under the GNU General Public License v3 or later.
// Source: https://github.com/yomidevs/yomitan

import 'deinflector.dart';

const jaConditions = <String, ConditionDef>{\n`;
for (const [k, c] of Object.entries(d.conditions)) {
  o += `  ${q(k)}: ConditionDef(${c.isDictionaryForm}${c.subConditions ? ', ' + ql(c.subConditions) : ''}),\n`;
}
o += `};\n\nconst jaTransforms = <TransformDef>[\n`;
for (const [id, t] of Object.entries(d.transforms)) {
  o += `  TransformDef(${q(id)}, ${q(t.name)}, [\n`;
  for (const r of t.rules) {
    const src = r.isInflected.source;
    const inflected = r.type === 'suffix' ? src.slice(0, -1) : src.slice(1, -1);
    const out = r.type === 'suffix' ? r.deinflected : r.deinflect('');
    if (r.type !== 'suffix' && r.type !== 'wholeWord') throw new Error('unknown rule type ' + r.type);
    if (/[\^$.*+?()[\]{}|]/.test(inflected)) throw new Error('regex metachar in ' + src);
    o += `    RuleDef.${r.type === 'suffix' ? 'suffix' : 'whole'}(${q(inflected)}, ${q(out)}, ${ql(r.conditionsIn)}, ${ql(r.conditionsOut)}),\n`;
  }
  o += `  ]),\n`;
}
o += '];\n';
writeFileSync(outPath, o);
console.log('transforms', Object.keys(d.transforms).length, 'conditions', Object.keys(d.conditions).length);
