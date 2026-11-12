final _ext = RegExp(r'\.[A-Za-z0-9]{2,4}$');
final _brackets = RegExp(r'\[[^\]]*\]|\{[^}]*\}|【[^】]*】');
final _trailingParens = RegExp(r'(\s*\([^)]*\))+\s*$');
final _quality = RegExp(
  r'\b(\d{3,4}p|[0-9]{3,4}x[0-9]{3,4}|web-?(dl|rip)|bdrip|bluray|hevc|x26[45]|aac)\b.*$',
  caseSensitive: false,
);

/// "[Erai-raws] Show - 02 [1080p CR WEBRip HEVC AAC][MultiSub].mkv" → "Show - 02".
/// Drops release-group/quality tags; returns the bare file name if nothing is left.
String displayName(String fileName) {
  final bare = fileName.replaceFirst(_ext, '');
  var s = bare.replaceAll(_brackets, ' ').replaceFirst(_trailingParens, '');
  if (!s.contains(' ')) {
    s = s.replaceAll(RegExp(r'[._]'), ' '); // Show.Name.S01E02.1080p
  }
  s = s.replaceFirst(_quality, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceFirst(RegExp(r'[\s\-–_.]+$'), '');
  return s.isEmpty ? bare : s;
}
