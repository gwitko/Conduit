import 'package:conduit/core/app_failure.dart';
import 'package:conduit/core/l10n/l10n.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

String describeSshConnectionError(Object error) {
  final l10n = AppLocalizationsHolder.current;
  final unwrapped = _unwrapSshError(error);

  if (unwrapped is CtapError) {
    return describeCtapStatus(unwrapped.status);
  }
  if (unwrapped is PlatformException) {
    return _describePlatformException(unwrapped);
  }
  if (unwrapped is SSHSecurityKeyNotPresentError) {
    return l10n.sshErrorKeyNotUsable;
  }
  if (unwrapped is SSHAuthFailError) {
    return l10n.sshErrorAuthRejected;
  }
  if (unwrapped is SSHAuthAbortError) {
    return l10n.sshErrorAuthAborted;
  }
  if (unwrapped is SSHHandshakeError) {
    return l10n.sshErrorHandshakeFailed(unwrapped.message);
  }
  if (unwrapped is StateError) {
    return unwrapped.message;
  }
  if (unwrapped is Exception || unwrapped is Error) {
    return '$unwrapped';
  }

  return unwrapped.toString();
}

Object _unwrapSshError(Object error) {
  var current = error;
  while (true) {
    if (current is AppFailure && current.cause != null) {
      current = current.cause!;
      continue;
    }
    if (current is SSHAuthAbortError && current.reason != null) {
      current = current.reason!;
      continue;
    }
    if (current is SSHInternalError) {
      current = current.error;
      continue;
    }
    return current;
  }
}

String describeCtapStatus(CtapStatusCode status) {
  final l10n = AppLocalizationsHolder.current;
  return switch (status) {
    CtapStatusCode.ctap2ErrPinInvalid => l10n.ctapErrorPinInvalid,
    CtapStatusCode.ctap2ErrPinBlocked => l10n.ctapErrorPinBlocked,
    CtapStatusCode.ctap2ErrPinAuthBlocked => l10n.ctapErrorPinAuthBlocked,
    CtapStatusCode.ctap2ErrPinNotSet => l10n.ctapErrorPinNotSet,
    CtapStatusCode.ctap2ErrPuatRequired => l10n.ctapErrorPuatRequired,
    CtapStatusCode.ctap2ErrUserActionTimeout ||
    CtapStatusCode.ctap2ErrActionTimeout => l10n.ctapErrorTouchTimeout,
    CtapStatusCode.ctap2ErrUpRequired => l10n.ctapErrorUpRequired,
    CtapStatusCode.ctap2ErrKeepaliveCancel ||
    CtapStatusCode.ctap2ErrOperationDenied => l10n.ctapErrorCancelled,
    CtapStatusCode.ctap2ErrNoCredentials ||
    CtapStatusCode.ctap2ErrInvalidCredential => l10n.ctapErrorNoCredentials,
    CtapStatusCode.ctap2ErrPinAuthInvalid => l10n.ctapErrorPinAuthInvalid,
    CtapStatusCode.ctap2ErrInvalidOption => l10n.ctapErrorInvalidOption,
    CtapStatusCode.ctap2ErrUnauthorizedPermission =>
      l10n.ctapErrorUnauthorizedPermission,
    _ => l10n.ctapErrorGeneric(status.name),
  };
}

String _describePlatformException(PlatformException error) {
  final l10n = AppLocalizationsHolder.current;
  return switch (error.code) {
    'permission_denied' => l10n.securityKeyPermissionDenied,
    '409' => l10n.ctapErrorCancelled,
    '408' => l10n.securityKeyNfcTimeout,
    '500' || '503' || '406' => l10n.securityKeyNfcInterrupted,
    _ =>
      error.message == null || error.message!.isEmpty
          ? l10n.securityKeyOperationFailed(error.code)
          : error.message!,
  };
}
