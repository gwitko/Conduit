/// A record of one file Conduit uploaded to a host, used so automatic
/// cleanup can only ever touch files the app itself wrote.
class UploadManifestEntry {
  const UploadManifestEntry({required this.path, required this.uploadedAt});

  final String path;
  final DateTime uploadedAt;

  Map<String, Object?> toJson() {
    return {'path': path, 'at': uploadedAt.toUtc().millisecondsSinceEpoch};
  }

  static UploadManifestEntry? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final path = json['path'];
    final at = json['at'];
    if (path is! String || path.isEmpty || at is! int) {
      return null;
    }
    return UploadManifestEntry(
      path: path,
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UploadManifestEntry &&
        other.path == path &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode => Object.hash(path, uploadedAt);
}

/// Per-host ledger of Conduit-owned remote uploads.
abstract class UploadManifestRepository {
  Future<List<UploadManifestEntry>> entriesFor(String hostId);

  Future<void> setEntries(String hostId, List<UploadManifestEntry> entries);
}
