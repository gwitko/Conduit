import 'dart:io';

import 'package:conduit/core/l10n/l10n.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

class FidoUsbCtapDevice extends CtapDevice {
  FidoUsbCtapDevice._();

  static const _channel = MethodChannel('conduit/fido_usb');

  static Future<bool> get isAvailable async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('hasDevice') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<FidoUsbCtapDevice> open() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        AppLocalizationsHolder.current.securityKeyUsbAndroidOnly,
      );
    }
    await _channel.invokeMethod<void>('open');
    return FidoUsbCtapDevice._();
  }

  Future<void> close() => _channel.invokeMethod<void>('close');

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    final response = await _channel.invokeMethod<Uint8List>(
      'transceive',
      Uint8List.fromList(command),
    );
    if (response == null || response.isEmpty) {
      throw FormatException(
        AppLocalizationsHolder.current.securityKeyUsbEmptyResponse,
      );
    }
    return CtapResponse(response[0], response.sublist(1));
  }
}
