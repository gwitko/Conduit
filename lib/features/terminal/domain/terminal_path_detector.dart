/// Extracts the file path under a tapped column of terminal output, so paths
/// printed by compilers, greps, and shells can be opened in the file viewer.
///
/// Returns null when the tapped character is not part of something that looks
/// like a file path. Trailing `:line` / `:line:column` suffixes (grep, build
/// errors) and surrounding punctuation are stripped.
String? terminalPathAt(String text, int column) {
  if (column < 0 || column >= text.length) {
    return null;
  }
  if (!_isPathChar(text.codeUnitAt(column))) {
    return null;
  }
  var start = column;
  while (start > 0 && _isPathChar(text.codeUnitAt(start - 1))) {
    start--;
  }
  var end = column + 1;
  while (end < text.length && _isPathChar(text.codeUnitAt(end))) {
    end++;
  }
  return _cleanCandidate(text.substring(start, end));
}

String? _cleanCandidate(String token) {
  if (token.contains('://')) {
    return null;
  }
  // grep/compiler output: path:12:34:matched text — keep only the path part.
  var path = token.split(':').first;
  // Flag values ("--config=/etc/app.conf") — keep what follows the '='.
  final equals = path.lastIndexOf('=');
  if (equals != -1) {
    path = path.substring(equals + 1);
  }
  while (path.startsWith(',')) {
    path = path.substring(1);
  }
  // Sentence punctuation glued onto the path ("see /etc/hosts.").
  while (path.isNotEmpty &&
      _isTrailingPunctuation(path.codeUnitAt(path.length - 1))) {
    path = path.substring(0, path.length - 1);
  }
  while (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final looksLikePath =
      path.contains('/') || path.startsWith('~') || path.startsWith('.');
  if (!looksLikePath || path.length < 2 || path == './' || path == '..') {
    return null;
  }
  // Require a real name: at least one letter or digit.
  if (!path.codeUnits.any(_isAlphanumeric)) {
    return null;
  }
  return path;
}

bool _isPathChar(int codeUnit) {
  if (_isAlphanumeric(codeUnit)) {
    return true;
  }
  const allowed = r'./_-~+@%=:,';
  return allowed.codeUnits.contains(codeUnit);
}

bool _isTrailingPunctuation(int codeUnit) {
  const punctuation = '.,;!?';
  return punctuation.codeUnits.contains(codeUnit);
}

bool _isAlphanumeric(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A);
}
