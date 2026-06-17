import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cbor/cbor.dart';
import 'package:conduit/core/app_failure.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/hosts/presentation/host_form_page.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart';
import 'package:conduit/features/terminal/data/secure_host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/network_connectivity.dart';
import 'package:conduit/features/terminal/domain/predictive_terminal_session.dart';
import 'package:conduit/features/terminal/domain/roaming_terminal_session.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';
import 'package:conduit/features/terminal/data/openssh_security_key_signer.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_coordinator.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/main.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('system navigation insets', () {
    test('keeps Android gesture navigation edge-to-edge', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.android,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isFalse,
      );
    });

    test('protects Android three-button navigation', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.android,
          systemGestureInsets: EdgeInsets.zero,
        ),
        isTrue,
      );
      expect(
        shouldPaintAndroidThreeButtonNavigationBackgroundFor(
          platform: TargetPlatform.android,
          systemGestureInsets: EdgeInsets.zero,
        ),
        isTrue,
      );
    });

    test('preserves safe areas on non-Android platforms', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.iOS,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isTrue,
      );
      expect(
        shouldPaintAndroidThreeButtonNavigationBackgroundFor(
          platform: TargetPlatform.iOS,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isFalse,
      );
    });
  });

  testWidgets('unlocks into the saved machine list', (tester) async {
    final promptCoordinator = HostKeyPromptCoordinator();
    final verifier = _NoopVerifier();
    await tester.pumpWidget(
      ConduitApp(
        lockController: AppLockController(_AlwaysAuthenticates()),
        themeController: ThemeController(_InMemoryThemePreferences()),
        hostsController: HostsController(_EmptyHostsRepository()),
        terminalRepository: _NoNetworkTerminalRepository(),
        workspaceController: TerminalWorkspaceController(
          _NoNetworkTerminalRepository(),
        ),
        hostKeyVerifier: verifier,
        promptCoordinator: promptCoordinator,
        sftpRepository: _NoNetworkSftpRepository(),
        fileExport: _RecordingFileExport(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Conduit'), findsWidgets);
    expect(find.text('No machines yet'), findsOneWidget);
    expect(find.text('Add machine'), findsOneWidget);
  });

  test('workspace opens, focuses, and closes machine tabs', () async {
    final workspace = TerminalWorkspaceController(
      _CompletingTerminalRepository(),
    );
    const firstHost = SavedHost(
      id: 'first',
      name: 'First',
      host: '192.168.1.10',
      port: 22,
      username: 'user',
      authMethod: SshAuthMethod.password,
      password: 'password',
    );
    const secondHost = SavedHost(
      id: 'second',
      name: 'Second',
      host: '192.168.1.11',
      port: 22,
      username: 'user',
      authMethod: SshAuthMethod.password,
      password: 'password',
    );

    final firstSession = workspace.open(firstHost);
    final duplicateFirstSession = workspace.open(firstHost);
    final secondSession = workspace.open(secondHost);

    expect(workspace.sessions, hasLength(2));
    expect(duplicateFirstSession, same(firstSession));
    expect(workspace.activeSession, same(secondSession));
    expect(workspace.liveSessionCount, 0);

    await firstSession.connect();
    expect(workspace.liveSessionCount, 1);
    await secondSession.connect();
    expect(workspace.liveSessionCount, 2);

    workspace.activate(firstSession);
    expect(workspace.activeSession, same(firstSession));

    await workspace.close(firstSession);
    expect(workspace.sessions, hasLength(1));
    expect(workspace.activeSession, same(secondSession));
    expect(workspace.liveSessionCount, 1);

    await workspace.closeAll();
    expect(workspace.sessions, isEmpty);
    expect(workspace.liveSessionCount, 0);
  });

  group('TerminalSessionController', () {
    test('ignores a connection that completes after disconnect', () async {
      final repository = _PendingTerminalRepository();
      final session = _TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: _buildHost('late'),
        repository: repository,
      );

      final connect = controller.connect();
      expect(controller.status, TerminalConnectionStatus.connecting);

      await controller.disconnect();
      repository.complete(session);
      await connect;

      expect(controller.status, TerminalConnectionStatus.disconnected);
      expect(session.closeCount, 1);

      controller.dispose();
    });

    test('re-homes a roaming session when connectivity changes', () async {
      final session = _RoamingTerminalSession();
      final connectivity = _FakeNetworkConnectivity();
      final controller = TerminalSessionController(
        host: _buildHost('roam'),
        repository: _ImmediateTerminalRepository(session),
        connectivity: connectivity,
      );

      await controller.connect();
      expect(controller.status, TerminalConnectionStatus.connected);

      connectivity.emit();
      await Future<void>.delayed(Duration.zero);
      expect(session.rehomeCount, 1);

      await controller.disconnect();
      connectivity.emit();
      await Future<void>.delayed(Duration.zero);
      expect(session.rehomeCount, 1);

      controller.dispose();
    });

    test('ignores connectivity changes for a non-roaming session', () async {
      final session = _TrackableTerminalSession();
      final connectivity = _FakeNetworkConnectivity();
      final controller = TerminalSessionController(
        host: _buildHost('ssh'),
        repository: _ImmediateTerminalRepository(session),
        connectivity: connectivity,
      );

      await controller.connect();
      connectivity.emit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, TerminalConnectionStatus.connected);

      controller.dispose();
    });

    test('keeps predictive overlays until confirmed output arrives', () async {
      final session = _PredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: _buildHost('predict'),
        repository: _ImmediateTerminalRepository(session),
        predictiveEchoEnabled: true,
      );

      await controller.connect();
      controller.sendText('l');
      controller.sendText('s');

      expect(session.sent.map(String.fromCharCodes), ['l', 's']);
      expect(controller.overlays.map((overlay) => overlay.text).join(), 'ls');
      expect(controller.overlays.map((overlay) => overlay.column), [0, 1]);

      session.emitStdout('ls');
      await Future<void>.delayed(Duration.zero);
      expect(controller.overlays, isEmpty);

      controller.dispose();
    });

    test(
      'shows predictive overlays before the first mosh RTT sample',
      () async {
        final session = _PredictiveTerminalSession(smoothedRtt: null);
        final controller = TerminalSessionController(
          host: _buildHost('predict-no-rtt'),
          repository: _ImmediateTerminalRepository(session),
          predictiveEchoEnabled: true,
        );

        await controller.connect();
        controller.sendText('x');

        expect(controller.overlays.map((overlay) => overlay.text).join(), 'x');

        controller.dispose();
      },
    );

    test('leaves predictive echo disabled by default', () async {
      final session = _PredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: _buildHost('predict-default-off'),
        repository: _ImmediateTerminalRepository(session),
      );

      await controller.connect();
      controller.sendText('x');

      expect(session.sent.map(String.fromCharCodes), ['x']);
      expect(controller.predictiveEchoEnabled, isFalse);
      expect(controller.overlays, isEmpty);

      controller.dispose();
    });

    test(
      'hides predictive cells once confirmed output reaches the buffer',
      () async {
        final session = _PredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: _buildHost('predict-confirmed'),
          repository: _ImmediateTerminalRepository(session),
          predictiveEchoEnabled: true,
        );

        await controller.connect();
        controller.sendText('l');
        controller.sendText('s');
        expect(controller.overlays.map((overlay) => overlay.text).join(), 'ls');

        session.emitStdout('l');
        await Future<void>.delayed(Duration.zero);
        expect(controller.overlays.map((overlay) => overlay.text).join(), 's');

        session.emitStdout('s');
        await Future<void>.delayed(Duration.zero);
        expect(controller.overlays, isEmpty);

        controller.dispose();
      },
    );

    test(
      'clears stale predictive cells once output cursor passes them',
      () async {
        final session = _PredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: _buildHost('predict-stale'),
          repository: _ImmediateTerminalRepository(session),
          predictiveEchoEnabled: true,
        );

        await controller.connect();
        controller.sendText('a');
        controller.sendText('b');
        expect(controller.overlays.map((overlay) => overlay.text).join(), 'ab');

        session.emitStdout('xy');
        await Future<void>.delayed(Duration.zero);
        expect(controller.overlays, isEmpty);

        controller.dispose();
      },
    );

    test('predicts backspace over confirmed terminal text', () async {
      final session = _PredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: _buildHost('predict-backspace'),
        repository: _ImmediateTerminalRepository(session),
        predictiveEchoEnabled: true,
      );

      await controller.connect();
      controller.sendText('abc');
      session.emitStdout('abc');
      await Future<void>.delayed(Duration.zero);

      controller.sendKey(TerminalKey.backspace);

      expect(session.sent.map(String.fromCharCodes), ['abc', '\x7f']);
      expect(controller.overlays, hasLength(1));
      expect(controller.overlays.single.column, 2);
      expect(controller.overlays.single.text, isEmpty);
      expect(controller.overlays.single.erase, isTrue);

      controller.dispose();
    });

    test('can disable predictive overlays while keeping mosh input', () async {
      final session = _PredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: _buildHost('predict-off'),
        repository: _ImmediateTerminalRepository(session),
        predictiveEchoEnabled: false,
      );

      await controller.connect();
      controller.sendText('l');
      controller.sendText('s');

      expect(session.sent.map(String.fromCharCodes), ['l', 's']);
      expect(controller.overlays, isEmpty);

      controller.predictiveEchoEnabled = true;
      controller.sendText('!');
      expect(controller.overlays.map((overlay) => overlay.text).join(), '!');

      controller.predictiveEchoEnabled = false;
      expect(controller.overlays, isEmpty);

      controller.dispose();
    });

    test(
      'deduplicates iOS enter events delivered through two input paths',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final session = _PredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: _buildHost('ios-enter'),
          repository: _ImmediateTerminalRepository(session),
        );
        addTearDown(controller.dispose);

        await controller.connect();
        controller.sendKey(TerminalKey.enter);
        controller.sendKey(TerminalKey.enter);

        expect(session.sent.map(String.fromCharCodes), ['\r']);
      },
    );

    test(
      'deduplicates mixed iOS enter outputs from action and text input',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final session = _PredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: _buildHost('ios-mixed-enter'),
          repository: _ImmediateTerminalRepository(session),
        );
        addTearDown(controller.dispose);

        await controller.connect();
        controller.sendKey(TerminalKey.enter);
        controller.sendText('\n');

        expect(session.sent.map(String.fromCharCodes), ['\r']);
      },
    );
  });

  group('SavedHost.isValid', () {
    const base = SavedHost(
      id: 'id',
      name: 'name',
      host: '192.168.1.1',
      port: 22,
      username: 'user',
      authMethod: SshAuthMethod.password,
      password: 'p',
    );

    test('rejects empty id, name, host, username', () {
      expect(base.copyWith(id: '').isValid, isFalse);
      expect(base.copyWith(name: ' ').isValid, isFalse);
      expect(base.copyWith(host: '').isValid, isFalse);
      expect(base.copyWith(username: '').isValid, isFalse);
    });

    test('rejects out-of-range ports', () {
      expect(base.copyWith(port: 0).isValid, isFalse);
      expect(base.copyWith(port: 65536).isValid, isFalse);
      expect(base.copyWith(port: 1).isValid, isTrue);
      expect(base.copyWith(port: 65535).isValid, isTrue);
    });

    test('rejects out-of-range timeouts', () {
      expect(base.copyWith(connectionTimeoutSeconds: 2).isValid, isFalse);
      expect(base.copyWith(connectionTimeoutSeconds: 121).isValid, isFalse);
      expect(base.copyWith(connectionTimeoutSeconds: 3).isValid, isTrue);
      expect(base.copyWith(connectionTimeoutSeconds: 120).isValid, isTrue);
    });

    test('requires credential for the chosen auth method', () {
      expect(base.copyWith(password: '').isValid, isFalse);
      expect(
        base
            .copyWith(authMethod: SshAuthMethod.privateKey, privateKey: '')
            .isValid,
        isFalse,
      );
      expect(
        base
            .copyWith(authMethod: SshAuthMethod.privateKey, privateKey: 'pem')
            .isValid,
        isTrue,
      );
      expect(
        base
            .copyWith(authMethod: SshAuthMethod.hardwareKey, privateKey: '')
            .isValid,
        isFalse,
      );
      expect(
        base
            .copyWith(
              authMethod: SshAuthMethod.hardwareKey,
              privateKey: 'openssh-sk-stub',
            )
            .isValid,
        isTrue,
      );
    });
  });

  group('SavedHost round-trip', () {
    test('toJson then fromJson preserves all fields', () {
      final original = SavedHost(
        id: 'id',
        name: 'My Host',
        host: 'example.com',
        port: 2222,
        username: 'root',
        authMethod: SshAuthMethod.privateKey,
        privateKey: '-----BEGIN-----',
        passphrase: 'pp',
        tags: const ['prod', 'edge'],
        connectionTimeoutSeconds: 30,
        useMosh: true,
        moshLocale: 'en_US.UTF-8',
        predictiveEchoEnabled: false,
        lastConnectedAt: DateTime.parse('2025-01-02T03:04:05Z'),
      );

      final decoded = SavedHost.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.host, original.host);
      expect(decoded.port, original.port);
      expect(decoded.username, original.username);
      expect(decoded.authMethod, original.authMethod);
      expect(decoded.privateKey, original.privateKey);
      expect(decoded.passphrase, original.passphrase);
      expect(decoded.tags, original.tags);
      expect(
        decoded.connectionTimeoutSeconds,
        original.connectionTimeoutSeconds,
      );
      expect(decoded.useMosh, original.useMosh);
      expect(decoded.moshLocale, original.moshLocale);
      expect(decoded.predictiveEchoEnabled, original.predictiveEchoEnabled);
      expect(decoded.lastConnectedAt, original.lastConnectedAt);
    });

    test('preserves hardware key auth method', () {
      const original = SavedHost(
        id: 'id',
        name: 'Hardware Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.hardwareKey,
        privateKey: '-----BEGIN OPENSSH PRIVATE KEY-----',
      );

      final decoded = SavedHost.fromJson(original.toJson());

      expect(decoded.authMethod, SshAuthMethod.hardwareKey);
      expect(decoded.privateKey, original.privateKey);
      expect(decoded.passphrase, isEmpty);
    });
  });

  group('HostFormPage auth validation', () {
    testWidgets('private key rejects OpenSSH hardware key stubs', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Host',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Host or IP'),
        'example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'root',
      );
      await tester.tap(find.text('Private key').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Private key'),
        _fakeSecurityKeyPem(),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add machine'));
      await tester.pumpAndSettle();

      expect(
        find.text('This is a hardware-key stub. Choose Hardware key instead.'),
        findsOneWidget,
      );
    });
  });

  group('OpenSSH security key signer', () {
    test('converts CTAP ECDSA assertion into OpenSSH sk signature', () async {
      final device = _FakeCtapDevice(
        signature: const [0x30, 0x06, 0x02, 0x01, 0x05, 0x02, 0x01, 0x07],
        authData: [...List<int>.filled(32, 0), 0x01, 0x00, 0x00, 0x00, 0x09],
      );
      final signer = OpenSshSecurityKeySigner(openDevice: () async => device);
      final keyPair = signer.attach([
        OpenSSHSecurityKeyEcdsaKeyPair(
          q: Uint8List.fromList([0x04, ...List<int>.filled(64, 0x01)]),
          application: 'ssh:',
          flags: 0x01,
          keyHandle: Uint8List.fromList([0xAA, 0xBB]),
          reserved: '',
        ),
      ]).single;

      final signature = await keyPair.signAsync(Uint8List.fromList([1, 2, 3]));

      expect(signature, isA<SSHSecurityKeyEcdsaSignature>());
      final skSignature = signature as SSHSecurityKeyEcdsaSignature;
      expect(skSignature.r, BigInt.from(5));
      expect(skSignature.s, BigInt.from(7));
      expect(skSignature.flags, 0x01);
      expect(skSignature.counter, 9);

      final request =
          cbor.decode(device.commands.single.sublist(1)).toObject() as Map;
      final allowList =
          request[GetAssertionRequest.allowListIdx] as List<Object?>;
      final allowedCredential = allowList.single as Map<Object?, Object?>;
      expect(device.commands.single.first, Ctap2Commands.getAssertion.value);
      expect(request[GetAssertionRequest.rpIdIdx], 'ssh:');
      expect(
        request[GetAssertionRequest.clientDataHashIdx],
        crypto.sha256.convert([1, 2, 3]).bytes,
      );
      expect(allowedCredential['id'], [0xAA, 0xBB]);
    });

    test('converts CTAP Ed25519 assertion into OpenSSH sk signature', () async {
      final rawSignature = List<int>.generate(64, (index) => index);
      final device = _FakeCtapDevice(
        signature: rawSignature,
        authData: [...List<int>.filled(32, 0), 0x05, 0x00, 0x00, 0x00, 0x0A],
      );
      final signer = OpenSshSecurityKeySigner(openDevice: () async => device);
      final keyPair = signer.attach([
        OpenSSHSecurityKeyEd25519KeyPair(
          publicKey: Uint8List.fromList(List<int>.filled(32, 0x01)),
          application: 'ssh:',
          flags: 0x05,
          keyHandle: Uint8List.fromList([0xCC, 0xDD]),
          reserved: '',
        ),
      ]).single;

      final signature = await keyPair.signAsync(Uint8List.fromList([4, 5, 6]));

      expect(signature, isA<SSHSecurityKeyEd25519Signature>());
      final skSignature = signature as SSHSecurityKeyEd25519Signature;
      expect(skSignature.signature, rawSignature);
      expect(skSignature.flags, 0x05);
      expect(skSignature.counter, 10);
    });
  });

  group('SshClientFactory hardware key identities', () {
    test('rejects security key stubs for private key auth', () {
      final factory = SshClientFactory(
        _NoopVerifier(),
        keyPairParser: (_, _) => [
          OpenSSHSecurityKeyEd25519KeyPair(
            publicKey: Uint8List.fromList(List<int>.filled(32, 3)),
            application: 'ssh:',
            flags: 0x01,
            keyHandle: Uint8List.fromList([0xAA]),
            reserved: '',
          ),
        ],
      );

      expect(
        () => factory.identitiesForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.privateKey,
            privateKey: 'openssh sk key',
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('rejects normal private keys for hardware key auth', () {
      final factory = SshClientFactory(
        _NoopVerifier(),
        keyPairParser: (_, _) => [
          OpenSSHEd25519KeyPair(
            Uint8List.fromList(List<int>.filled(32, 1)),
            Uint8List.fromList(List<int>.filled(64, 2)),
            'normal key',
          ),
        ],
      );

      expect(
        () => factory.identitiesForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.hardwareKey,
            privateKey: 'normal openssh key',
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('keeps only security key pairs for hardware key auth', () {
      final factory = SshClientFactory(
        _NoopVerifier(),
        keyPairParser: (_, _) => [
          OpenSSHEd25519KeyPair(
            Uint8List.fromList(List<int>.filled(32, 1)),
            Uint8List.fromList(List<int>.filled(64, 2)),
            'normal key',
          ),
          OpenSSHSecurityKeyEd25519KeyPair(
            publicKey: Uint8List.fromList(List<int>.filled(32, 3)),
            application: 'ssh:',
            flags: 0x01,
            keyHandle: Uint8List.fromList([0xAA]),
            reserved: '',
          ),
        ],
      );

      final identities = factory.identitiesForTesting(
        const SavedHost(
          id: 'id',
          name: 'Host',
          host: 'example.com',
          port: 22,
          username: 'root',
          authMethod: SshAuthMethod.hardwareKey,
          privateKey: 'openssh sk key',
        ),
      );

      expect(identities, hasLength(1));
      expect(identities!.single, isA<OpenSSHSecurityKeyPair>());
    });
  });

  group('HostsController', () {
    test('upsert + load surfaces persisted hosts', () async {
      final repository = _FakeHostsRepository();
      final controller = HostsController(repository);
      await controller.load();

      await controller.upsert(_buildHost('a'));
      expect(controller.hosts, hasLength(1));
      expect(repository.persisted, hasLength(1));
    });

    test('markConnected uses the latest version of the host', () async {
      final repository = _FakeHostsRepository();
      final controller = HostsController(repository);
      await controller.load();
      await controller.upsert(_buildHost('a', username: 'old'));
      final stale = _buildHost('a', username: 'old');
      await controller.upsert(_buildHost('a', username: 'new'));

      await controller.markConnected(stale);

      final saved = repository.persisted.single;
      expect(saved.username, 'new');
      expect(saved.lastConnectedAt, isNotNull);
    });
  });

  group('SecureHostKeyVerifier', () {
    test('first connection prompts and trusts on accept', () async {
      final storage = _InMemorySecureStorage();
      final prompt = _StubPrompt(decision: HostKeyDecision.trust);
      final verifier = SecureHostKeyVerifier(storage, prompt);

      final ok = await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      expect(ok, isTrue);
      expect(prompt.calls, 1);
      expect(await verifier.loadTrustedKeys(), hasLength(1));
    });

    test('first connection rejected does not persist', () async {
      final storage = _InMemorySecureStorage();
      final prompt = _StubPrompt(decision: HostKeyDecision.reject);
      final verifier = SecureHostKeyVerifier(storage, prompt);

      final ok = await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      expect(ok, isFalse);
      expect(await verifier.loadTrustedKeys(), isEmpty);
    });

    test('matching key returns true without prompting', () async {
      final storage = _InMemorySecureStorage();
      final prompt = _StubPrompt(decision: HostKeyDecision.trust);
      final verifier = SecureHostKeyVerifier(storage, prompt);
      await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );
      prompt.calls = 0;

      final ok = await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      expect(ok, isTrue);
      expect(prompt.calls, 0);
    });

    test('mismatch prompts; reject leaves prior key intact', () async {
      final storage = _InMemorySecureStorage();
      final accept = _StubPrompt(decision: HostKeyDecision.trust);
      final verifier1 = SecureHostKeyVerifier(storage, accept);
      await verifier1.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      final reject = _StubPrompt(decision: HostKeyDecision.reject);
      final verifier2 = SecureHostKeyVerifier(storage, reject);
      final ok = await verifier2.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:bb',
      );

      expect(ok, isFalse);
      expect(reject.calls, 1);
      final stored = await verifier2.loadTrustedKeys();
      expect(stored.single.fingerprint, 'MD5:aa');
    });

    test('mismatch accept replaces the stored fingerprint', () async {
      final storage = _InMemorySecureStorage();
      final accept = _StubPrompt(decision: HostKeyDecision.trust);
      final verifier = SecureHostKeyVerifier(storage, accept);
      await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      final ok = await verifier.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:bb',
      );

      expect(ok, isTrue);
      final stored = await verifier.loadTrustedKeys();
      expect(stored, hasLength(1));
      expect(stored.single.fingerprint, 'MD5:bb');
    });
  });

  group('HostKeyPromptCoordinator', () {
    test('queues requests and resolves them in order', () async {
      final coordinator = HostKeyPromptCoordinator();
      final r1 = _request('a');
      final r2 = _request('b');
      final f1 = coordinator.request(r1);
      final f2 = coordinator.request(r2);

      expect(coordinator.current, same(r1));
      coordinator.resolve(r1, HostKeyDecision.trust);
      expect(await f1, HostKeyDecision.trust);
      expect(coordinator.current, same(r2));
      coordinator.resolve(r2, HostKeyDecision.reject);
      expect(await f2, HostKeyDecision.reject);
      expect(coordinator.current, isNull);
    });

    test('dispose rejects pending prompts', () async {
      final coordinator = HostKeyPromptCoordinator();
      final pending = coordinator.request(_request('x'));
      coordinator.dispose();
      expect(await pending, HostKeyDecision.reject);
    });

    test(
      'rejectAll rejects queued prompts and clears current prompt',
      () async {
        final coordinator = HostKeyPromptCoordinator();
        final first = coordinator.request(_request('x'));
        final second = coordinator.request(_request('y'));

        coordinator.rejectAll();

        expect(await first, HostKeyDecision.reject);
        expect(await second, HostKeyDecision.reject);
        expect(coordinator.current, isNull);
      },
    );
  });

  group('AppLockController', () {
    test('unavailable device shows continue-anyway path', () async {
      final controller = AppLockController(_UnavailableAuthenticator());
      await controller.unlock();
      expect(controller.status, AppLockStatus.unavailable);
      controller.continueWithoutAuth();
      expect(controller.isUnlocked, isTrue);
    });

    test('cancelled auth keeps the app locked', () async {
      final controller = AppLockController(
        _ScriptedAuthenticator(AppAuthenticationResult.cancelled),
      );
      await controller.unlock();
      expect(controller.status, AppLockStatus.locked);
      expect(controller.message, isNotNull);
    });

    test('successful auth unlocks', () async {
      final controller = AppLockController(_AlwaysAuthenticates());
      await controller.unlock();
      expect(controller.isUnlocked, isTrue);
    });

    test('auth errors return to the locked state', () async {
      final controller = AppLockController(const _ThrowingAuthenticator());
      await controller.unlock();
      expect(controller.status, AppLockStatus.locked);
      expect(controller.message, isNotNull);
    });

    test('availability errors show the unavailable path', () async {
      final controller = AppLockController(
        const _ThrowingAuthenticator(throwFromCanAuthenticate: true),
      );
      await controller.unlock();
      expect(controller.status, AppLockStatus.unavailable);
    });
  });

  group('SftpEntry', () {
    SftpEntry withMode(String octal) => SftpEntry(
      name: 'f',
      path: '/f',
      kind: SftpEntryKind.file,
      permissions: int.parse(octal, radix: 8),
    );

    test('formats permission bits like ls', () {
      expect(withMode('755').permissionString, 'rwxr-xr-x');
      expect(withMode('644').permissionString, 'rw-r--r--');
      expect(withMode('000').permissionString, '---------');
    });

    test('directories and symlinks are navigable; files are not', () {
      expect(_entry(SftpEntryKind.directory).isNavigable, isTrue);
      expect(_entry(SftpEntryKind.symlink).isNavigable, isTrue);
      expect(_entry(SftpEntryKind.file).isNavigable, isFalse);
    });
  });

  group('SftpBrowserController', () {
    late _FakeSftpSession session;
    late SftpBrowserController controller;
    late _RecordingFileExport export;

    const dir = SftpEntry(
      name: 'docs',
      path: '/home/user/docs',
      kind: SftpEntryKind.directory,
    );
    const file = SftpEntry(
      name: 'a.txt',
      path: '/home/user/a.txt',
      kind: SftpEntryKind.file,
      size: 3,
    );

    setUp(() {
      session = _FakeSftpSession(
        home: '/home/user',
        tree: {
          '/home/user': [dir, file],
          '/home/user/docs': <SftpEntry>[],
        },
      );
      export = _RecordingFileExport();
      controller = SftpBrowserController(
        host: _buildHost('files'),
        repository: _FakeSftpRepository(session),
        fileExport: export,
      );
    });

    tearDown(() => controller.dispose());

    test('connect resolves the home directory and lists it', () async {
      await controller.connect();
      expect(controller.status, SftpBrowserStatus.ready);
      expect(controller.path, '/home/user');
      expect(controller.entries, hasLength(2));
      expect(controller.canGoUp, isTrue);
    });

    test('open navigates into a directory and goUp returns', () async {
      await controller.connect();
      await controller.open(dir);
      expect(controller.path, '/home/user/docs');
      await controller.goUp();
      expect(controller.path, '/home/user');
    });

    test('download reads the file and saves it to downloads', () async {
      await controller.connect();
      final location = await controller.download(file);
      expect(location, 'Downloads/a.txt');
      expect(export.saved.single.$1, 'a.txt');
    });

    test('download archives folders recursively', () async {
      session.tree['/home/user/docs'] = [
        const SftpEntry(
          name: 'nested.txt',
          path: '/home/user/docs/nested.txt',
          kind: SftpEntryKind.file,
          size: 3,
        ),
      ];

      await controller.connect();
      final location = await controller.download(dir);

      expect(location, 'Downloads/docs.tar');
      expect(export.saved.single.$1, 'docs.tar');
      expect(
        String.fromCharCodes(export.saved.single.$2),
        contains('nested.txt'),
      );
    });

    test('makeDirectory issues the join under the current path', () async {
      await controller.connect();
      await controller.makeDirectory('new');
      expect(session.madeDirectories.single, '/home/user/new');
    });

    test('uploads multiple files under the current path', () async {
      final tempDir = await Directory.systemTemp.createTemp('conduit_sftp_');
      addTearDown(() => tempDir.delete(recursive: true));
      final first = File('${tempDir.path}/one.txt');
      final second = File('${tempDir.path}/two.txt');
      await first.writeAsBytes([1, 2]);
      await second.writeAsBytes([3, 4, 5]);

      await controller.connect();
      await controller.uploadFiles([
        SftpUploadFile.local(localPath: first.path, name: 'one.txt', size: 2),
        SftpUploadFile.local(localPath: second.path, name: 'two.txt', size: 3),
      ]);

      expect(session.writtenFiles['/home/user/one.txt'], [1, 2]);
      expect(session.writtenFiles['/home/user/two.txt'], [3, 4, 5]);
      expect(session.listCalls['/home/user'], 2);
      expect(controller.transfer, isNull);
      expect(controller.busy, isFalse);
    });

    test(
      'search filters current folder entries by name and metadata',
      () async {
        await controller.connect();

        controller.setSearchQuery('txt');
        expect(controller.visibleEntries, [file]);

        controller.setSearchQuery('directory');
        expect(controller.visibleEntries, [dir]);

        controller.clearSearch();
        expect(controller.visibleEntries, [dir, file]);
      },
    );

    test(
      'sort keeps folders first and orders files by selected mode',
      () async {
        final older = SftpEntry(
          name: 'older.log',
          path: '/home/user/older.log',
          kind: SftpEntryKind.file,
          size: 200,
          modifiedAt: DateTime(2024, 1, 1),
        );
        final newer = SftpEntry(
          name: 'newer.log',
          path: '/home/user/newer.log',
          kind: SftpEntryKind.file,
          size: 100,
          modifiedAt: DateTime(2025, 1, 1),
        );
        session.tree['/home/user'] = [older, dir, newer];

        await controller.connect();
        controller.setSortMode(SftpSortMode.modified);
        expect(controller.visibleEntries, [dir, newer, older]);

        controller.setSortMode(SftpSortMode.size);
        expect(controller.visibleEntries, [dir, older, newer]);
      },
    );

    test('connect failure surfaces an error status', () async {
      final failing = SftpBrowserController(
        host: _buildHost('bad'),
        repository: _ThrowingSftpRepository(),
        fileExport: export,
      );
      addTearDown(failing.dispose);
      await failing.connect();
      expect(failing.status, SftpBrowserStatus.failed);
      expect(failing.errorMessage, isNotNull);
    });
  });
}

SftpEntry _entry(SftpEntryKind kind) =>
    SftpEntry(name: 'x', path: '/x', kind: kind);

SavedHost _buildHost(String id, {String username = 'user'}) {
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

HostKeyPromptRequest _request(String host) {
  return HostKeyPromptRequest(
    host: host,
    port: 22,
    type: 'ssh-rsa',
    fingerprint: 'MD5:aa',
    kind: HostKeyPromptKind.firstTrust,
  );
}

class _InMemoryThemePreferences implements ThemePreferencesRepository {
  ThemePreferences _preferences = const ThemePreferences(
    themeMode: ThemeMode.system,
    palette: AppPalette.catppuccin,
  );

  @override
  Future<ThemePreferences> load() async => _preferences;

  @override
  Future<void> save(ThemePreferences preferences) async {
    _preferences = preferences;
  }
}

class _AlwaysAuthenticates implements AppAuthenticator {
  @override
  Future<AppAuthenticationResult> authenticate() async =>
      AppAuthenticationResult.success;

  @override
  Future<bool> canAuthenticate() async => true;
}

class _UnavailableAuthenticator implements AppAuthenticator {
  @override
  Future<AppAuthenticationResult> authenticate() async =>
      AppAuthenticationResult.unavailable;

  @override
  Future<bool> canAuthenticate() async => false;
}

class _ScriptedAuthenticator implements AppAuthenticator {
  _ScriptedAuthenticator(this.result);

  final AppAuthenticationResult result;

  @override
  Future<AppAuthenticationResult> authenticate() async => result;

  @override
  Future<bool> canAuthenticate() async => true;
}

class _ThrowingAuthenticator implements AppAuthenticator {
  const _ThrowingAuthenticator({this.throwFromCanAuthenticate = false});

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

class _EmptyHostsRepository implements SavedHostsRepository {
  @override
  Future<List<SavedHost>> loadHosts() async => const [];

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async {}
}

class _FakeHostsRepository implements SavedHostsRepository {
  List<SavedHost> persisted = [];

  @override
  Future<List<SavedHost>> loadHosts() async => List.unmodifiable(persisted);

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async {
    persisted = List.of(hosts);
  }
}

class _NoNetworkTerminalRepository implements SshTerminalRepository {
  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) {
    throw StateError('This test does not open network connections.');
  }
}

class _CompletingTerminalRepository implements SshTerminalRepository {
  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    return _FakeTerminalSession();
  }
}

class _PendingTerminalRepository implements SshTerminalRepository {
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

class _FakeTerminalSession implements SshTerminalSession {
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

class _TrackableTerminalSession implements SshTerminalSession {
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

class _ImmediateTerminalRepository implements SshTerminalRepository {
  _ImmediateTerminalRepository(this._session);

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

class _RoamingTerminalSession
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

class _PredictiveTerminalSession
    implements SshTerminalSession, PredictiveTerminalSession {
  _PredictiveTerminalSession({
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

class _FakeNetworkConnectivity implements NetworkConnectivity {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  void emit() => _controller.add(null);

  @override
  Stream<void> get onNetworkChanged => _controller.stream;
}

class _StubPrompt implements HostKeyPrompt {
  _StubPrompt({required this.decision});

  final HostKeyDecision decision;
  int calls = 0;

  @override
  Future<HostKeyDecision> request(HostKeyPromptRequest request) async {
    calls += 1;
    return decision;
  }
}

class _NoopVerifier implements HostKeyVerifier {
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

class _NoNetworkSftpRepository implements SftpRepository {
  @override
  Future<SftpSession> connect(SavedHost host) {
    throw StateError('This test does not open SFTP connections.');
  }
}

class _FakeSftpRepository implements SftpRepository {
  _FakeSftpRepository(this.session);

  final _FakeSftpSession session;

  @override
  Future<SftpSession> connect(SavedHost host) async => session;
}

class _ThrowingSftpRepository implements SftpRepository {
  @override
  Future<SftpSession> connect(SavedHost host) async => throw StateError('boom');
}

class _FakeSftpSession implements SftpSession {
  _FakeSftpSession({required this.home, required this.tree});

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

class _RecordingFileExport implements FileExport {
  final List<(String, Uint8List)> saved = [];

  @override
  Future<String?> save(String fileName, Uint8List bytes) async {
    saved.add((fileName, bytes));
    return 'Downloads/$fileName';
  }
}

class _FakeCtapDevice extends CtapDevice {
  _FakeCtapDevice({required this.signature, required this.authData});

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

String _fakeSecurityKeyPem() {
  return OpenSSHSecurityKeyEd25519KeyPair(
    publicKey: Uint8List.fromList(List<int>.filled(32, 3)),
    application: 'ssh:',
    flags: 0x01,
    keyHandle: Uint8List.fromList([0xAA]),
    reserved: '',
  ).toPem();
}

class _InMemorySecureStorage extends FlutterSecureStorage {
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
