enum SshKeyAlgorithm {
  ed25519,
  rsa,
  ecdsa,
  securityKeyEd25519,
  securityKeyEcdsa,
  unknown,
}

extension SshKeyAlgorithmDetails on SshKeyAlgorithm {
  String get label => switch (this) {
    SshKeyAlgorithm.ed25519 => 'Ed25519',
    SshKeyAlgorithm.rsa => 'RSA',
    SshKeyAlgorithm.ecdsa => 'ECDSA',
    SshKeyAlgorithm.securityKeyEd25519 => 'Ed25519 SK',
    SshKeyAlgorithm.securityKeyEcdsa => 'ECDSA SK',
    SshKeyAlgorithm.unknown => 'SSH key',
  };

  bool get isSecurityKey =>
      this == SshKeyAlgorithm.securityKeyEd25519 ||
      this == SshKeyAlgorithm.securityKeyEcdsa;
}

class SshKeyDetails {
  const SshKeyDetails({
    required this.algorithm,
    required this.fingerprintSha256,
    required this.publicKeyOpenSsh,
    required this.comment,
  });

  final SshKeyAlgorithm algorithm;
  final String fingerprintSha256;
  final String publicKeyOpenSsh;
  final String comment;

  bool get isSecurityKey => algorithm.isSecurityKey;
}

enum SshKeyStatus {
  valid,
  securityKeyStub,
  needsPassphrase,
  verifying,
  wrongPassphrase,
  invalid,
}

class SshKeyInspection {
  const SshKeyInspection._(this.status, this.details);

  const SshKeyInspection.valid(SshKeyDetails details)
    : this._(SshKeyStatus.valid, details);

  const SshKeyInspection.securityKeyStub(SshKeyDetails details)
    : this._(SshKeyStatus.securityKeyStub, details);

  const SshKeyInspection.needsPassphrase()
    : this._(SshKeyStatus.needsPassphrase, null);

  const SshKeyInspection.verifying() : this._(SshKeyStatus.verifying, null);

  const SshKeyInspection.wrongPassphrase()
    : this._(SshKeyStatus.wrongPassphrase, null);

  const SshKeyInspection.invalid() : this._(SshKeyStatus.invalid, null);

  final SshKeyStatus status;
  final SshKeyDetails? details;

  bool get isUsable =>
      status == SshKeyStatus.valid || status == SshKeyStatus.securityKeyStub;
}

class GeneratedSshKey {
  const GeneratedSshKey({required this.privateKeyPem, required this.details});

  final String privateKeyPem;
  final SshKeyDetails details;
}

abstract class SshKeyService {
  /// Cheap, synchronous inspection. With an empty [passphrase] it never runs
  /// the key-derivation function, so it is safe to call on every keystroke.
  SshKeyInspection inspect(String pem, {String passphrase = ''});

  /// Verifies [passphrase] against an encrypted key. This runs the (slow)
  /// key-derivation function, so it is performed off the UI isolate.
  Future<SshKeyInspection> verify(String pem, {String passphrase = ''});

  GeneratedSshKey generateEd25519({
    String comment = '',
    String passphrase = '',
  });
}
