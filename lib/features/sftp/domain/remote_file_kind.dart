/// How a remote file should be presented in the file viewer.
enum RemoteFileKind { image, pdf, html, text }

/// Files larger than this are not opened in the viewer; download instead.
const remoteFileViewerMaxBytes = 24 * 1024 * 1024;

/// Text files larger than this open read-only to keep editing responsive.
const remoteFileEditorMaxBytes = 2 * 1024 * 1024;

const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'ico'};

RemoteFileKind remoteFileKindForPath(String path) {
  final extension = remoteFileExtension(path);
  if (_imageExtensions.contains(extension)) {
    return RemoteFileKind.image;
  }
  if (extension == 'pdf') {
    return RemoteFileKind.pdf;
  }
  if (extension == 'html' || extension == 'htm') {
    return RemoteFileKind.html;
  }
  return RemoteFileKind.text;
}

String remoteFileExtension(String path) {
  final name = remoteFileName(path);
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1).toLowerCase();
}

String remoteFileName(String path) {
  final trimmed = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  final slash = trimmed.lastIndexOf('/');
  return slash == -1 ? trimmed : trimmed.substring(slash + 1);
}

/// True when [bytes] look like text rather than a binary blob.
///
/// A NUL byte in the sampled prefix is the classic binary marker; everything
/// else is treated as text and decoded leniently.
bool remoteFileLooksTextual(List<int> bytes) {
  final sample = bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes;
  return !sample.contains(0);
}
