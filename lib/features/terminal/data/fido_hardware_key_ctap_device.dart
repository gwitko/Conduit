import 'dart:async';
import 'dart:io';

import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

import 'fido_nfc_ctap_device.dart';
import 'fido_usb_ctap_device.dart';

class FidoHardwareKeyCtapDevice {
  const FidoHardwareKeyCtapDevice._();

  static const _androidDiscoveryWindow = Duration(seconds: 30);
  static const _usbPollInterval = Duration(milliseconds: 250);

  static Future<CtapDevice> open() async {
    if (Platform.isAndroid) {
      return _openAndroid();
    }
    return FidoNfcCtapDevice.pollAndSelect();
  }

  static Future<CtapDevice> _openAndroid() async {
    final completer = Completer<CtapDevice>();
    var settled = false;
    var usbDiscoveryDone = false;
    Object? nfcError;
    StackTrace? nfcStackTrace;

    void completeWithDevice(CtapDevice device) {
      if (settled) {
        unawaited(close(device, false));
        return;
      }
      settled = true;
      if (device is FidoUsbCtapDevice) {
        unawaited(FidoNfcCtapDevice.cancelPoll());
      }
      completer.complete(device);
    }

    void completeWithError(Object error, StackTrace stackTrace) {
      if (settled) return;
      settled = true;
      unawaited(FidoNfcCtapDevice.cancelPoll());
      completer.completeError(error, stackTrace);
    }

    void completeWithNfcErrorIfUsbFinished() {
      final error = nfcError;
      final stackTrace = nfcStackTrace;
      if (!usbDiscoveryDone || error == null || stackTrace == null) return;
      completeWithError(error, stackTrace);
    }

    unawaited(
      _pollUsbUntilAvailable(
            _androidDiscoveryWindow,
            isCancelled: () => settled,
          )
          .then((device) {
            usbDiscoveryDone = true;
            if (device != null) {
              completeWithDevice(device);
            } else {
              completeWithNfcErrorIfUsbFinished();
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (error is PlatformException &&
                error.code == 'permission_denied') {
              completeWithError(error, stackTrace);
            }
          }),
    );

    unawaited(
      FidoNfcCtapDevice.pollAndSelect().then(completeWithDevice).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        nfcError = error;
        nfcStackTrace = stackTrace;
        completeWithNfcErrorIfUsbFinished();
      }),
    );

    return completer.future;
  }

  static Future<CtapDevice?> _pollUsbUntilAvailable(
    Duration timeout, {
    required bool Function() isCancelled,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!isCancelled() && DateTime.now().isBefore(deadline)) {
      if (await FidoUsbCtapDevice.isAvailable) {
        try {
          if (isCancelled()) return null;
          return await FidoUsbCtapDevice.open();
        } on PlatformException catch (error) {
          if (error.code == 'permission_denied') {
            rethrow;
          }
        }
      }
      await Future<void>.delayed(_usbPollInterval);
    }
    return null;
  }

  static Future<void> close(CtapDevice device, bool ok) {
    if (device is FidoUsbCtapDevice) {
      return device.close();
    }
    if (device is FidoNfcCtapDevice) {
      return device.close(
        successful: ok,
        iosAlertMessage: ok ? 'Security key accepted.' : null,
        iosErrorMessage: ok ? null : 'Security key signing failed.',
      );
    }
    return Future<void>.value();
  }
}
