import 'dart:async';

import 'package:conduit/features/hosts/data/dartssh2_ssh_key_service.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/host_form_page.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
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

    test('rejects empty id, name, host, but allows empty username', () {
      expect(base.copyWith(id: '').isValid, isFalse);
      expect(base.copyWith(name: ' ').isValid, isFalse);
      expect(base.copyWith(host: '').isValid, isFalse);
      expect(base.copyWith(username: '').isValid, isTrue);
      expect(
        base
            .copyWith(
              username: '',
              authMethod: SshAuthMethod.external,
              password: '',
            )
            .isValid,
        isTrue,
      );
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
      expect(
        base.copyWith(authMethod: SshAuthMethod.external, password: '').isValid,
        isTrue,
      );
      expect(
        base
            .copyWith(
              authMethod: SshAuthMethod.hardwareKey,
              privateKey: '',
              hardwareKeys: const [
                HardwareKeyEntry(id: 'a', privateKey: 'stub'),
              ],
            )
            .isValid,
        isTrue,
      );
      expect(
        base
            .copyWith(
              authMethod: SshAuthMethod.hardwareKey,
              privateKey: '',
              hardwareKeys: const [HardwareKeyEntry(id: 'a', privateKey: ' ')],
            )
            .isValid,
        isFalse,
      );
    });
  });

  group('MoshPortRange', () {
    test('parses a single port', () {
      final range = MoshPortRange.tryParse('60001');
      expect(range?.first, 60001);
      expect(range?.last, 60001);
    });

    test('parses a range', () {
      final range = MoshPortRange.tryParse(' 60000:61000 ');
      expect(range?.first, 60000);
      expect(range?.last, 61000);
    });

    test('rejects malformed and out-of-range values', () {
      expect(MoshPortRange.tryParse(''), isNull);
      expect(MoshPortRange.tryParse('abc'), isNull);
      expect(MoshPortRange.tryParse('0'), isNull);
      expect(MoshPortRange.tryParse('65536'), isNull);
      expect(MoshPortRange.tryParse('61000:60000'), isNull);
      expect(MoshPortRange.tryParse('60000:'), isNull);
      expect(MoshPortRange.tryParse(':60000'), isNull);
      expect(MoshPortRange.tryParse('60000:61000:62000'), isNull);
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
        moshPorts: '60000:61000',
        externalAuthOfferKey: false,
        startTmuxOnConnect: true,
        tmuxPrefixKey: TmuxPrefixKey.controlA,
        tmuxSessionName: 'work',
        tmuxStartDirectory: '~/projects',
        snippets: const [
          TerminalSnippet(
            id: 'snippet:deploy',
            label: 'Deploy',
            text: 'deploy production',
            hidden: true,
          ),
        ],
        connectSnippetId: 'snippet:deploy',
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
      expect(decoded.moshPorts, original.moshPorts);
      expect(decoded.externalAuthOfferKey, original.externalAuthOfferKey);
      expect(decoded.predictiveEchoEnabled, original.predictiveEchoEnabled);
      expect(decoded.startTmuxOnConnect, original.startTmuxOnConnect);
      expect(decoded.tmuxPrefixKey, original.tmuxPrefixKey);
      expect(decoded.tmuxSessionName, original.tmuxSessionName);
      expect(decoded.tmuxStartDirectory, original.tmuxStartDirectory);
      expect(decoded.snippets, original.snippets);
      expect(decoded.connectSnippetId, original.connectSnippetId);
      expect(decoded.lastConnectedAt, original.lastConnectedAt);
    });

    test('invalid persisted mosh ports fall back to the default', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'password',
        'password': 'secret',
        'moshPorts': '70000:80000',
      });

      expect(decoded.moshPorts, isEmpty);
    });

    test('older saved hosts default to no tmux start with Ctrl-B', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Legacy Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'password',
        'password': 'secret',
      });

      expect(decoded.startTmuxOnConnect, isFalse);
      expect(decoded.tmuxPrefixKey, TmuxPrefixKey.controlB);
      expect(decoded.tmuxSessionName, defaultTmuxSessionName);
      expect(decoded.tmuxStartDirectory, isEmpty);
      expect(decoded.externalAuthOfferKey, isTrue);
    });

    test('legacy tmux start flag is still supported', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Legacy Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'password',
        'password': 'secret',
        'startTmuxOnConnect': true,
      });

      expect(decoded.startTmuxOnConnect, isTrue);
      expect(decoded.tmuxSessionName, defaultTmuxSessionName);
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

    test('round-trips multiple hardware keys', () {
      const original = SavedHost(
        id: 'id',
        name: 'Hardware Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.hardwareKey,
        hardwareKeys: [
          HardwareKeyEntry(
            id: 'a',
            privateKey: 'stub-a',
            label: 'work',
            passphrase: 'pw',
          ),
          HardwareKeyEntry(id: 'b', privateKey: 'stub-b', label: 'backup'),
        ],
      );

      final decoded = SavedHost.fromJson(original.toJson());

      expect(decoded.hardwareKeys, hasLength(2));
      expect(decoded.hardwareKeys.first.id, 'a');
      expect(decoded.hardwareKeys.first.label, 'work');
      expect(decoded.hardwareKeys.first.privateKey, 'stub-a');
      expect(decoded.hardwareKeys.first.passphrase, 'pw');
      expect(decoded.hardwareKeys.last.label, 'backup');
      expect(decoded.isValid, isTrue);
    });

    test('mirrors the first hardware key into the legacy stub fields', () {
      const host = SavedHost(
        id: 'id',
        name: 'Hardware Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.hardwareKey,
        hardwareKeys: [
          HardwareKeyEntry(id: 'a', privateKey: 'stub-a', passphrase: 'pw'),
          HardwareKeyEntry(id: 'b', privateKey: 'stub-b'),
        ],
      );

      final json = host.toJson();

      expect(json['privateKey'], 'stub-a');
      expect(json['passphrase'], 'pw');
    });

    test('migrates a legacy single-stub host to a hardware key entry', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Legacy Hardware Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'hardwareKey',
        'privateKey': 'legacy-stub',
        'passphrase': 'legacy-pw',
      });

      expect(decoded.hardwareKeys, hasLength(1));
      expect(decoded.hardwareKeys.single.privateKey, 'legacy-stub');
      expect(decoded.hardwareKeys.single.passphrase, 'legacy-pw');
      expect(decoded.isValid, isTrue);
    });

    test('ignores malformed hardware key entries', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Hardware Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'hardwareKey',
        'hardwareKeys': [
          'garbage',
          42,
          {'id': 'no-key'},
          {'id': 7, 'privateKey': 'wrong-id-type'},
          {'id': 'wrong-label', 'privateKey': 'stub', 'label': 3},
          {'id': 'ok', 'privateKey': 'stub-ok'},
        ],
      });

      expect(decoded.hardwareKeys, hasLength(2));
      expect(decoded.hardwareKeys.first.id, 'wrong-label');
      expect(decoded.hardwareKeys.first.label, isEmpty);
      expect(decoded.hardwareKeys.last.id, 'ok');
    });

    test('does not migrate legacy keys for other auth methods', () {
      final decoded = SavedHost.fromJson(const {
        'id': 'id',
        'name': 'Key Host',
        'host': 'example.com',
        'port': 22,
        'username': 'root',
        'authMethod': 'privateKey',
        'privateKey': 'normal-key',
      });

      expect(decoded.hardwareKeys, isEmpty);
      expect(decoded.privateKey, 'normal-key');
    });

    test('preserves external auth method without credentials', () {
      const original = SavedHost(
        id: 'id',
        name: 'External Host',
        host: 'example.com',
        port: 22,
        username: '',
        authMethod: SshAuthMethod.external,
      );

      final decoded = SavedHost.fromJson(original.toJson());

      expect(decoded.authMethod, SshAuthMethod.external);
      expect(decoded.password, isEmpty);
      expect(decoded.privateKey, isEmpty);
      expect(decoded.passphrase, isEmpty);
      expect(decoded.externalAuthOfferKey, isTrue);
      expect(decoded.endpoint, 'example.com:22');
      expect(decoded.isValid, isTrue);
    });

    test('preserves disabled temporary public key for external auth', () {
      const original = SavedHost(
        id: 'id',
        name: 'External Host',
        host: 'example.com',
        port: 22,
        username: '',
        authMethod: SshAuthMethod.external,
        externalAuthOfferKey: false,
      );

      final decoded = SavedHost.fromJson(original.toJson());

      expect(decoded.authMethod, SshAuthMethod.external);
      expect(decoded.externalAuthOfferKey, isFalse);
      expect(decoded.isValid, isTrue);
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
        fakeSecurityKeyPem(),
      );
      final listPosition =
          ((find.byType(Scrollable).evaluate().first as StatefulElement).state
                  as ScrollableState)
              .position;
      final addButton = find.text('Add machine');
      for (var i = 0; i < 40 && addButton.evaluate().isEmpty; i++) {
        listPosition.jumpTo(
          (listPosition.pixels + 200).clamp(0.0, listPosition.maxScrollExtent),
        );
        await tester.pump();
      }
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      listPosition.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        find.text('This is a hardware-key stub. Choose Hardware key instead.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a key summary for a recognized private key', (
      tester,
    ) async {
      final generated = const Dartssh2SshKeyService().generateEd25519(
        comment: 'me@conduit',
      );

      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));
      await tester.tap(find.text('Private key').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Private key'),
        generated.privateKeyPem,
      );
      await tester.pump();

      expect(find.text('Ed25519'), findsOneWidget);
      expect(find.text('me@conduit'), findsOneWidget);
      expect(find.text('View public key'), findsOneWidget);
      expect(find.text(generated.details.fingerprintSha256), findsOneWidget);
    });

    testWidgets('encrypted key without a passphrase asks for one on save', (
      tester,
    ) async {
      final generated = const Dartssh2SshKeyService().generateEd25519(
        passphrase: 'locked',
      );

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
        generated.privateKeyPem,
      );
      final listPosition =
          ((find.byType(Scrollable).evaluate().first as StatefulElement).state
                  as ScrollableState)
              .position;
      final addButton = find.text('Add machine');
      for (var i = 0; i < 40 && addButton.evaluate().isEmpty; i++) {
        listPosition.jumpTo(
          (listPosition.pixels + 200).clamp(0.0, listPosition.maxScrollExtent),
        );
        await tester.pump();
      }
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      listPosition.jumpTo(0);
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the key passphrase to unlock it.'),
        findsOneWidget,
      );
    });

    testWidgets('verifies an encrypted passphrase and unlocks the card', (
      tester,
    ) async {
      final generated = const Dartssh2SshKeyService().generateEd25519(
        comment: 'locked@conduit',
        passphrase: 'open me',
      );

      await tester.pumpWidget(
        const MaterialApp(home: HostFormPage(keyService: _SyncKeyService())),
      );
      await tester.tap(find.text('Private key').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Private key'),
        generated.privateKeyPem,
      );
      await tester.pump();
      expect(
        find.text(
          'This key is encrypted. Enter its passphrase below to unlock it.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Key passphrase'),
        'open me',
      );
      await tester.pump();
      expect(find.text('Checking passphrase…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Ed25519'), findsOneWidget);
      expect(find.text('locked@conduit'), findsOneWidget);
    });

    testWidgets('a stale verify result cannot overwrite a cleared passphrase', (
      tester,
    ) async {
      final service = _ControllableKeyService();
      final generated = const Dartssh2SshKeyService().generateEd25519(
        passphrase: 'secret',
      );
      const encryptedNotice =
          'This key is encrypted. Enter its passphrase below to unlock it.';

      await tester.pumpWidget(
        MaterialApp(home: HostFormPage(keyService: service)),
      );
      await tester.tap(find.text('Private key').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Private key'),
        generated.privateKeyPem,
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Key passphrase'),
        'secret',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(service.pending, 1);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Key passphrase'),
        '',
      );
      await tester.pump();
      expect(find.text(encryptedNotice), findsOneWidget);

      service.completeLast(const SshKeyInspection.wrongPassphrase());
      await tester.pump();

      expect(find.text(encryptedNotice), findsOneWidget);
      expect(
        find.text('That passphrase did not match this key.'),
        findsNothing,
      );
    });
  });

  group('HostFormPage hardware keys', () {
    Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
      final listPosition =
          ((find.byType(Scrollable).evaluate().first as StatefulElement).state
                  as ScrollableState)
              .position;
      listPosition.jumpTo(0);
      await tester.pump();
      for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
        listPosition.jumpTo(
          (listPosition.pixels + 200).clamp(0.0, listPosition.maxScrollExtent),
        );
        await tester.pump();
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> scrollToFinder(WidgetTester tester, Finder finder) async {
      final listPosition =
          ((find.byType(Scrollable).evaluate().first as StatefulElement).state
                  as ScrollableState)
              .position;
      listPosition.jumpTo(0);
      await tester.pump();
      for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
        listPosition.jumpTo(
          (listPosition.pixels + 200).clamp(0.0, listPosition.maxScrollExtent),
        );
        await tester.pump();
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    void mockClipboard(WidgetTester tester, String text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, Object?>{'text': text};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('requires at least one hardware key to save', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display name'),
        'Host',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Host or IP'),
        'example.com',
      );
      await tester.tap(find.text('Hardware key').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('No hardware keys yet'), findsOneWidget);

      await scrollToAndTap(tester, find.text('Add machine'));

      await scrollToFinder(tester, find.text('Add at least one hardware key.'));
      expect(find.text('Add at least one hardware key.'), findsOneWidget);
    });

    testWidgets('adopts a pasted stub when switching to hardware key', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));

      await tester.tap(find.text('Private key').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Private key'),
        fakeSecurityKeyPem(),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Hardware key').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hardware key').first);
      await tester.pumpAndSettle();

      expect(find.text('Hardware keys (1)'), findsOneWidget);
      expect(find.text('Hardware key 1'), findsOneWidget);
      expect(find.text('View public key'), findsOneWidget);
      expect(find.textContaining('No hardware keys yet'), findsNothing);
    });

    testWidgets('adds a key through the paste flow in the sheet', (
      tester,
    ) async {
      mockClipboard(tester, fakeSecurityKeyPem());
      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));

      await tester.tap(find.text('Hardware key').first);
      await tester.pumpAndSettle();
      await scrollToAndTap(tester, find.text('Add hardware key'));
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('Ed25519 SK'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Label'), 'backup');
      await tester.ensureVisible(find.text('Add key'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add key'));
      await tester.pumpAndSettle();

      expect(find.text('Hardware keys (1)'), findsOneWidget);
      expect(find.text('backup'), findsOneWidget);

      await scrollToAndTap(tester, find.text('Add hardware key'));
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(
        find.text('This key is already added to this host.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Add key'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('adds a key typed into the sheet input field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HostFormPage()));

      await tester.tap(find.text('Hardware key').first);
      await tester.pumpAndSettle();
      await scrollToAndTap(tester, find.text('Add hardware key'));

      await tester.enterText(
        find.widgetWithText(TextField, 'OpenSSH hardware key stub'),
        fakeSecurityKeyPem(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ed25519 SK'), findsOneWidget);

      await tester.ensureVisible(find.text('Add key'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add key'));
      await tester.pumpAndSettle();

      expect(find.text('Hardware keys (1)'), findsOneWidget);
    });

    testWidgets('shows a legacy single-stub host as one entry', (tester) async {
      final host = SavedHost(
        id: 'id',
        name: 'Legacy',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.hardwareKey,
        privateKey: fakeSecurityKeyPem(),
      );

      await tester.pumpWidget(MaterialApp(home: HostFormPage(host: host)));
      await tester.pumpAndSettle();

      expect(find.text('Hardware keys (1)'), findsOneWidget);
      expect(find.text('Hardware key 1'), findsOneWidget);
    });
  });

  group('HostsController', () {
    final older = DateTime.parse('2026-01-01T10:00:00Z');
    final newer = DateTime.parse('2026-01-02T10:00:00Z');

    test('upsert + load surfaces persisted hosts', () async {
      final repository = FakeHostsRepository();
      final controller = HostsController(repository);
      await controller.load();

      await controller.upsert(buildHost('a'));
      expect(controller.hosts, hasLength(1));
      expect(repository.persisted, hasLength(1));
    });

    test('markConnected uses the latest version of the host', () async {
      final repository = FakeHostsRepository();
      final controller = HostsController(repository);
      await controller.load();
      await controller.upsert(buildHost('a', username: 'old'));
      final stale = buildHost('a', username: 'old');
      await controller.upsert(buildHost('a', username: 'new'));

      await controller.markConnected(stale);

      final saved = repository.persisted.single;
      expect(saved.username, 'new');
      expect(saved.lastConnectedAt, isNotNull);
    });

    test('sorts by last connected by default', () async {
      final repository = FakeHostsRepository()
        ..persisted = [
          buildHost('a').copyWith(name: 'Alpha', lastConnectedAt: older),
          buildHost('b').copyWith(name: 'Beta'),
          buildHost('c').copyWith(name: 'Gamma', lastConnectedAt: newer),
        ];
      final controller = HostsController(repository);

      await controller.load();

      expect(controller.sortedHosts.map((host) => host.name), [
        'Gamma',
        'Alpha',
        'Beta',
      ]);
    });

    test('can keep a static name sort', () async {
      final repository = FakeHostsRepository()
        ..persistedSortMode = HostListSortMode.name
        ..persisted = [
          buildHost('c').copyWith(name: 'Gamma', lastConnectedAt: newer),
          buildHost('a').copyWith(name: 'Alpha', lastConnectedAt: older),
          buildHost('b').copyWith(name: 'Beta'),
        ];
      final controller = HostsController(repository);

      await controller.load();
      await controller.markConnected(repository.persisted.first);

      expect(controller.sortMode, HostListSortMode.name);
      expect(controller.sortedHosts.map((host) => host.name), [
        'Alpha',
        'Beta',
        'Gamma',
      ]);
    });

    test('can keep a static added sort', () async {
      final repository = FakeHostsRepository()
        ..persistedSortMode = HostListSortMode.added
        ..persisted = [
          buildHost('c').copyWith(name: 'Gamma', lastConnectedAt: newer),
          buildHost('a').copyWith(name: 'Alpha', lastConnectedAt: older),
          buildHost('b').copyWith(name: 'Beta'),
        ];
      final controller = HostsController(repository);

      await controller.load();
      await controller.markConnected(repository.persisted.first);

      expect(controller.sortMode, HostListSortMode.added);
      expect(controller.sortedHosts.map((host) => host.name), [
        'Gamma',
        'Alpha',
        'Beta',
      ]);
    });

    test('persists selected sort mode', () async {
      final repository = FakeHostsRepository();
      final controller = HostsController(repository);
      await controller.load();

      await controller.setSortMode(HostListSortMode.name);

      expect(repository.persistedSortMode, HostListSortMode.name);
      expect(controller.sortMode, HostListSortMode.name);
    });

    test('seeds manual order from the current arrangement', () async {
      final repository = FakeHostsRepository()
        ..persistedSortMode = HostListSortMode.name
        ..persisted = [
          buildHost('c').copyWith(name: 'Gamma'),
          buildHost('a').copyWith(name: 'Alpha'),
          buildHost('b').copyWith(name: 'Beta'),
        ];
      final controller = HostsController(repository);
      await controller.load();

      await controller.setSortMode(HostListSortMode.manual);

      expect(controller.sortedHosts.map((host) => host.name), [
        'Alpha',
        'Beta',
        'Gamma',
      ]);
      expect(repository.persistedManualOrder, ['a', 'b', 'c']);
    });

    test('reorders and persists the manual order', () async {
      final repository = FakeHostsRepository()
        ..persistedSortMode = HostListSortMode.manual
        ..persistedManualOrder = ['a', 'b', 'c']
        ..persisted = [
          buildHost('a').copyWith(name: 'Alpha'),
          buildHost('b').copyWith(name: 'Beta'),
          buildHost('c').copyWith(name: 'Gamma'),
        ];
      final controller = HostsController(repository);
      await controller.load();

      await controller.reorderManual(0, 2);

      expect(controller.sortedHosts.map((host) => host.name), [
        'Beta',
        'Gamma',
        'Alpha',
      ]);
      expect(repository.persistedManualOrder, ['b', 'c', 'a']);
    });

    test('appends newly added hosts to the end of the manual order', () async {
      final repository = FakeHostsRepository()
        ..persistedSortMode = HostListSortMode.manual
        ..persistedManualOrder = ['b', 'a']
        ..persisted = [
          buildHost('a').copyWith(name: 'Alpha'),
          buildHost('b').copyWith(name: 'Beta'),
        ];
      final controller = HostsController(repository);
      await controller.load();

      await controller.upsert(buildHost('c').copyWith(name: 'Gamma'));

      expect(controller.sortedHosts.map((host) => host.name), [
        'Beta',
        'Alpha',
        'Gamma',
      ]);
    });
  });
}

class _SyncKeyService implements SshKeyService {
  const _SyncKeyService();

  SshKeyService get _delegate => const Dartssh2SshKeyService();

  @override
  SshKeyInspection inspect(String pem, {String passphrase = ''}) =>
      _delegate.inspect(pem, passphrase: passphrase);

  @override
  Future<SshKeyInspection> verify(String pem, {String passphrase = ''}) =>
      Future.value(_delegate.inspect(pem, passphrase: passphrase));

  @override
  GeneratedSshKey generateEd25519({
    String comment = '',
    String passphrase = '',
  }) => _delegate.generateEd25519(comment: comment, passphrase: passphrase);
}

class _ControllableKeyService implements SshKeyService {
  final _delegate = const Dartssh2SshKeyService();
  final _completers = <Completer<SshKeyInspection>>[];

  int get pending => _completers.where((c) => !c.isCompleted).length;

  void completeLast(SshKeyInspection result) =>
      _completers.last.complete(result);

  @override
  SshKeyInspection inspect(String pem, {String passphrase = ''}) =>
      _delegate.inspect(pem, passphrase: passphrase);

  @override
  Future<SshKeyInspection> verify(String pem, {String passphrase = ''}) {
    final completer = Completer<SshKeyInspection>();
    _completers.add(completer);
    return completer.future;
  }

  @override
  GeneratedSshKey generateEd25519({
    String comment = '',
    String passphrase = '',
  }) => _delegate.generateEd25519(comment: comment, passphrase: passphrase);
}
