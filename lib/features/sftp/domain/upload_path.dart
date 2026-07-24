/// Pure helpers for building safe remote upload paths.
library;

/// Default remote directory (under the user's home) that uploads land in,
/// with one dated subdirectory per day.
const defaultUploadDirectoryName = '.conduit/uploads';

/// Formats the dated subdirectory for an upload batch: `yyyy-mm-dd`.
String uploadDateDirectory(DateTime now) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${now.year.toString().padLeft(4, '0')}-'
      '${pad(now.month)}-${pad(now.day)}';
}

/// Resolves the absolute remote upload directory for a host.
///
/// [home] is the server-resolved home directory. A [custom] directory from
/// host settings may be absolute, `~/`-relative, or home-relative; when
/// absent, uploads go to `$home/.conduit/uploads/<yyyy-mm-dd>`.
String resolveUploadDirectory({
  required String home,
  required DateTime now,
  String? custom,
}) {
  final base = custom?.trim();
  final root = home.endsWith('/') ? home.substring(0, home.length - 1) : home;
  if (base == null || base.isEmpty) {
    return '$root/$defaultUploadDirectoryName/${uploadDateDirectory(now)}';
  }
  if (base.startsWith('/')) {
    return _stripTrailingSlash(base);
  }
  if (base == '~') {
    return root;
  }
  if (base.startsWith('~/')) {
    return _stripTrailingSlash('$root/${base.substring(2)}');
  }
  return _stripTrailingSlash('$root/$base');
}

String _stripTrailingSlash(String path) {
  return path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
}

/// Makes a picked filename safe to use as a single remote path segment.
///
/// Path separators and control characters are removed so a hostile or odd
/// filename cannot escape the upload directory; everything else — spaces,
/// Unicode, punctuation — is preserved for recognizability because inserted
/// paths are always shell-quoted separately.
String sanitizeUploadFileName(String name) {
  var base = name.split('/').last.split(r'\').last;
  base = base.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
  if (base.isEmpty || base == '.' || base == '..') {
    return 'file';
  }
  return base;
}

/// Picks a name that does not collide with [existing] entries, preserving
/// the extension: `photo.jpg` becomes `photo-143502.jpg` (upload time), and
/// `photo-143502-2.jpg` if even that is taken.
String resolveUploadCollision(String name, Set<String> existing, DateTime now) {
  if (!existing.contains(name)) {
    return name;
  }
  final dot = name.lastIndexOf('.');
  final stem = dot > 0 ? name.substring(0, dot) : name;
  final extension = dot > 0 ? name.substring(dot) : '';
  String pad(int value) => value.toString().padLeft(2, '0');
  final stamp = '${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
  var candidate = '$stem-$stamp$extension';
  var counter = 2;
  while (existing.contains(candidate)) {
    candidate = '$stem-$stamp-$counter$extension';
    counter += 1;
  }
  return candidate;
}

const _posixSafePattern = r'^[A-Za-z0-9._/\-]+$';

/// Quotes [value] for safe literal use in a POSIX shell command line.
///
/// Values made only of unambiguously safe characters pass through unquoted;
/// everything else is wrapped in single quotes with embedded single quotes
/// escaped as `'\''`, which keeps spaces, quotes, `$`, parentheses, newlines,
/// and globs literal in sh/bash/zsh/fish.
String posixShellQuote(String value) {
  if (value.isNotEmpty &&
      !value.startsWith('-') &&
      RegExp(_posixSafePattern).hasMatch(value)) {
    return value;
  }
  return "'${value.replaceAll("'", "'\\''")}'";
}
