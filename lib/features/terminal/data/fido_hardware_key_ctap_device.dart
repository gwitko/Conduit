import 'dart:io';

import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

import 'fido_nfc_ctap_device.dart';
import 'fido_usb_ctap_device.dart';

class FidoHardwareKeyCtapDevice {
  const FidoHardwareKeyCtapDevice._();

  static Future<CtapDevice> open() async {
    if (Platform.isAndroid && await FidoUsbCtapDevice.isAvailable) {
      try {
        return await FidoUsbCtapDevice.open();
      } on PlatformException catch (error) {
        if (error.code == 'permission_denied') {
          rethrow;
        }
      }
    }
    return FidoNfcCtapDevice.pollAndSelect();
  }

  static Future<void> close(CtapDevice device, bool ok) {
    if (device is FidoUsbCtapDevice) {
      return device.close();
    }
    if (device is FidoNfcCtapDevice) {
      return device.close(
        iosAlertMessage: ok ? 'Security key accepted.' : null,
        iosErrorMessage: ok ? null : 'Security key signing failed.',
      );
    }
    return Future<void>.value();
  }
}
