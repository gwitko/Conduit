import 'dart:io';
import 'dart:typed_data';

import 'package:fido2/fido2_client.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class FidoNfcCtapDevice extends CtapDevice {
  FidoNfcCtapDevice._();

  static const _selectFidoApplet = <int>[
    0x00,
    0xA4,
    0x04,
    0x00,
    0x08,
    0xA0,
    0x00,
    0x00,
    0x06,
    0x47,
    0x2F,
    0x00,
    0x01,
  ];

  static Future<FidoNfcCtapDevice> pollAndSelect() async {
    await FlutterNfcKit.poll(
      timeout: const Duration(seconds: 30),
      androidCheckNDEF: false,
      iosAlertMessage: 'Hold your security key near the phone.',
      readIso14443A: true,
      readIso14443B: true,
      readIso15693: false,
    );

    final response = await FlutterNfcKit.transceive<Uint8List>(
      Uint8List.fromList(_selectFidoApplet),
      timeout: const Duration(seconds: 10),
    );
    _throwIfBadStatus(response, 'FIDO applet selection failed.');
    return FidoNfcCtapDevice._();
  }

  static Future<void> cancelPoll() {
    return FlutterNfcKit.finish();
  }

  Future<void> close({
    bool successful = false,
    String? iosAlertMessage,
    String? iosErrorMessage,
  }) {
    if (Platform.isAndroid && successful) {
      return Future<void>.value();
    }
    return FlutterNfcKit.finish(
      iosAlertMessage: iosAlertMessage,
      iosErrorMessage: iosErrorMessage,
    );
  }

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> command) async {
    var capdu = _ctapCommandApdu(command);
    var rapdu = <int>[];

    do {
      if (rapdu.length >= 2) {
        final remaining = rapdu.last;
        capdu = Uint8List.fromList([0x80, 0xC0, 0x00, 0x00, remaining]);
        rapdu = rapdu.sublist(0, rapdu.length - 2);
      }

      final chunk = await FlutterNfcKit.transceive<Uint8List>(
        capdu,
        timeout: const Duration(seconds: 30),
      );
      rapdu = [...rapdu, ...chunk];
    } while (rapdu.length >= 2 && rapdu[rapdu.length - 2] == 0x61);

    _throwIfBadStatus(Uint8List.fromList(rapdu), 'FIDO command failed.');
    if (rapdu.length < 3) {
      throw const FormatException('FIDO response was too short.');
    }
    return CtapResponse(rapdu[0], rapdu.sublist(1, rapdu.length - 2));
  }

  static Uint8List _ctapCommandApdu(List<int> command) {
    final lc = command.length <= 255
        ? <int>[command.length]
        : <int>[0x00, command.length >> 8, command.length & 0xff];
    return Uint8List.fromList([0x80, 0x10, 0x00, 0x00, ...lc, ...command]);
  }

  static void _throwIfBadStatus(Uint8List response, String message) {
    if (response.length < 2) {
      throw FormatException('$message Empty APDU response.');
    }
    final sw1 = response[response.length - 2];
    final sw2 = response[response.length - 1];
    if (sw1 != 0x90 || sw2 != 0x00) {
      throw FormatException(
        '$message APDU status ${sw1.toRadixString(16).padLeft(2, '0')}'
        '${sw2.toRadixString(16).padLeft(2, '0')}.',
      );
    }
  }
}
