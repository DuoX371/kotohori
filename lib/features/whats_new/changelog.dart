import '../update/update_check.dart' show compareVersions;

/// One heading of a release ("Added", "Fixed") and its lines.
typedef ChangelogGroup = ({String title, List<String> items});

/// One released version from `docs/CHANGELOG.md`.
class ChangelogRelease {
  const ChangelogRelease(this.version, this.date, this.groups);
  final String version;

  /// As written in the file ("2026-11-17"); null when missing.
  final String? date;
  final List<ChangelogGroup> groups;
}

final _release = RegExp(r'^##\s+\[([^\]]+)\](?:\s*-\s*(\S+))?');
final _group = RegExp(r'^###\s+(.+?)\s*$');
final _item = RegExp(r'^\s*[-*]\s+(.*)$');
final _linkReference = RegExp(r'^\[[^\]]+\]:\s');

/// The released versions in [markdown] (Keep a Changelog format), newest
/// first as written. "Unreleased" and empty headings are left out.
List<ChangelogRelease> parseChangelog(String markdown) {
  final releases = <ChangelogRelease>[];
  List<ChangelogGroup>? groups; // null: outside a released version
  List<String>? items;
  var inItem = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.startsWith('## ')) {
      final m = _release.firstMatch(line);
      inItem = false;
      items = null;
      if (m == null || m.group(1)!.toLowerCase() == 'unreleased') {
        groups = null;
        continue;
      }
      groups = [];
      releases.add(ChangelogRelease(m.group(1)!, m.group(2), groups));
    } else if (groups == null) {
      continue;
    } else if (_group.firstMatch(line) case final m?) {
      items = [];
      groups.add((title: m.group(1)!, items: items));
      inItem = false;
    } else if (_item.firstMatch(line) case final m? when items != null) {
      items.add(_plain(m.group(1)!));
      inItem = true;
    } else if (line.trim().isEmpty || _linkReference.hasMatch(line)) {
      inItem = false;
    } else if (inItem && items != null) {
      // A wrapped line of the same entry.
      items[items.length - 1] = '${items.last} ${_plain(line.trim())}';
    }
  }
  return [
    for (final r in releases)
      if (r.groups.any((g) => g.items.isNotEmpty))
        ChangelogRelease(r.version, r.date, [
          for (final g in r.groups)
            if (g.items.isNotEmpty) g,
        ]),
  ];
}

/// Markdown marks removed, for showing as plain text.
String _plain(String text) => text
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!)
    .replaceAll('**', '')
    .replaceAll('`', '');

/// The releases to announce after an update: newer than [seen] (the version
/// whose notes the user last saw), up to [installed]. With [seen] unknown
/// (the app was updated from a version that didn't keep track), only the
/// installed version. Newest first.
List<ChangelogRelease> unseenReleases(
  List<ChangelogRelease> all, {
  required String installed,
  required String? seen,
}) => [
  for (final r in all)
    if (compareVersions(r.version, installed) <= 0 &&
        (seen == null
            ? compareVersions(r.version, installed) == 0
            : compareVersions(r.version, seen) > 0))
      r,
];
