import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/whats_new/changelog.dart';

const _sample = '''
# Changelog

Intro text that is not a release.

## [Unreleased]

### Added

- Not released yet

## [0.2.0] - 2026-12-01

### Added

- Explain: a **button** in the player that
  explains the line, see [the docs](https://example.com)
- Second thing

### Changed

### Fixed
- Fixed `Space` on the first press

## [0.1.9] - 2026-11-20

### Fixed

- One fix

## [0.1.8]

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/compare/v0.1.9...v0.2.0
''';

void main() {
  test('reads released versions, their headings and their entries', () {
    final releases = parseChangelog(_sample);
    expect(releases.map((r) => r.version), ['0.2.0', '0.1.9']);
    final latest = releases.first;
    expect(latest.date, '2026-12-01');
    // "Changed" is empty and is left out; wrapped lines and marks are tidied.
    expect(latest.groups.map((g) => g.title), ['Added', 'Fixed']);
    expect(latest.groups.first.items, [
      'Explain: a button in the player that explains the line, see the docs',
      'Second thing',
    ]);
    expect(latest.groups.last.items, ['Fixed Space on the first press']);
    // The link list at the bottom is not part of the last entry.
    expect(releases.last.groups.single.items, ['One fix']);
  });

  test('after an update: everything newer than what was last seen', () {
    final all = parseChangelog(_sample);
    List<String> unseen(String installed, String? seen) => [
      for (final r in unseenReleases(all, installed: installed, seen: seen))
        r.version,
    ];
    expect(unseen('0.2.0', '0.1.9'), ['0.2.0']);
    expect(unseen('0.2.0', '0.1.7'), ['0.2.0', '0.1.9']); // skipped a version
    expect(unseen('0.2.0', '0.2.0'), isEmpty); // already seen, or fresh install
    // Not yet released versions in the file are never announced.
    expect(unseen('0.1.9', '0.1.8'), ['0.1.9']);
    // Updated from a version that kept no record: just the installed one.
    expect(unseen('0.2.0', null), ['0.2.0']);
    expect(unseen('0.3.0', null), isEmpty); // no notes for it
  });

  test('the real changelog has notes for the version in pubspec.yaml', () {
    final releases = parseChangelog(
      File('docs/CHANGELOG.md').readAsStringSync(),
    );
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
    expect(releases, isNotEmpty);
    expect(releases.first.version, version);
    for (final r in releases) {
      expect(r.groups, isNotEmpty, reason: r.version);
      expect(r.date, isNotNull, reason: r.version);
    }
  });
}
