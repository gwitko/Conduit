import 'dart:async';
import 'dart:typed_data';

import 'package:conduit/features/terminal/data/bastion_ssh_socket.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards traffic through the tunnel socket', () async {
    final tunnel = _FakeSocket();
    final bastion = BastionSshSocket(tunnel: tunnel, closeBastion: () {});

    bastion.sink.add([1, 2, 3]);
    expect(tunnel.written, [
      [1, 2, 3],
    ]);

    final received = bastion.stream.first;
    tunnel.receive([4, 5, 6]);
    expect(await received, [4, 5, 6]);
    expect(bastion.done, tunnel.done);

    await bastion.close();
    expect(tunnel.closed, isTrue);
  });

  test('closing the tunnel also closes the bastion connection', () async {
    final tunnel = _FakeSocket();
    var bastionClosed = false;
    final bastion = BastionSshSocket(
      tunnel: tunnel,
      closeBastion: () => bastionClosed = true,
    );

    await bastion.close();

    expect(tunnel.closed, isTrue);
    expect(bastionClosed, isTrue);
  });

  test('destroying the tunnel also closes the bastion connection', () {
    final tunnel = _FakeSocket();
    var bastionClosed = false;
    final bastion = BastionSshSocket(
      tunnel: tunnel,
      closeBastion: () => bastionClosed = true,
    );

    bastion.destroy();

    expect(tunnel.destroyed, isTrue);
    expect(bastionClosed, isTrue);
  });

  test('close times out and destroys a stuck tunnel', () async {
    final tunnel = _FakeSocket()..completeClose = false;
    var bastionClosed = false;
    final bastion = BastionSshSocket(
      tunnel: tunnel,
      closeBastion: () => bastionClosed = true,
      closeTimeout: const Duration(milliseconds: 20),
    );

    await bastion.close();

    expect(tunnel.destroyed, isTrue);
    expect(bastionClosed, isTrue);
  });

  test('close and destroy are idempotent', () async {
    final tunnel = _FakeSocket();
    var bastionCloseCount = 0;
    final bastion = BastionSshSocket(
      tunnel: tunnel,
      closeBastion: () => bastionCloseCount += 1,
    );

    await bastion.close();
    await bastion.close();
    bastion.destroy();

    expect(bastionCloseCount, 1);
  });
}

class _FakeSocket implements SSHSocket {
  final _incoming = StreamController<Uint8List>.broadcast(sync: true);
  final _sink = StreamController<List<int>>.broadcast(sync: true);
  final _done = Completer<void>();
  final written = <List<int>>[];

  bool closed = false;
  bool destroyed = false;
  bool completeClose = true;

  _FakeSocket() {
    _sink.stream.listen(written.add);
  }

  void receive(List<int> bytes) => _incoming.add(Uint8List.fromList(bytes));

  @override
  Stream<Uint8List> get stream => _incoming.stream;

  @override
  StreamSink<List<int>> get sink => _sink.sink;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    closed = true;
    if (!completeClose) {
      return Completer<void>().future;
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
    await _incoming.close();
    await _sink.close();
  }

  @override
  void destroy() {
    destroyed = true;
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}
