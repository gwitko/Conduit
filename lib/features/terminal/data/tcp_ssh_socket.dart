import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

class TcpSshSocket implements SSHSocket {
  TcpSshSocket._(this._socket);

  static Future<TcpSshSocket> connect(
    String host,
    int port, {
    Duration? timeout,
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    return TcpSshSocket._(socket);
  }

  final Socket _socket;

  InternetAddress? get remoteAddress {
    try {
      return _socket.remoteAddress;
    } on SocketException {
      return null;
    }
  }

  @override
  Stream<Uint8List> get stream => _socket;

  @override
  StreamSink<List<int>> get sink => _socket;

  @override
  Future<void> get done => _socket.done;

  @override
  Future<void> close() async {
    await _socket.close();
  }

  @override
  void destroy() {
    _socket.destroy();
  }
}
