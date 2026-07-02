import 'package:conduit/core/app_failure.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

String describeSshConnectionError(Object error) {
  final unwrapped = _unwrapSshError(error);

  if (unwrapped is CtapError) {
    return describeCtapStatus(unwrapped.status);
  }
  if (unwrapped is PlatformException) {
    return _describePlatformException(unwrapped);
  }
  if (unwrapped is SSHSecurityKeyNotPresentError) {
    return 'The presented security key does not hold any usable key for '
        'this host.';
  }
  if (unwrapped is SSHAuthFailError) {
    return 'SSH server rejected the configured credentials.';
  }
  if (unwrapped is SSHAuthAbortError) {
    return 'SSH authentication stopped before it completed.';
  }
  if (unwrapped is SSHHandshakeError) {
    return 'SSH handshake failed: ${unwrapped.message}';
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
  return switch (status) {
    CtapStatusCode.ctap2ErrPinInvalid => 'Security key PIN was incorrect.',
    CtapStatusCode.ctap2ErrPinBlocked =>
      'Security key PIN is blocked. Reset the key FIDO app to use it again.',
    CtapStatusCode.ctap2ErrPinAuthBlocked =>
      'Security key PIN authentication is temporarily blocked. Remove and '
          'reinsert the key, then try again.',
    CtapStatusCode.ctap2ErrPinNotSet =>
      'This security key needs a FIDO2 PIN before it can be used.',
    CtapStatusCode.ctap2ErrPuatRequired =>
      'This security key requires PIN or user verification.',
    CtapStatusCode.ctap2ErrUserActionTimeout ||
    CtapStatusCode.ctap2ErrActionTimeout => 'Security key touch timed out.',
    CtapStatusCode.ctap2ErrUpRequired =>
      'Touch is required on the security key.',
    CtapStatusCode.ctap2ErrKeepaliveCancel ||
    CtapStatusCode.ctap2ErrOperationDenied =>
      'Security key authentication was cancelled.',
    CtapStatusCode.ctap2ErrNoCredentials ||
    CtapStatusCode.ctap2ErrInvalidCredential =>
      'This security key does not have the credential for this SSH key stub.',
    CtapStatusCode.ctap2ErrPinAuthInvalid =>
      'Security key rejected the PIN authentication data.',
    CtapStatusCode.ctap2ErrInvalidOption =>
      'Security key rejected the requested verification option.',
    CtapStatusCode.ctap2ErrUnauthorizedPermission =>
      'Security key rejected the requested authentication permission.',
    _ => 'Security key failed with CTAP status ${status.name}.',
  };
}

String _describePlatformException(PlatformException error) {
  return switch (error.code) {
    'permission_denied' => 'USB security key permission was denied.',
    '500' || '503' || '406' =>
      'NFC security key read was interrupted. Hold the key still and try again.',
    _ =>
      error.message == null || error.message!.isEmpty
          ? 'Security key operation failed: ${error.code}.'
          : error.message!,
  };
}
