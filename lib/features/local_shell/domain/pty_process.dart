import 'dart:typed_data';

abstract interface class PtyProcess {
  Stream<Uint8List> get output;

  Future<int> get exitCode;

  void write(Uint8List data);

  void resize(int rows, int columns);

  void kill();
}
