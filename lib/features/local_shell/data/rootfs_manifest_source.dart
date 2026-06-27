import 'dart:convert';

import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';
import 'package:http/http.dart' as http;

abstract interface class RootfsManifestSource {
  Future<RootfsManifest> fetch();
}

class EmbeddedRootfsManifestSource implements RootfsManifestSource {
  EmbeddedRootfsManifestSource(this.manifest);

  final RootfsManifest manifest;

  @override
  Future<RootfsManifest> fetch() async => manifest;
}

class HttpRootfsManifestSource implements RootfsManifestSource {
  HttpRootfsManifestSource(this.manifestUrl, [http.Client? client])
    : _client = client ?? http.Client();

  final Uri manifestUrl;
  final http.Client _client;

  @override
  Future<RootfsManifest> fetch() async {
    final response = await _client.get(manifestUrl);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Manifest request failed (HTTP ${response.statusCode}).',
        manifestUrl,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Manifest is not a JSON object.');
    }
    return RootfsManifest.fromJson(decoded);
  }
}
