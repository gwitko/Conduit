import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/domain/ssh_password_interaction.dart';
// SSHUserInfoRequest is not exported by package:dartssh2.
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

// Servers with `AuthenticationMethods publickey,password` accept the key with
// partial success and then need a password. Key hosts must therefore offer
// password and keyboard-interactive handlers too.
void main() {
  SavedHost keyHost(SshAuthMethod method, {String password = ''}) => SavedHost(
    id: 'id',
    name: 'Host',
    host: ' arizone.example ',
    port: 22,
    username: ' ari ',
    authMethod: method,
    privateKey: 'key',
    password: password,
  );

  group('SshClientFactory password after key', () {
    for (final method in [
      SshAuthMethod.privateKey,
      SshAuthMethod.hardwareKey,
    ]) {
      test('${method.name}: prompts when no password is saved', () async {
        final requests = <SshPasswordPromptRequest>[];
        final factory = SshClientFactory(
          NoopVerifier(),
          passwordPrompt: (request) async {
            requests.add(request);
            return 'secret';
          },
        );

        final handler = factory.passwordRequestForTesting(keyHost(method));

        expect(handler, isNotNull);
        expect(await handler!(), 'secret');
        expect(requests, hasLength(1));
        expect(requests.single.username, 'ari');
        expect(requests.single.host, 'arizone.example');
        expect(requests.single.echo, isFalse);
      });

      test('${method.name}: uses a saved password without prompting', () async {
        var prompted = false;
        final factory = SshClientFactory(
          NoopVerifier(),
          passwordPrompt: (_) async {
            prompted = true;
            return 'other';
          },
        );
        final host = keyHost(method, password: 'saved');

        expect(await factory.passwordRequestForTesting(host)!(), 'saved');
        expect(
          await factory.userInfoRequestForTesting(host)!(
            SSHUserInfoRequest('', '', [
              SSHUserInfoPrompt('Password:', false),
            ]),
          ),
          ['saved'],
        );
        expect(prompted, isFalse);
      });
    }

    test('keyboard-interactive shows each server prompt', () async {
      final requests = <SshPasswordPromptRequest>[];
      final factory = SshClientFactory(
        NoopVerifier(),
        passwordPrompt: (request) async {
          requests.add(request);
          return request.echo ? 'visible' : 'hidden';
        },
      );

      final answers = await factory.userInfoRequestForTesting(
        keyHost(SshAuthMethod.hardwareKey),
      )!(
        SSHUserInfoRequest('', 'Second factor', [
          SSHUserInfoPrompt('Password:', false),
          SSHUserInfoPrompt('Code:', true),
        ]),
      );

      expect(answers, ['hidden', 'visible']);
      expect(requests.map((request) => request.prompt), [
        'Password:',
        'Code:',
      ]);
      expect(requests.first.instruction, 'Second factor');
    });

    test('keyboard-interactive with no prompts does not ask', () async {
      var prompted = false;
      final factory = SshClientFactory(
        NoopVerifier(),
        passwordPrompt: (_) async {
          prompted = true;
          return 'x';
        },
      );

      final answers = await factory.userInfoRequestForTesting(
        keyHost(SshAuthMethod.privateKey),
      )!(SSHUserInfoRequest('', '', []));

      expect(answers, isEmpty);
      expect(prompted, isFalse);
    });

    test('cancelling once stops later prompts on the same connection', () async {
      var prompts = 0;
      final factory = SshClientFactory(
        NoopVerifier(),
        passwordPrompt: (_) async {
          prompts++;
          return null;
        },
      );

      final handlers = factory.authHandlersForTesting(
        keyHost(SshAuthMethod.hardwareKey),
      );

      expect(await handlers.password!(), isNull);
      expect(
        await handlers.userInfo!(
          SSHUserInfoRequest('', '', [SSHUserInfoPrompt('Password:', false)]),
        ),
        isNull,
      );
      expect(prompts, 1);
    });

    test('password and external hosts are unchanged', () async {
      final factory = SshClientFactory(
        NoopVerifier(),
        passwordPrompt: (_) async => fail('must not prompt'),
      );
      const passwordHost = SavedHost(
        id: 'id',
        name: 'Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.password,
        password: 'pw',
      );
      const externalHost = SavedHost(
        id: 'id',
        name: 'Host',
        host: 'example.com',
        port: 22,
        username: 'root',
        authMethod: SshAuthMethod.external,
      );

      expect(await factory.passwordRequestForTesting(passwordHost)!(), 'pw');
      expect(factory.passwordRequestForTesting(externalHost), isNull);
      expect(factory.userInfoRequestForTesting(externalHost), isNull);
    });
  });
}
