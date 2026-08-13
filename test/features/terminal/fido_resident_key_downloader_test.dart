import 'package:cbor/cbor.dart';
import 'package:conduit/features/terminal/data/fido_resident_key_downloader.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

const credentialManagementPreviewCommand = 0x41;

CtapResponse<List<int>> ctapOk(Map<Object?, Object?> map) => CtapResponse(
  CtapStatusCode.ctap1ErrSuccess.value,
  cbor.encode(CborValue(map)),
);

CtapResponse<List<int>> ctapStatus(CtapStatusCode status) =>
    CtapResponse(status.value, const []);

CtapResponse<List<int>> infoResponse(
  Map<Object?, Object?> options, {
  List<int> pinProtocols = const [1],
}) => ctapOk({
  AuthenticatorInfo.versionsIdx: ['FIDO_2_0'],
  AuthenticatorInfo.aaguidIdx: CborBytes(List<int>.filled(16, 0)),
  AuthenticatorInfo.optionsIdx: options,
  AuthenticatorInfo.pinUvAuthProtocolsIdx: pinProtocols,
});

int credMgmtSubCommandOf(List<int> command) {
  final request = cbor.decode(command.sublist(1)).toObject() as Map;
  return request[CredentialManagementRequest.subCmdIdx] as int;
}

Map<Object?, Object?>? credMgmtParamsOf(List<int> command) {
  final request = cbor.decode(command.sublist(1)).toObject() as Map;
  return (request[CredentialManagementRequest.paramsIdx] as Map?)
      ?.cast<Object?, Object?>();
}

List<int>? credMgmtPinUvAuthParamOf(List<int> command) {
  final request = cbor.decode(command.sublist(1)).toObject() as Map;
  return (request[CredentialManagementRequest.pinUvAuthParamIdx] as List?)
      ?.cast<int>();
}

Map<Object?, Object?> rpEntry(String rpId) => {
  CredentialManagementResponse.rpIdx: {'id': rpId},
  CredentialManagementResponse.rpIdHashIdx: CborBytes(rpIdHashOf(rpId)),
};

List<int> rpIdHashOf(String rpId) =>
    List<int>.generate(32, (index) => (rpId.hashCode + index) & 0xff);

Map<Object?, Object?> ed25519PublicKey(List<int> x) => {
  1: 1, // kty: OKP
  3: -8, // alg: EdDSA
  -1: 6, // crv: Ed25519
  -2: CborBytes(x),
};

Map<Object?, Object?> es256PublicKey(List<int> x, List<int> y) => {
  1: 2, // kty: EC2
  3: -7, // alg: ES256
  -1: 1, // crv: P-256
  -2: CborBytes(x),
  -3: CborBytes(y),
};

Map<Object?, Object?> credentialEntry({
  required List<int> credentialId,
  required Map<Object?, Object?> publicKey,
  String userName = 'openssh',
  int? totalCredentials,
  int credProtect = 0x01,
}) => {
  CredentialManagementResponse.userIdx: {
    'id': CborBytes(const [0x0F]),
    'name': userName,
  },
  CredentialManagementResponse.credentialIdIdx: {
    'type': 'public-key',
    'id': CborBytes(credentialId),
  },
  CredentialManagementResponse.publicKeyIdx: publicKey,
  CredentialManagementResponse.totalCredentialsIdx: ?totalCredentials,
  CredentialManagementResponse.credProtectIdx: credProtect,
};

/// Serves scripted per-RP credentials over the credential-management command,
/// tracking enumeration cursors like a real authenticator.
class CredMgmtResponder {
  CredMgmtResponder({
    required this.rps,
    this.command = 0x0A,
    this.pinProtocols = const [1],
    Map<Object?, Object?>? infoOptions,
  }) : infoOptions = infoOptions ?? {'clientPin': true, 'credMgmt': true};

  final int command;
  final List<int> pinProtocols;
  final Map<Object?, Object?> infoOptions;

  /// rpId -> scripted credential entries.
  final Map<String, List<Map<Object?, Object?>>> rps;

  final commands = <List<int>>[];
  var _rpCursor = 0;
  List<Map<Object?, Object?>>? _remainingCredentials;

  CtapResponse<List<int>>? call(List<int> command) {
    if (command.first == Ctap2Commands.getInfo.value) {
      return infoResponse(infoOptions, pinProtocols: pinProtocols);
    }
    if (command.first != this.command) {
      return null;
    }
    commands.add(List.of(command));
    final subCommand = credMgmtSubCommandOf(command);
    if (subCommand == CredentialManagementSubCommand.enumerateRpsBegin.value) {
      _rpCursor = 0;
      if (rps.isEmpty) {
        return ctapStatus(CtapStatusCode.ctap2ErrNoCredentials);
      }
      return ctapOk({
        ...rpEntry(rps.keys.first),
        CredentialManagementResponse.totalRPsIdx: rps.length,
      });
    }
    if (subCommand ==
        CredentialManagementSubCommand.enumerateRpsGetNextRp.value) {
      _rpCursor++;
      return ctapOk(rpEntry(rps.keys.elementAt(_rpCursor)));
    }
    if (subCommand ==
        CredentialManagementSubCommand.enumerateCredentialsBegin.value) {
      final requestedHash =
          (credMgmtParamsOf(
                    command,
                  )![CredentialManagementSubCommandParams.rpIdHash.value]
                  as List)
              .cast<int>();
      final rpId = rps.keys.firstWhere(
        (id) => _sameBytes(rpIdHashOf(id), requestedHash),
      );
      final credentials = rps[rpId]!;
      if (credentials.isEmpty) {
        return ctapStatus(CtapStatusCode.ctap2ErrNoCredentials);
      }
      _remainingCredentials = credentials.sublist(1);
      return ctapOk({
        ...credentials.first,
        CredentialManagementResponse.totalCredentialsIdx: credentials.length,
      });
    }
    if (subCommand ==
        CredentialManagementSubCommand
            .enumerateCredentialsGetNextCredential
            .value) {
      final next = _remainingCredentials!.removeAt(0);
      return ctapOk(next);
    }
    return ctapStatus(CtapStatusCode.ctap1ErrInvalidCommand);
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

void main() {
  FidoResidentKeyDownloader downloaderFor(
    FakeCtapDevice device, {
    String pin = '1234',
    List<String?>? pins,
    List<String>? statuses,
    List<int?>? promptedRetries,
  }) {
    var pinRequests = 0;
    return FidoResidentKeyDownloader(
      openDevice: () async => device,
      onStatus: statuses?.add,
      onPinRequest: ({int? retriesRemaining}) async {
        promptedRetries?.add(retriesRemaining);
        final index = pinRequests++;
        if (pins != null) {
          return index < pins.length ? pins[index] : null;
        }
        return pin;
      },
    );
  }

  group('FidoResidentKeyDownloader', () {
    test('downloads an ed25519 resident key as an OpenSSH stub', () async {
      final x = List<int>.generate(32, (index) => index + 1);
      final responder = CredMgmtResponder(
        rps: {
          'ssh:demo': [
            credentialEntry(
              credentialId: const [0xAA, 0xBB],
              publicKey: ed25519PublicKey(x),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      );

      final keys = await downloaderFor(device).download();

      expect(keys, hasLength(1));
      final key = keys.single;
      expect(key.algorithm, 'ed25519-sk');
      expect(key.application, 'ssh:demo');
      expect(key.suggestedLabel, 'demo');
      expect(key.requiresUserVerification, isFalse);

      final keyPair = key.keyPair as OpenSSHSecurityKeyEd25519KeyPair;
      expect(keyPair.publicKey, x);
      expect(keyPair.keyHandle, const [0xAA, 0xBB]);
      expect(keyPair.flags, 0x21);
      expect(keyPair.reserved, '');
      expect(key.fingerprintSha256, startsWith('SHA256:'));

      final authParam = credMgmtPinUvAuthParamOf(responder.commands.first)!;
      expect(authParam, hasLength(16));

      final reparsed =
          SSHKeyPair.fromPem(key.toPem()).single
              as OpenSSHSecurityKeyEd25519KeyPair;
      expect(reparsed.publicKey, x);
      expect(reparsed.application, 'ssh:demo');
      expect(reparsed.flags, 0x21);
      expect(reparsed.keyHandle, const [0xAA, 0xBB]);
    });

    test('sends the full pinUvAuthParam under PIN protocol 2', () async {
      final responder = CredMgmtResponder(
        pinProtocols: const [2, 1],
        rps: {
          'ssh:v2': [
            credentialEntry(
              credentialId: const [0x55],
              publicKey: ed25519PublicKey(List<int>.filled(32, 8)),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        // Protocol 2 token ciphertext: 16-byte IV + 32-byte token.
        pinTokenBytes: 48,
        respond: responder.call,
      );

      final keys = await downloaderFor(device).download();

      expect(keys, hasLength(1));
      expect(keys.single.application, 'ssh:v2');
      final authParam = credMgmtPinUvAuthParamOf(responder.commands.first)!;
      expect(authParam, hasLength(32));
    });

    test('distinguishes standard SSH credentials by fingerprint', () async {
      final responder = CredMgmtResponder(
        rps: {
          'ssh:': [
            credentialEntry(
              credentialId: const [0x01],
              publicKey: ed25519PublicKey(List<int>.filled(32, 1)),
            ),
            credentialEntry(
              credentialId: const [0x02],
              publicKey: ed25519PublicKey(List<int>.filled(32, 2)),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      );

      final keys = await downloaderFor(device).download();

      expect(keys.map((key) => key.suggestedLabel), everyElement(isEmpty));
      expect(keys.map((key) => key.fingerprintSha256).toSet(), hasLength(2));
    });

    test('marks uv-protected credentials as requiring verification', () async {
      final responder = CredMgmtResponder(
        rps: {
          'ssh:': [
            credentialEntry(
              credentialId: const [0x01],
              publicKey: ed25519PublicKey(List<int>.filled(32, 7)),
              credProtect: 0x03,
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      );

      final key = (await downloaderFor(device).download()).single;

      expect(key.keyPair.flags, 0x25);
      expect(key.requiresUserVerification, isTrue);
      expect(key.suggestedLabel, '');
    });

    test(
      'downloads an ecdsa resident key with an uncompressed point',
      () async {
        final x = List<int>.generate(31, (index) => index + 1);
        final y = List<int>.generate(32, (index) => 32 - index);
        final responder = CredMgmtResponder(
          rps: {
            'ssh:work': [
              credentialEntry(
                credentialId: const [0xC0],
                publicKey: es256PublicKey(x, y),
              ),
            ],
          },
        );
        final device = FakeCtapDevice(
          signature: const [],
          authData: const [],
          respond: responder.call,
        );

        final key = (await downloaderFor(device).download()).single;

        expect(key.algorithm, 'ecdsa-sk');
        final keyPair = key.keyPair as OpenSSHSecurityKeyEcdsaKeyPair;
        expect(keyPair.q, hasLength(65));
        expect(keyPair.q.first, 0x04);
        // x is 31 bytes long and must be left-padded to 32.
        expect(keyPair.q.sublist(1, 33), [0, ...x]);
        expect(keyPair.q.sublist(33), y);

        final reparsed =
            SSHKeyPair.fromPem(key.toPem()).single
                as OpenSSHSecurityKeyEcdsaKeyPair;
        expect(reparsed.q, keyPair.q);
      },
    );

    test('skips non-ssh relying parties and unsupported algorithms', () async {
      final responder = CredMgmtResponder(
        rps: {
          'example.com': [
            credentialEntry(
              credentialId: const [0x99],
              publicKey: ed25519PublicKey(List<int>.filled(32, 9)),
            ),
          ],
          'ssh:mixed': [
            credentialEntry(
              credentialId: const [0x11],
              publicKey: {
                1: 3,
                3: -257,
                -1: CborBytes(const [1]),
                -2: CborBytes(const [2]),
              },
            ),
            credentialEntry(
              credentialId: const [0x22],
              publicKey: ed25519PublicKey(List<int>.filled(32, 4)),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      );

      final keys = await downloaderFor(device).download();

      expect(keys, hasLength(1));
      expect(keys.single.keyPair.keyHandle, const [0x22]);
      final enumerated = responder.commands
          .where(
            (command) =>
                credMgmtSubCommandOf(command) ==
                CredentialManagementSubCommand.enumerateCredentialsBegin.value,
          )
          .map(
            (command) =>
                (credMgmtParamsOf(
                          command,
                        )![CredentialManagementSubCommandParams.rpIdHash.value]
                        as List)
                    .cast<int>(),
          );
      expect(enumerated, hasLength(1));
      expect(enumerated.single, rpIdHashOf('ssh:mixed'));
    });

    test(
      'returns an empty list when the key has no resident credentials',
      () async {
        final responder = CredMgmtResponder(rps: {});
        final device = FakeCtapDevice(
          signature: const [],
          authData: const [],
          respond: responder.call,
        );

        final statuses = <String>[];
        final keys = await downloaderFor(device, statuses: statuses).download();

        expect(keys, isEmpty);
        expect(
          statuses.last,
          'No resident SSH keys found on this security key.',
        );
      },
    );

    test('falls back to the credentialMgmtPreview command byte', () async {
      final responder = CredMgmtResponder(
        command: credentialManagementPreviewCommand,
        infoOptions: {'clientPin': true, 'credentialMgmtPreview': true},
        rps: {
          'ssh:legacy': [
            credentialEntry(
              credentialId: const [0x33],
              publicKey: ed25519PublicKey(List<int>.filled(32, 5)),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      );

      final keys = await downloaderFor(device).download();

      expect(keys, hasLength(1));
      expect(keys.single.application, 'ssh:legacy');
      expect(responder.commands, isNotEmpty);
      expect(
        device.commands.any(
          (command) =>
              command.first == Ctap2Commands.credentialManagement.value,
        ),
        isFalse,
      );
    });

    test('reports keys without credential management support', () async {
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: (command) => command.first == Ctap2Commands.getInfo.value
            ? infoResponse({'clientPin': true})
            : null,
      );

      final statuses = <String>[];
      await expectLater(
        downloaderFor(device, statuses: statuses).download(),
        throwsA(isA<ResidentKeyDownloadError>()),
      );
      expect(statuses.last, contains('cannot list resident keys'));
    });

    test('re-prompts for the PIN after a rejection', () async {
      final responder = CredMgmtResponder(
        rps: {
          'ssh:retry': [
            credentialEntry(
              credentialId: const [0x44],
              publicKey: ed25519PublicKey(List<int>.filled(32, 6)),
            ),
          ],
        },
      );
      final device = FakeCtapDevice(
        signature: const [],
        authData: const [],
        respond: responder.call,
      )..rejectPinChecks = 1;

      final promptedRetries = <int?>[];
      final keys = await downloaderFor(
        device,
        pins: ['0000', '1234'],
        promptedRetries: promptedRetries,
      ).download();

      expect(keys, hasLength(1));
      expect(promptedRetries, [null, 8]);
      expect(device.pinTokenGrants, 1);
    });

    test('throws when the PIN prompt is cancelled', () async {
      final device = FakeCtapDevice(signature: const [], authData: const []);

      await expectLater(
        downloaderFor(device, pins: [null]).download(),
        throwsA(isA<ResidentKeyDownloadCancelled>()),
      );
      expect(device.commands, isEmpty);
    });
  });
}
