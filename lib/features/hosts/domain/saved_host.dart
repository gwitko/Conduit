enum SshAuthMethod { password, privateKey, hardwareKey }

class SavedHost {
  const SavedHost({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.authMethod,
    this.password = '',
    this.privateKey = '',
    this.passphrase = '',
    this.tags = const [],
    this.connectionTimeoutSeconds = 12,
    this.useMosh = false,
    this.moshLocale = 'C.UTF-8',
    this.predictiveEchoEnabled = false,
    this.lastConnectedAt,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final SshAuthMethod authMethod;
  final String password;
  final String privateKey;
  final String passphrase;
  final List<String> tags;
  final int connectionTimeoutSeconds;
  final bool useMosh;
  final String moshLocale;
  final bool predictiveEchoEnabled;
  final DateTime? lastConnectedAt;

  bool get isValid =>
      id.isNotEmpty &&
      name.trim().isNotEmpty &&
      host.trim().isNotEmpty &&
      port > 0 &&
      port <= 65535 &&
      username.trim().isNotEmpty &&
      connectionTimeoutSeconds >= 3 &&
      connectionTimeoutSeconds <= 120 &&
      switch (authMethod) {
        SshAuthMethod.password => password.isNotEmpty,
        SshAuthMethod.privateKey => privateKey.trim().isNotEmpty,
        SshAuthMethod.hardwareKey => privateKey.trim().isNotEmpty,
      };

  String get endpoint => '$username@$host:$port';

  SavedHost copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    SshAuthMethod? authMethod,
    String? password,
    String? privateKey,
    String? passphrase,
    List<String>? tags,
    int? connectionTimeoutSeconds,
    bool? useMosh,
    String? moshLocale,
    bool? predictiveEchoEnabled,
    DateTime? lastConnectedAt,
    bool clearLastConnectedAt = false,
  }) {
    return SavedHost(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passphrase: passphrase ?? this.passphrase,
      tags: tags ?? this.tags,
      connectionTimeoutSeconds:
          connectionTimeoutSeconds ?? this.connectionTimeoutSeconds,
      useMosh: useMosh ?? this.useMosh,
      moshLocale: moshLocale ?? this.moshLocale,
      predictiveEchoEnabled:
          predictiveEchoEnabled ?? this.predictiveEchoEnabled,
      lastConnectedAt: clearLastConnectedAt
          ? null
          : lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authMethod': authMethod.name,
      'password': password,
      'privateKey': privateKey,
      'passphrase': passphrase,
      'tags': tags,
      'connectionTimeoutSeconds': connectionTimeoutSeconds,
      'useMosh': useMosh,
      'moshLocale': moshLocale,
      'predictiveEchoEnabled': predictiveEchoEnabled,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  factory SavedHost.fromJson(Map<String, Object?> json) {
    final authMethod = SshAuthMethod.values.firstWhere(
      (method) => method.name == json['authMethod'],
      orElse: () => SshAuthMethod.password,
    );
    final lastConnectedAtRaw = json['lastConnectedAt'] as String?;

    final tags = (json['tags'] as List? ?? const [])
        .whereType<String>()
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);

    return SavedHost(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      username: json['username'] as String? ?? '',
      authMethod: authMethod,
      password: json['password'] as String? ?? '',
      privateKey: json['privateKey'] as String? ?? '',
      passphrase: json['passphrase'] as String? ?? '',
      tags: tags,
      connectionTimeoutSeconds: json['connectionTimeoutSeconds'] as int? ?? 12,
      useMosh: json['useMosh'] as bool? ?? false,
      moshLocale: (json['moshLocale'] as String?)?.trim().isNotEmpty == true
          ? (json['moshLocale'] as String).trim()
          : 'C.UTF-8',
      predictiveEchoEnabled: json['predictiveEchoEnabled'] as bool? ?? false,
      lastConnectedAt: lastConnectedAtRaw == null
          ? null
          : DateTime.tryParse(lastConnectedAtRaw),
    );
  }
}
