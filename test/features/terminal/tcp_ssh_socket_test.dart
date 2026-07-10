import 'dart:async';
import 'dart:io';

import 'package:conduit/features/terminal/data/tcp_ssh_socket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects, exposes the remote address, and moves data', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<List<int>>();
    server.listen((client) {
      client.listen((data) {
        received.complete(data);
        client.add([4, 5, 6]);
        client.flush().then((_) => client.close());
      });
    });

    final socket = await TcpSshSocket.connect('127.0.0.1', server.port);
    expect(socket.remoteAddress, InternetAddress.loopbackIPv4);

    socket.sink.add([1, 2, 3]);
    expect(await received.future, [1, 2, 3]);

    final echoed = await socket.stream.first;
    expect(echoed, [4, 5, 6]);

    await socket.close();
    await server.close();
  });

  test('resolves a hostname to the address actually connected to', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((client) => client.close());

    final socket = await TcpSshSocket.connect('localhost', server.port);
    expect(socket.remoteAddress?.address, '127.0.0.1');

    socket.destroy();
    await server.close();
  });
}
