import 'dart:convert';

import 'package:crypto/crypto.dart';

class RootfsManifest {
  const RootfsManifest({
    required this.version,
    required this.archiveUrl,
    required this.sha256,
    required this.downloadSizeBytes,
    required this.pacmanMirror,
    this.keyringName = 'archlinuxarm',
  });

  final String version;
  final Uri archiveUrl;

  final String sha256;
  final int downloadSizeBytes;

  final String pacmanMirror;

  final String keyringName;

  factory RootfsManifest.fromJson(Map<String, Object?> json) {
    final url = (json['archiveUrl'] as String?)?.trim() ?? '';
    final sha = (json['sha256'] as String?)?.trim().toLowerCase() ?? '';
    final mirror = (json['pacmanMirror'] as String?)?.trim() ?? '';
    final version = (json['version'] as String?)?.trim() ?? '';
    final size = (json['downloadSizeBytes'] as num?)?.toInt() ?? 0;

    if (url.isEmpty) {
      throw const FormatException('Manifest is missing "archiveUrl".');
    }
    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null || !parsedUrl.hasScheme) {
      throw FormatException('Manifest "archiveUrl" is not a valid URL: $url');
    }
    if (sha.length != 64 || !_isHex(sha)) {
      throw const FormatException(
        'Manifest "sha256" must be a 64-character hex digest.',
      );
    }
    if (version.isEmpty) {
      throw const FormatException('Manifest is missing "version".');
    }
    if (mirror.isEmpty) {
      throw const FormatException('Manifest is missing "pacmanMirror".');
    }

    return RootfsManifest(
      version: version,
      archiveUrl: parsedUrl,
      sha256: sha,
      downloadSizeBytes: size,
      pacmanMirror: mirror,
      keyringName: (json['keyringName'] as String?)?.trim().isNotEmpty == true
          ? (json['keyringName'] as String).trim()
          : 'archlinuxarm',
    );
  }

  static bool _isHex(String value) => RegExp(r'^[0-9a-f]+$').hasMatch(value);
}

bool verifySha256(List<int> bytes, String expectedSha256) {
  final actual = sha256.convert(bytes).toString();
  return actual == expectedSha256.trim().toLowerCase();
}

class Sha256Verifier {
  Sha256Verifier(this._expected);

  final String _expected;
  Digest? _digest;
  late final ByteConversionSink _input = sha256.startChunkedConversion(
    _DigestCollector((digest) => _digest = digest),
  );
  bool _closed = false;

  void addChunk(List<int> chunk) {
    if (_closed) return;
    _input.add(chunk);
  }

  bool verify() {
    if (!_closed) {
      _input.close();
      _closed = true;
    }
    return _digest?.toString() == _expected.trim().toLowerCase();
  }
}

class _DigestCollector implements Sink<Digest> {
  _DigestCollector(this._onDigest);

  final void Function(Digest digest) _onDigest;

  @override
  void add(Digest data) => _onDigest(data);

  @override
  void close() {}
}
