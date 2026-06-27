import 'dart:async';
import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/network_connectivity.dart';
import 'package:conduit/features/terminal/domain/predictive_terminal_session.dart';
import 'package:conduit/features/terminal/domain/roaming_terminal_session.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

SftpEntry entry(SftpEntryKind kind) =>
    SftpEntry(name: 'x', path: '/x', kind: kind);

SavedHost buildHost(String id, {String username = 'user'}) {
  return SavedHost(
    id: id,
    name: 'Host $id',
    host: '192.168.1.1',
    port: 22,
    username: username,
    authMethod: SshAuthMethod.password,
    password: 'pw',
  );
}

HostKeyPromptRequest request(String host) {
  return HostKeyPromptRequest(
    host: host,
    port: 22,
    type: 'ssh-rsa',
    fingerprint: 'MD5:aa',
    kind: HostKeyPromptKind.firstTrust,
  );
}

class InMemoryThemePreferences implements ThemePreferencesRepository {
  InMemoryThemePreferences([
    ThemePreferences preferences = const ThemePreferences(
      themeMode: ThemeMode.system,
      palette: AppPalette.catppuccin,
    ),
  ]) : _preferences = preferences;

  ThemePreferences _preferences;

  @override
  Future<ThemePreferences> load() async => _preferences;

  @override
  Future<void> save(ThemePreferences preferences) async {
    _preferences = preferences;
  }
}

class AlwaysAuthenticates implements AppAuthenticator {
  @override
  Future<AppAuthenticationResult> authenticate() async =>
      AppAuthenticationResult.success;

  @override
  Future<bool> canAuthenticate() async => true;
}

class UnavailableAuthenticator implements AppAuthenticator {
  @override
  Future<AppAuthenticationResult> authenticate() async =>
      AppAuthenticationResult.unavailable;

  @override
  Future<bool> canAuthenticate() async => false;
}

class ScriptedAuthenticator implements AppAuthenticator {
  ScriptedAuthenticator(this.result);

  final AppAuthenticationResult result;

  @override
  Future<AppAuthenticationResult> authenticate() async => result;

  @override
  Future<bool> canAuthenticate() async => true;
}

class ThrowingAuthenticator implements AppAuthenticator {
  const ThrowingAuthenticator({this.throwFromCanAuthenticate = false});

  final bool throwFromCanAuthenticate;

  @override
  Future<AppAuthenticationResult> authenticate() async {
    throw StateError('auth failed');
  }

  @override
  Future<bool> canAuthenticate() async {
    if (throwFromCanAuthenticate) {
      throw StateError('availability failed');
    }
    return true;
  }
}

class EmptyHostsRepository implements SavedHostsRepository {
  @override
  Future<List<SavedHost>> loadHosts() async => const [];

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async {}

  @override
  Future<HostListSortMode> loadSortMode() async =>
      HostListSortMode.lastConnected;

  @override
  Future<void> saveSortMode(HostListSortMode mode) async {}
}

class FakeHostsRepository implements SavedHostsRepository {
  List<SavedHost> persisted = [];
  HostListSortMode persistedSortMode = HostListSortMode.lastConnected;

  @override
  Future<List<SavedHost>> loadHosts() async => List.unmodifiable(persisted);

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async {
    persisted = List.of(hosts);
  }

  @override
  Future<HostListSortMode> loadSortMode() async => persistedSortMode;

  @override
  Future<void> saveSortMode(HostListSortMode mode) async {
    persistedSortMode = mode;
  }
}

class NoNetworkTerminalRepository implements SshTerminalRepository {
  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) {
    throw StateError('This test does not open network connections.');
  }
}

class CompletingTerminalRepository implements SshTerminalRepository {
  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    return FakeTerminalSession();
  }
}

class PendingTerminalRepository implements SshTerminalRepository {
  final Completer<SshTerminalSession> _completer =
      Completer<SshTerminalSession>();

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) {
    return _completer.future;
  }

  void complete(SshTerminalSession session) {
    _completer.complete(session);
  }
}

class FakeTerminalSession implements SshTerminalSession {
  @override
  Future<void> get done => Completer<void>().future;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Future<void> close() async {}

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {}

  @override
  Future<void> send(List<int> data) async {}
}

class TrackableTerminalSession implements SshTerminalSession {
  final Completer<void> _done = Completer<void>();
  int closeCount = 0;

  @override
  Future<void> get done => _done.future;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Future<void> close() async {
    closeCount += 1;
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {}

  @override
  Future<void> send(List<int> data) async {}
}

class ImmediateTerminalRepository implements SshTerminalRepository {
  ImmediateTerminalRepository(this._session);

  final SshTerminalSession _session;

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    return _session;
  }
}

class FakeRoamingTerminalSession
    implements SshTerminalSession, RoamingTerminalSession {
  final Completer<void> _done = Completer<void>();
  int rehomeCount = 0;

  @override
  Future<void> get done => _done.future;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Future<void> close() async {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {}

  @override
  Future<void> send(List<int> data) async {}

  @override
  Future<void> rehome() async {
    rehomeCount += 1;
  }
}

class FakePredictiveTerminalSession
    implements SshTerminalSession, PredictiveTerminalSession {
  FakePredictiveTerminalSession({
    this.smoothedRtt = const Duration(milliseconds: 180),
  });

  final Completer<void> _done = Completer<void>();
  final StreamController<int> _echoAcks = StreamController<int>.broadcast();
  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final List<List<int>> sent = <List<int>>[];
  int _inputState = 0;

  @override
  Future<void> get done => _done.future;

  @override
  Stream<int> get echoAcks => _echoAcks.stream;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  final Duration? smoothedRtt;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  void emitStdout(String data) {
    _stdout.add(utf8.encode(data));
  }

  @override
  Future<void> close() async {
    if (!_done.isCompleted) {
      _done.complete();
    }
    await _echoAcks.close();
    await _stdout.close();
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {}

  @override
  Future<void> send(List<int> data) async {
    sendWithInputState(data);
  }

  @override
  int sendWithInputState(List<int> data) {
    sent.add(List<int>.of(data));
    _inputState += 1;
    return _inputState;
  }
}

class FakeNetworkConnectivity implements NetworkConnectivity {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  void emit() => _controller.add(null);

  @override
  Stream<void> get onNetworkChanged => _controller.stream;
}

class StubPrompt implements HostKeyPrompt {
  StubPrompt({required this.decision});

  final HostKeyDecision decision;
  int calls = 0;

  @override
  Future<HostKeyDecision> request(HostKeyPromptRequest request) async {
    calls += 1;
    return decision;
  }
}

class CapturingPrompt implements HostKeyPrompt {
  CapturingPrompt({required this.decision});

  final HostKeyDecision decision;
  final List<HostKeyPromptRequest> requests = [];

  @override
  Future<HostKeyDecision> request(HostKeyPromptRequest request) async {
    requests.add(request);
    return decision;
  }
}

class NoopVerifier implements HostKeyVerifier {
  @override
  Future<List<HostKeyRecord>> loadTrustedKeys() async => const [];

  @override
  Future<void> removeTrustedKey(String host, int port) async {}

  @override
  Future<bool> verify({
    required String host,
    required int port,
    required String type,
    required String fingerprint,
  }) async => false;
}

class NoNetworkSftpRepository implements SftpRepository {
  @override
  Future<SftpSession> connect(SavedHost host) {
    throw StateError('This test does not open SFTP connections.');
  }
}

class FakeSftpRepository implements SftpRepository {
  FakeSftpRepository(this.session);

  final FakeSftpSession session;

  @override
  Future<SftpSession> connect(SavedHost host) async => session;
}

class ThrowingSftpRepository implements SftpRepository {
  @override
  Future<SftpSession> connect(SavedHost host) async => throw StateError('boom');
}

class FakeSftpSession implements SftpSession {
  FakeSftpSession({required this.home, required this.tree});

  final String home;
  final Map<String, List<SftpEntry>> tree;
  final List<String> madeDirectories = [];
  final Map<String, List<int>> writtenFiles = {};
  final Map<String, int> listCalls = {};

  @override
  Future<List<SftpEntry>> list(String path) async {
    listCalls[path] = (listCalls[path] ?? 0) + 1;
    final entries = tree[path];
    if (entries == null) {
      throw StateError('No such directory: $path');
    }
    return List.of(entries);
  }

  @override
  Future<String> resolve(String path) async => path == '.' ? home : path;

  @override
  Future<Uint8List> read(
    String path, {
    void Function(int bytesRead, int? total)? onProgress,
  }) async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    onProgress?.call(bytes.length, bytes.length);
    return bytes;
  }

  @override
  Future<void> write(
    String path,
    Stream<Uint8List> data,
    int length, {
    void Function(int bytesSent)? onProgress,
  }) async {
    final bytes = <int>[];
    await for (final chunk in data) {
      bytes.addAll(chunk);
      onProgress?.call(bytes.length);
    }
    writtenFiles[path] = bytes;
  }

  @override
  Future<void> makeDirectory(String path) async {
    madeDirectories.add(path);
    tree[path] = <SftpEntry>[];
  }

  @override
  Future<void> rename(String from, String to) async {}

  @override
  Future<void> delete(SftpEntry entry) async {}

  @override
  Future<void> close() async {}
}

class RecordingFileExport implements FileExport {
  final List<(String, Uint8List)> saved = [];

  @override
  Future<String?> save(String fileName, Uint8List bytes) async {
    saved.add((fileName, bytes));
    return 'Downloads/$fileName';
  }
}

class FakeCtapDevice extends CtapDevice {
  FakeCtapDevice({required this.signature, required this.authData});

  final List<int> signature;
  final List<int> authData;
  final List<List<int>> commands = [];

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    commands.add(List.of(command));
    return CtapResponse(
      CtapStatusCode.ctap1ErrSuccess.value,
      cbor.encode(
        CborValue({
          GetAssertionResponse.credentialIdx: {
            'type': 'public-key',
            'id': CborBytes(const [0x01]),
          },
          GetAssertionResponse.authDataIdx: CborBytes(authData),
          GetAssertionResponse.signatureIdx: CborBytes(signature),
        }),
      ),
    );
  }
}

String fakeSecurityKeyPem() {
  return OpenSSHSecurityKeyEd25519KeyPair(
    publicKey: Uint8List.fromList(List<int>.filled(32, 3)),
    application: 'ssh:',
    flags: 0x01,
    keyHandle: Uint8List.fromList([0xAA]),
    reserved: '',
  ).toPem();
}

class InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}
