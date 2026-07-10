class HostKeyRecord {
  const HostKeyRecord({
    required this.host,
    required this.port,
    required this.type,
    required this.fingerprint,
    required this.trustedAt,
  });

  final String host;
  final int port;
  final String type;
  final String fingerprint;
  final DateTime trustedAt;

  String get key => '$host:$port';

  Map<String, Object?> toJson() {
    return {
      'host': host,
      'port': port,
      'type': type,
      'fingerprint': fingerprint,
      'trustedAt': trustedAt.toIso8601String(),
    };
  }

  factory HostKeyRecord.fromJson(Map<String, Object?> json) {
    return HostKeyRecord(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      type: json['type'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      trustedAt:
          DateTime.tryParse(json['trustedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

abstract interface class HostKeyVerifier {
  Future<bool> verify({
    required String host,
    required int port,
    required String type,
    required String fingerprint,
  });

  Future<List<HostKeyRecord>> loadTrustedKeys();

  Future<void> saveTrustedKeys(List<HostKeyRecord> records);

  Future<void> removeTrustedKey(String host, int port);
}
