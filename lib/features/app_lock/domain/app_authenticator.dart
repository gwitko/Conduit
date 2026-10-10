enum AppAuthenticationResult { success, cancelled, unavailable }

/// Localized text for the platform authentication prompt.
///
/// The domain layer stays free of Flutter and of any particular language; the
/// presentation layer fills these in from `AppLocalizations` and the
/// implementation forwards them to the platform dialog.
///
/// Only the Android prompt needs these: it paints strings the plugin ships as
/// hardcoded English constants. iOS and macOS build their prompt from
/// OS-provided text, which the system already localizes.
class AppAuthenticationPrompt {
  const AppAuthenticationPrompt({
    required this.reason,
    required this.title,
    required this.hint,
    required this.cancel,
  });

  /// Why the app is asking, e.g. "Unlock Conduit to access saved SSH machines."
  final String reason;

  /// Dialog title, e.g. "Authentication required".
  final String title;

  /// Hint line under the title, e.g. "Verify identity".
  final String hint;

  /// Label of the button that dismisses the dialog.
  final String cancel;
}

abstract interface class AppAuthenticator {
  Future<bool> canAuthenticate();

  Future<AppAuthenticationResult> authenticate(AppAuthenticationPrompt prompt);
}
