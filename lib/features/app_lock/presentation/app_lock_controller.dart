import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:flutter/foundation.dart';

enum AppLockStatus { locked, checking, unlocked, unavailable }

/// Why the lock screen is showing a notice. The UI turns this into text so the
/// controller stays free of presentation strings.
enum AppLockNotice { deviceNotConfigured, cancelled, deviceUnavailable }

class AppLockController extends ChangeNotifier {
  AppLockController(this._authenticator);

  final AppAuthenticator _authenticator;

  AppLockStatus _status = AppLockStatus.locked;
  AppLockNotice? _notice;

  AppLockStatus get status => _status;
  AppLockNotice? get notice => _notice;
  bool get isUnlocked => _status == AppLockStatus.unlocked;

  Future<void> unlock(AppLocalizations l10n) async {
    if (_status == AppLockStatus.checking) {
      return;
    }

    _status = AppLockStatus.checking;
    _notice = null;
    notifyListeners();

    final canAuthenticate = await _canAuthenticate();
    if (!canAuthenticate) {
      _status = AppLockStatus.unavailable;
      _notice = AppLockNotice.deviceNotConfigured;
      notifyListeners();
      return;
    }

    final result = await _authenticate(l10n);
    switch (result) {
      case AppAuthenticationResult.success:
        _status = AppLockStatus.unlocked;
        _notice = null;
      case AppAuthenticationResult.cancelled:
        _status = AppLockStatus.locked;
        _notice = AppLockNotice.cancelled;
      case AppAuthenticationResult.unavailable:
        _status = AppLockStatus.unavailable;
        _notice = AppLockNotice.deviceUnavailable;
    }
    notifyListeners();
  }

  Future<bool> _canAuthenticate() async {
    try {
      return await _authenticator.canAuthenticate();
    } catch (_) {
      return false;
    }
  }

  Future<AppAuthenticationResult> _authenticate(AppLocalizations l10n) async {
    try {
      return await _authenticator.authenticate(
        AppAuthenticationPrompt(
          reason: l10n.lockAuthReason,
          title: l10n.lockAuthTitle,
          hint: l10n.lockAuthHint,
          cancel: l10n.actionCancel,
        ),
      );
    } catch (_) {
      return AppAuthenticationResult.cancelled;
    }
  }

  void continueWithoutAuth() {
    if (_status != AppLockStatus.unavailable) {
      return;
    }
    _status = AppLockStatus.unlocked;
    notifyListeners();
  }

  void lock() {
    _status = AppLockStatus.locked;
    _notice = null;
    notifyListeners();
  }
}
