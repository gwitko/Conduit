import 'package:conduit/features/snippets/domain/terminal_snippet.dart';

enum SshAuthMethod { password, privateKey, hardwareKey, external }

enum TmuxPrefixKey { controlB, controlA }

const defaultTmuxPrefixKey = TmuxPrefixKey.controlB;
const defaultTmuxSessionName = 'conduit';

bool _parseStartTmuxOnConnect(Map<String, Object?> json) {
  return json['startTmuxOnConnect'] as bool? ?? false;
}

class HardwareKeyEntry {
  const HardwareKeyEntry({
    required this.id,
    required this.privateKey,
    this.label = '',
    this.passphrase = '',
  });

  final String id;
  final String privateKey;
  final String label;
  final String passphrase;

  bool get isValid => id.isNotEmpty && privateKey.trim().isNotEmpty;

  HardwareKeyEntry copyWith({String? label}) {
    return HardwareKeyEntry(
      id: id,
      privateKey: privateKey,
      label: label ?? this.label,
      passphrase: passphrase,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'privateKey': privateKey,
      'passphrase': passphrase,
    };
  }

  static HardwareKeyEntry? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final privateKey = json['privateKey'];
    final label = json['label'];
    final passphrase = json['passphrase'];
    if (id is! String || privateKey is! String) {
      return null;
    }
    final entry = HardwareKeyEntry(
      id: id,
      privateKey: privateKey,
      label: label is String ? label : '',
      passphrase: passphrase is String ? passphrase : '',
    );
    return entry.isValid ? entry : null;
  }
}

List<HardwareKeyEntry> _parseHardwareKeys(Map<String, Object?> json) {
  final entries = (json['hardwareKeys'] as List? ?? const [])
      .map(HardwareKeyEntry.fromJson)
      .whereType<HardwareKeyEntry>()
      .toList(growable: false);
  if (entries.isNotEmpty) {
    return entries;
  }
  final authMethod = json['authMethod'];
  final legacyKey = json['privateKey'] as String? ?? '';
  if (authMethod == SshAuthMethod.hardwareKey.name &&
      legacyKey.trim().isNotEmpty) {
    return [
      HardwareKeyEntry(
        id: 'legacy',
        privateKey: legacyKey,
        passphrase: json['passphrase'] as String? ?? '',
      ),
    ];
  }
  return const [];
}

class MoshPortRange {
  const MoshPortRange(this.first, this.last);

  final int first;
  final int last;

  static final RegExp _pattern = RegExp(r'^(\d{1,5})(?::(\d{1,5}))?$');

  static MoshPortRange? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final first = int.parse(match.group(1)!);
    final last = match.group(2) == null ? first : int.parse(match.group(2)!);
    if (first < 1 || last > 65535 || last < first) {
      return null;
    }
    return MoshPortRange(first, last);
  }
}

String _parseMoshPorts(Map<String, Object?> json) {
  final raw = (json['moshPorts'] as String?)?.trim() ?? '';
  return MoshPortRange.tryParse(raw) == null ? '' : raw;
}

extension TmuxPrefixKeyDetails on TmuxPrefixKey {
  String get label => switch (this) {
    TmuxPrefixKey.controlB => 'Ctrl-B',
    TmuxPrefixKey.controlA => 'Ctrl-A',
  };
}

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
    this.hardwareKeys = const [],
    this.externalAuthOfferKey = true,
    this.forwardAgent = false,
    this.tags = const [],
    this.connectionTimeoutSeconds = 12,
    this.useMosh = false,
    this.moshLocale = 'C.UTF-8',
    this.moshPorts = '',
    this.predictiveEchoEnabled = false,
    this.startTmuxOnConnect = false,
    this.tmuxPrefixKey = defaultTmuxPrefixKey,
    this.tmuxSessionName = defaultTmuxSessionName,
    this.tmuxStartDirectory = '',
    this.snippets = const [],
    this.connectSnippetId = '',
    this.lastConnectedAt,
    this.isLocal = false,
  });

  factory SavedHost.localShell({required String id}) {
    return SavedHost(
      id: id,
      name: 'Arch Linux',
      host: 'localhost',
      port: 0,
      username: 'root',
      authMethod: SshAuthMethod.external,
      isLocal: true,
    );
  }

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final SshAuthMethod authMethod;
  final String password;
  final String privateKey;
  final String passphrase;
  final List<HardwareKeyEntry> hardwareKeys;
  final bool externalAuthOfferKey;
  final bool forwardAgent;
  final List<String> tags;
  final int connectionTimeoutSeconds;
  final bool useMosh;
  final String moshLocale;
  final String moshPorts;
  final bool predictiveEchoEnabled;
  final bool startTmuxOnConnect;
  final TmuxPrefixKey tmuxPrefixKey;
  final String tmuxSessionName;
  final String tmuxStartDirectory;
  final List<TerminalSnippet> snippets;
  final String connectSnippetId;
  final DateTime? lastConnectedAt;
  final bool isLocal;

  bool get isValid =>
      id.isNotEmpty &&
      name.trim().isNotEmpty &&
      host.trim().isNotEmpty &&
      port > 0 &&
      port <= 65535 &&
      connectionTimeoutSeconds >= 3 &&
      connectionTimeoutSeconds <= 120 &&
      switch (authMethod) {
        SshAuthMethod.password => password.isNotEmpty,
        SshAuthMethod.privateKey => privateKey.trim().isNotEmpty,
        SshAuthMethod.hardwareKey =>
          hardwareKeys.isNotEmpty
              ? hardwareKeys.every((key) => key.isValid)
              : privateKey.trim().isNotEmpty,
        SshAuthMethod.external => true,
      };

  /// Hardware-key stubs to authenticate with, tolerating hosts created
  /// before multi-key support that only carry the legacy single-stub fields.
  List<HardwareKeyEntry> get effectiveHardwareKeys {
    if (hardwareKeys.isNotEmpty) {
      return hardwareKeys;
    }
    if (privateKey.trim().isEmpty) {
      return const [];
    }
    return [
      HardwareKeyEntry(
        id: 'legacy',
        privateKey: privateKey,
        passphrase: passphrase,
      ),
    ];
  }

  String get endpoint {
    final trimmedUsername = username.trim();
    final trimmedHost = host.trim();
    if (trimmedUsername.isEmpty) {
      return '$trimmedHost:$port';
    }
    return '$trimmedUsername@$trimmedHost:$port';
  }

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
    List<HardwareKeyEntry>? hardwareKeys,
    bool? externalAuthOfferKey,
    bool? forwardAgent,
    List<String>? tags,
    int? connectionTimeoutSeconds,
    bool? useMosh,
    String? moshLocale,
    String? moshPorts,
    bool? predictiveEchoEnabled,
    bool? startTmuxOnConnect,
    TmuxPrefixKey? tmuxPrefixKey,
    String? tmuxSessionName,
    String? tmuxStartDirectory,
    List<TerminalSnippet>? snippets,
    String? connectSnippetId,
    DateTime? lastConnectedAt,
    bool clearLastConnectedAt = false,
    bool? isLocal,
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
      hardwareKeys: hardwareKeys ?? this.hardwareKeys,
      externalAuthOfferKey: externalAuthOfferKey ?? this.externalAuthOfferKey,
      forwardAgent: forwardAgent ?? this.forwardAgent,
      tags: tags ?? this.tags,
      connectionTimeoutSeconds:
          connectionTimeoutSeconds ?? this.connectionTimeoutSeconds,
      useMosh: useMosh ?? this.useMosh,
      moshLocale: moshLocale ?? this.moshLocale,
      moshPorts: moshPorts ?? this.moshPorts,
      predictiveEchoEnabled:
          predictiveEchoEnabled ?? this.predictiveEchoEnabled,
      startTmuxOnConnect: startTmuxOnConnect ?? this.startTmuxOnConnect,
      tmuxPrefixKey: tmuxPrefixKey ?? this.tmuxPrefixKey,
      tmuxSessionName: tmuxSessionName ?? this.tmuxSessionName,
      tmuxStartDirectory: tmuxStartDirectory ?? this.tmuxStartDirectory,
      snippets: snippets ?? this.snippets,
      connectSnippetId: connectSnippetId ?? this.connectSnippetId,
      lastConnectedAt: clearLastConnectedAt
          ? null
          : lastConnectedAt ?? this.lastConnectedAt,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, Object?> toJson() {
    final effectiveKeys = authMethod == SshAuthMethod.hardwareKey
        ? effectiveHardwareKeys
        : const <HardwareKeyEntry>[];
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authMethod': authMethod.name,
      'password': password,
      'privateKey': effectiveKeys.isNotEmpty
          ? effectiveKeys.first.privateKey
          : privateKey,
      'passphrase': effectiveKeys.isNotEmpty
          ? effectiveKeys.first.passphrase
          : passphrase,
      'hardwareKeys': [for (final key in effectiveKeys) key.toJson()],
      'externalAuthOfferKey': externalAuthOfferKey,
      'forwardAgent': forwardAgent,
      'tags': tags,
      'connectionTimeoutSeconds': connectionTimeoutSeconds,
      'useMosh': useMosh,
      'moshLocale': moshLocale,
      'moshPorts': moshPorts,
      'predictiveEchoEnabled': predictiveEchoEnabled,
      'startTmuxOnConnect': startTmuxOnConnect,
      'tmuxPrefixKey': tmuxPrefixKey.name,
      'tmuxSessionName': tmuxSessionName,
      'tmuxStartDirectory': tmuxStartDirectory,
      'snippets': [for (final snippet in snippets) snippet.toJson()],
      'connectSnippetId': connectSnippetId,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'isLocal': isLocal,
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
      hardwareKeys: _parseHardwareKeys(json),
      externalAuthOfferKey: json['externalAuthOfferKey'] as bool? ?? true,
      forwardAgent: json['forwardAgent'] as bool? ?? false,
      tags: tags,
      connectionTimeoutSeconds: json['connectionTimeoutSeconds'] as int? ?? 12,
      useMosh: json['useMosh'] as bool? ?? false,
      moshLocale: (json['moshLocale'] as String?)?.trim().isNotEmpty == true
          ? (json['moshLocale'] as String).trim()
          : 'C.UTF-8',
      moshPorts: _parseMoshPorts(json),
      predictiveEchoEnabled: json['predictiveEchoEnabled'] as bool? ?? false,
      startTmuxOnConnect: _parseStartTmuxOnConnect(json),
      tmuxPrefixKey: TmuxPrefixKey.values.firstWhere(
        (key) => key.name == json['tmuxPrefixKey'],
        orElse: () => defaultTmuxPrefixKey,
      ),
      tmuxSessionName:
          (json['tmuxSessionName'] as String?)?.trim().isNotEmpty == true
          ? (json['tmuxSessionName'] as String).trim()
          : defaultTmuxSessionName,
      tmuxStartDirectory: (json['tmuxStartDirectory'] as String?)?.trim() ?? '',
      snippets: (json['snippets'] as List? ?? const [])
          .map(TerminalSnippet.fromJson)
          .whereType<TerminalSnippet>()
          .toList(growable: false),
      connectSnippetId: json['connectSnippetId'] as String? ?? '',
      lastConnectedAt: lastConnectedAtRaw == null
          ? null
          : DateTime.tryParse(lastConnectedAtRaw),
      isLocal: json['isLocal'] as bool? ?? false,
    );
  }
}
