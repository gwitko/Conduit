import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

/// An [SSHSocket] whose traffic is tunnelled through a forwarded channel on a
/// bastion (jump host) SSH connection.
///
/// Closing or destroying this socket also tears down the bastion connection so
/// the jump host never leaks an idle SSH session.
class BastionSshSocket implements SSHSocket {
  BastionSshSocket({required this.tunnel, required this.closeBastion});

  final SSHSocket tunnel;
  final void Function() closeBastion;

  bool _closed = false;

  @override
  Stream<Uint8List> get stream => tunnel.stream;

  @override
  StreamSink<List<int>> get sink => tunnel.sink;

  @override
  Future<void> get done => tunnel.done;

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await tunnel.close();
    } finally {
      closeBastion();
    }
  }

  @override
  void destroy() {
    if (_closed) {
      return;
    }
    _closed = true;
    tunnel.destroy();
    closeBastion();
  }
}
