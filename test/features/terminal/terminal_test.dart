import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:conduit/core/app_failure.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/openssh_security_key_signer.dart';
import 'package:conduit/features/terminal/data/secure_host_key_verifier.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_coordinator.dart';
import 'package:conduit/features/terminal/presentation/terminal_keyboard_bar.dart';
import 'package:conduit/features/terminal/presentation/terminal_keyboard_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/widgets/terminal_surface.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  group('TerminalSessionController', () {
    test('builds quoted tmux startup command when enabled', () {
      final controller = TerminalSessionController(
        host: buildHost('tmux-create').copyWith(
          startTmuxOnConnect: true,
          tmuxSessionName: 'work session',
          tmuxStartDirectory: "~/client's app",
        ),
        repository: ImmediateTerminalRepository(TrackableTerminalSession()),
      );
      addTearDown(controller.dispose);

      expect(
        controller.buildTmuxCommandForTesting(),
        "tmux new-session -A -s 'work session' -c '~/client'\\''s app'\r",
      );
    });

    test('does not build a tmux startup command when disabled', () {
      final controller = TerminalSessionController(
        host: buildHost('tmux-off'),
        repository: ImmediateTerminalRepository(TrackableTerminalSession()),
      );
      addTearDown(controller.dispose);

      expect(controller.buildTmuxCommandForTesting(), isNull);
    });

    test('ignores a connection that completes after disconnect', () async {
      final repository = PendingTerminalRepository();
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('late'),
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
      final session = FakeRoamingTerminalSession();
      final connectivity = FakeNetworkConnectivity();
      final controller = TerminalSessionController(
        host: buildHost('roam'),
        repository: ImmediateTerminalRepository(session),
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
      final session = TrackableTerminalSession();
      final connectivity = FakeNetworkConnectivity();
      final controller = TerminalSessionController(
        host: buildHost('ssh'),
        repository: ImmediateTerminalRepository(session),
        connectivity: connectivity,
      );

      await controller.connect();
      connectivity.emit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, TerminalConnectionStatus.connected);

      controller.dispose();
    });

    test('keeps predictive overlays until confirmed output arrives', () async {
      final session = FakePredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('predict'),
        repository: ImmediateTerminalRepository(session),
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
        final session = FakePredictiveTerminalSession(smoothedRtt: null);
        final controller = TerminalSessionController(
          host: buildHost('predict-no-rtt'),
          repository: ImmediateTerminalRepository(session),
          predictiveEchoEnabled: true,
        );

        await controller.connect();
        controller.sendText('x');

        expect(controller.overlays.map((overlay) => overlay.text).join(), 'x');

        controller.dispose();
      },
    );

    test('leaves predictive echo disabled by default', () async {
      final session = FakePredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('predict-default-off'),
        repository: ImmediateTerminalRepository(session),
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
        final session = FakePredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: buildHost('predict-confirmed'),
          repository: ImmediateTerminalRepository(session),
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
        final session = FakePredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: buildHost('predict-stale'),
          repository: ImmediateTerminalRepository(session),
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
      final session = FakePredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('predict-backspace'),
        repository: ImmediateTerminalRepository(session),
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

    testWidgets('repeats held keyboard row navigation keys', (tester) async {
      final controller = _RecordingTerminalSessionController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalKeyboardBar(
              controller: controller,
              focusNode: focusNode,
              palette: AppPalette.catppuccin,
              brightness: Brightness.dark,
              items: const [
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowDown),
              ],
              fullscreen: false,
              onToggleFullscreen: () {},
              onEnterTmuxScrollMode: () {},
              onExitTmuxScrollMode: () {},
              tmuxPrefixKey: TmuxPrefixKey.controlB,
              tmuxScrollMode: false,
            ),
          ),
        ),
      );

      final key = find.byIcon(Icons.keyboard_arrow_down_rounded);
      final gesture = await tester.press(key);

      expect(controller.sentKeys, isEmpty);

      await tester.pump(const Duration(milliseconds: 249));
      expect(controller.sentKeys, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.sentKeys, [TerminalKey.arrowDown]);

      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.sentKeys, [
        TerminalKey.arrowDown,
        TerminalKey.arrowDown,
      ]);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 180));
      expect(controller.sentKeys, [
        TerminalKey.arrowDown,
        TerminalKey.arrowDown,
      ]);
    });

    testWidgets('does not send a keyboard row key while scrolling', (
      tester,
    ) async {
      final controller = _RecordingTerminalSessionController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalKeyboardBar(
              controller: controller,
              focusNode: focusNode,
              palette: AppPalette.catppuccin,
              brightness: Brightness.dark,
              items: const [
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.control),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlC),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlD),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxPrefix),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxMenu),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.pageDown),
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowRight),
              ],
              fullscreen: false,
              onToggleFullscreen: () {},
              onEnterTmuxScrollMode: () {},
              onExitTmuxScrollMode: () {},
              tmuxPrefixKey: TmuxPrefixKey.controlB,
              tmuxScrollMode: false,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('^C')),
      );
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await gesture.up();

      expect(controller.sentControlKeys, isEmpty);
      expect(controller.sentKeys, isEmpty);
      expect(controller.sentText, isEmpty);

      final toggleGesture = await tester.startGesture(
        tester.getCenter(find.text('Ctrl')),
      );
      await toggleGesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await toggleGesture.up();

      expect(controller.keyboard.ctrl, isFalse);
    });

    testWidgets('sends custom keyboard row items', (tester) async {
      final controller = _RecordingTerminalSessionController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalKeyboardBar(
              controller: controller,
              focusNode: focusNode,
              palette: AppPalette.catppuccin,
              brightness: Brightness.dark,
              items: const [
                TerminalKeyboardItem(
                  id: 'custom:text',
                  kind: TerminalKeyboardItemKind.customText,
                  label: 'gs',
                  text: 'git status',
                  submit: true,
                ),
                TerminalKeyboardItem(
                  id: 'custom:ctrl',
                  kind: TerminalKeyboardItemKind.customControl,
                  label: 'C-a',
                  controlKey: 'A',
                ),
              ],
              fullscreen: false,
              onToggleFullscreen: () {},
              onEnterTmuxScrollMode: () {},
              onExitTmuxScrollMode: () {},
              tmuxPrefixKey: TmuxPrefixKey.controlB,
              tmuxScrollMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('gs'));
      await tester.tap(find.text('C-a'));

      expect(controller.sentText, ['git status\r']);
      expect(controller.sentControlKeys, [TerminalKey.keyA]);
    });

    testWidgets('tmux scroll key enters scrollback mode', (tester) async {
      final controller = _RecordingTerminalSessionController();
      final focusNode = FocusNode();
      var enteredScrollMode = false;
      var exitedScrollMode = false;
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      Widget buildBar({required bool tmuxScrollMode}) => MaterialApp(
        home: Scaffold(
          body: TerminalKeyboardBar(
            controller: controller,
            focusNode: focusNode,
            palette: AppPalette.catppuccin,
            brightness: Brightness.dark,
            items: const [
              TerminalKeyboardItem.builtIn(
                TerminalKeyboardAction.tmuxScrollback,
              ),
            ],
            fullscreen: false,
            onToggleFullscreen: () {},
            onEnterTmuxScrollMode: () => enteredScrollMode = true,
            onExitTmuxScrollMode: () => exitedScrollMode = true,
            tmuxPrefixKey: TmuxPrefixKey.controlB,
            tmuxScrollMode: tmuxScrollMode,
          ),
        ),
      );

      await tester.pumpWidget(buildBar(tmuxScrollMode: false));
      await tester.tap(find.text('Scroll'));

      expect(controller.sentControlKeys, [TerminalKey.keyB]);
      expect(controller.sentText, ['[']);
      expect(enteredScrollMode, isTrue);

      await tester.pumpWidget(buildBar(tmuxScrollMode: true));
      await tester.tap(find.text('Scroll'));

      expect(controller.sentText, ['[', 'q']);
      expect(exitedScrollMode, isTrue);
    });

    testWidgets('tmux scroll mode drags without visible overlay', (
      tester,
    ) async {
      final controller = _RecordingTerminalSessionController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalSurface(
              session: controller,
              palette: AppPalette.catppuccin,
              brightness: Brightness.dark,
              fontFamily: 'monospace',
              fontSize: 14,
              onFontSizeChanged: (_) {},
              predictiveEchoEnabled: false,
              focusNode: focusNode,
              tmuxScrollMode: true,
              onExitTmuxScrollMode: () {},
            ),
          ),
        ),
      );

      expect(find.text('tmux scroll'), findsNothing);
      expect(find.text('Exit'), findsNothing);

      await tester.drag(find.byType(TerminalSurface), const Offset(0, 84));
      await tester.pump();

      expect(controller.sentKeys, isNotEmpty);
      expect(controller.sentKeys, everyElement(TerminalKey.arrowUp));
      expect(controller.sentKeys, isNot(contains(TerminalKey.pageUp)));
      expect(controller.sentKeys, isNot(contains(TerminalKey.pageDown)));

      await tester.pump(const Duration(milliseconds: 250));
    });

    test('keyboard input clears toggled row modifiers after one key', () {
      final handler = _RecordingInputHandler();
      final keyboard = TerminalKeyboardController(handler)..ctrl = true;
      final terminal = Terminal();

      final output = keyboard(
        TerminalKeyboardEvent(
          key: TerminalKey.keyC,
          shift: false,
          ctrl: false,
          alt: false,
          state: terminal,
          altBuffer: false,
          platform: TerminalTargetPlatform.unknown,
        ),
      );

      expect(output, 'ok');
      expect(handler.events.single.ctrl, isTrue);
      expect(keyboard.ctrl, isFalse);
    });

    test('can disable predictive overlays while keeping mosh input', () async {
      final session = FakePredictiveTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('predict-off'),
        repository: ImmediateTerminalRepository(session),
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

        final session = FakePredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: buildHost('ios-enter'),
          repository: ImmediateTerminalRepository(session),
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

        final session = FakePredictiveTerminalSession();
        final controller = TerminalSessionController(
          host: buildHost('ios-mixed-enter'),
          repository: ImmediateTerminalRepository(session),
        );
        addTearDown(controller.dispose);

        await controller.connect();
        controller.sendKey(TerminalKey.enter);
        controller.sendText('\n');

        expect(session.sent.map(String.fromCharCodes), ['\r']);
      },
    );
  });

  group('OpenSSH security key signer', () {
    test(
      'security key PIN prompts use the latest registered handler',
      () async {
        Future<String?> first(SecurityKeyPinRequest request) async => 'first';
        Future<String?> second(SecurityKeyPinRequest request) async {
          expect(request.retriesRemaining, 2);
          return 'second';
        }

        SecurityKeyInteraction.instance.registerPinPrompt(first);
        SecurityKeyInteraction.instance.registerPinPrompt(second);
        addTearDown(() {
          SecurityKeyInteraction.instance.unregisterPinPrompt(second);
          SecurityKeyInteraction.instance.unregisterPinPrompt(first);
        });

        expect(
          await SecurityKeyInteraction.instance.requestPin(retriesRemaining: 2),
          'second',
        );

        SecurityKeyInteraction.instance.unregisterPinPrompt(second);
        expect(await SecurityKeyInteraction.instance.requestPin(), 'first');
      },
    );

    test('converts CTAP ECDSA assertion into OpenSSH sk signature', () async {
      final device = FakeCtapDevice(
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
      final device = FakeCtapDevice(
        signature: rawSignature,
        authData: [...List<int>.filled(32, 0), 0x05, 0x00, 0x00, 0x00, 0x0A],
      );
      final signer = OpenSshSecurityKeySigner(openDevice: () async => device);
      final keyPair = signer.attach([
        OpenSSHSecurityKeyEd25519KeyPair(
          publicKey: Uint8List.fromList(List<int>.filled(32, 0x01)),
          application: 'ssh:',
          flags: 0x01,
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

  group('SshClientFactory host key fingerprints', () {
    test('formats raw MD5 digest bytes as OpenSSH MD5 text', () {
      final factory = SshClientFactory(NoopVerifier());

      final fingerprint = factory.formatFingerprintForTesting(
        Uint8List.fromList([0x37, 0x9e, 0x7b, 0x91]),
      );

      expect(fingerprint, 'MD5:37:9e:7b:91');
    });

    test('passes through textual SHA256 fingerprints without hex encoding', () {
      final factory = SshClientFactory(NoopVerifier());

      final fingerprint = factory.formatFingerprintForTesting(
        Uint8List.fromList(utf8.encode('SHA256:abc')),
      );

      expect(fingerprint, 'SHA256:abc');
    });
  });

  group('SshClientFactory hardware key identities', () {
    test('rejects security key stubs for private key auth', () {
      final factory = SshClientFactory(
        NoopVerifier(),
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
        NoopVerifier(),
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
        NoopVerifier(),
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

  group('SshClientFactory external auth', () {
    test('uses only an ephemeral public key identity', () {
      final factory = SshClientFactory(NoopVerifier());
      const host = SavedHost(
        id: 'id',
        name: 'Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.external,
        forwardAgent: true,
      );

      final identities = factory.identitiesForTesting(host);

      expect(identities, hasLength(1));
      expect(identities!.single, isA<OpenSSHEd25519KeyPair>());
      expect(factory.agentHandlerForTesting(host), isNull);
      expect(factory.passwordRequestForTesting(host), isNull);
      expect(factory.userInfoRequestForTesting(host), isNull);
    });

    test('can use pure none auth without an ephemeral identity', () {
      final factory = SshClientFactory(NoopVerifier());
      const host = SavedHost(
        id: 'id',
        name: 'Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.external,
        externalAuthOfferKey: false,
        forwardAgent: true,
      );

      expect(factory.identitiesForTesting(host), isNull);
      expect(factory.agentHandlerForTesting(host), isNull);
      expect(factory.passwordRequestForTesting(host), isNull);
      expect(factory.userInfoRequestForTesting(host), isNull);
    });
  });

  group('SshClientFactory agent forwarding', () {
    SshClientFactory privateKeyFactory() => SshClientFactory(
      NoopVerifier(),
      keyPairParser: (_, _) => [
        OpenSSHEd25519KeyPair(
          Uint8List.fromList(List<int>.filled(32, 1)),
          Uint8List.fromList(List<int>.filled(64, 2)),
          'normal key',
        ),
      ],
    );

    SshClientFactory hardwareKeyFactory() => SshClientFactory(
      NoopVerifier(),
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

    test('no handler for password auth', () {
      final factory = privateKeyFactory();
      expect(
        factory.agentHandlerForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.password,
            password: 'secret',
            forwardAgent: true,
          ),
        ),
        isNull,
      );
    });

    test('no handler when forwarding disabled', () {
      final factory = privateKeyFactory();
      expect(
        factory.agentHandlerForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.privateKey,
            privateKey: 'normal openssh key',
          ),
        ),
        isNull,
      );
    });

    test('attaches key-pair agent for private key auth', () {
      final factory = privateKeyFactory();
      expect(
        factory.agentHandlerForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.privateKey,
            privateKey: 'normal openssh key',
            forwardAgent: true,
          ),
        ),
        isA<SSHKeyPairAgent>(),
      );
    });

    test('attaches key-pair agent for hardware key auth', () {
      final factory = hardwareKeyFactory();
      expect(
        factory.agentHandlerForTesting(
          const SavedHost(
            id: 'id',
            name: 'Host',
            host: 'example.com',
            port: 22,
            username: 'root',
            authMethod: SshAuthMethod.hardwareKey,
            privateKey: 'openssh sk key',
            forwardAgent: true,
          ),
        ),
        isA<SSHKeyPairAgent>(),
      );
    });
  });

  group('SecureHostKeyVerifier', () {
    test('first connection prompts and trusts on accept', () async {
      final storage = InMemorySecureStorage();
      final prompt = StubPrompt(decision: HostKeyDecision.trust);
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
      final storage = InMemorySecureStorage();
      final prompt = StubPrompt(decision: HostKeyDecision.reject);
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
      final storage = InMemorySecureStorage();
      final prompt = StubPrompt(decision: HostKeyDecision.trust);
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
      final storage = InMemorySecureStorage();
      final accept = StubPrompt(decision: HostKeyDecision.trust);
      final verifier1 = SecureHostKeyVerifier(storage, accept);
      await verifier1.verify(
        host: 'a',
        port: 22,
        type: 'ssh-rsa',
        fingerprint: 'MD5:aa',
      );

      final reject = StubPrompt(decision: HostKeyDecision.reject);
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
      final storage = InMemorySecureStorage();
      final accept = StubPrompt(decision: HostKeyDecision.trust);
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

    test(
      'loadTrustedKeys repairs fingerprints polluted by SHA256 text bytes',
      () async {
        final storage = InMemorySecureStorage();
        final verifier = SecureHostKeyVerifier(
          storage,
          StubPrompt(decision: HostKeyDecision.trust),
        );
        await storage.write(
          key: 'conduit.trusted_host_keys.v1',
          value: jsonEncode([
            HostKeyRecord(
              host: 'bad',
              port: 22,
              type: 'ssh-ed25519',
              fingerprint: 'MD5:53:48:41:32:35:36:3a:61:62:63',
              trustedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ).toJson(),
            HostKeyRecord(
              host: 'good',
              port: 22,
              type: 'ssh-ed25519',
              fingerprint: 'MD5:37:9e:7b:91',
              trustedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ).toJson(),
          ]),
        );

        final records = await verifier.loadTrustedKeys();

        expect(records, hasLength(1));
        expect(records.single.host, 'good');
        final persisted =
            jsonDecode(
                  (await storage.read(key: 'conduit.trusted_host_keys.v1'))!,
                )
                as List<Object?>;
        expect(persisted, hasLength(1));
      },
    );

    test(
      'polluted stored fingerprint reconnect prompts as first trust',
      () async {
        final storage = InMemorySecureStorage();
        await storage.write(
          key: 'conduit.trusted_host_keys.v1',
          value: jsonEncode([
            HostKeyRecord(
              host: 'a',
              port: 22,
              type: 'ssh-ed25519',
              fingerprint: 'MD5:53:48:41:32:35:36:3a:61:62:63',
              trustedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ).toJson(),
          ]),
        );
        final prompt = CapturingPrompt(decision: HostKeyDecision.reject);
        final verifier = SecureHostKeyVerifier(storage, prompt);

        final ok = await verifier.verify(
          host: 'a',
          port: 22,
          type: 'ssh-ed25519',
          fingerprint: 'MD5:37:9e:7b:91',
        );

        expect(ok, isFalse);
        expect(prompt.requests.single.kind, HostKeyPromptKind.firstTrust);
        expect(prompt.requests.single.existing, isNull);
      },
    );
  });

  group('HostKeyPromptCoordinator', () {
    test('queues requests and resolves them in order', () async {
      final coordinator = HostKeyPromptCoordinator();
      final r1 = request('a');
      final r2 = request('b');
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
      final pending = coordinator.request(request('x'));
      coordinator.dispose();
      expect(await pending, HostKeyDecision.reject);
    });

    test(
      'rejectAll rejects queued prompts and clears current prompt',
      () async {
        final coordinator = HostKeyPromptCoordinator();
        final first = coordinator.request(request('x'));
        final second = coordinator.request(request('y'));

        coordinator.rejectAll();

        expect(await first, HostKeyDecision.reject);
        expect(await second, HostKeyDecision.reject);
        expect(coordinator.current, isNull);
      },
    );
  });
}

class _RecordingTerminalSessionController extends TerminalSessionController {
  _RecordingTerminalSessionController()
    : super(
        host: buildHost('repeat'),
        repository: NoNetworkTerminalRepository(),
      );

  final List<TerminalKey> sentKeys = <TerminalKey>[];
  final List<TerminalKey> sentControlKeys = <TerminalKey>[];
  final List<String> sentText = <String>[];

  @override
  void sendKey(TerminalKey key) {
    sentKeys.add(key);
    keyboard.clearModifiers();
  }

  @override
  void sendControl(TerminalKey key) {
    sentControlKeys.add(key);
    keyboard.clearModifiers();
  }

  @override
  void sendText(String text) {
    sentText.add(text);
    keyboard.clearModifiers();
  }
}

class _RecordingInputHandler extends TerminalInputHandler {
  final List<TerminalKeyboardEvent> events = <TerminalKeyboardEvent>[];

  @override
  String? call(TerminalKeyboardEvent event) {
    events.add(event);
    return 'ok';
  }
}
