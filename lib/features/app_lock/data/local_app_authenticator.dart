import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

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
  Future<AppAuthenticationResult> authenticate(
    AppAuthenticationPrompt prompt,
  ) async {
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: prompt.reason,
        // The Android prompt is the only one that paints plugin-side strings:
        // `signInTitle`, `signInHint`, and `cancelButton` default to hardcoded
        // English constants, so they have to be supplied. iOS and macOS read
        // their button labels from the OS instead, which is already localized.
        authMessages: [
          AndroidAuthMessages(
            signInTitle: prompt.title,
            signInHint: prompt.hint,
            cancelButton: prompt.cancel,
          ),
        ],
      );
      return authenticated
          ? AppAuthenticationResult.success
          : AppAuthenticationResult.cancelled;
    } on PlatformException {
      return AppAuthenticationResult.unavailable;
    }
  }
}
