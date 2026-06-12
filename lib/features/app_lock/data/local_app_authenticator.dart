import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAppAuthenticator implements AppAuthenticator {
  LocalAppAuthenticator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _localAuthentication.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<AppAuthenticationResult> authenticate() async {
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Unlock Conduit to access saved SSH machines.',
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      return authenticated
          ? AppAuthenticationResult.success
          : AppAuthenticationResult.cancelled;
    } on PlatformException {
      return AppAuthenticationResult.unavailable;
    }
  }
}
