import 'dart:convert';
import 'dart:typed_data';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/core/l10n/l10n.dart';

class TarArchiveBuilder {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  void addDirectory(String path, DateTime? modifiedAt) {
    final normalized = path.endsWith('/') ? path : '$path/';
    _addHeader(
      name: normalized,
      size: 0,
      type: _TarEntryType.directory,
      modifiedAt: modifiedAt,
    );
  }

  void addFile(String path, Uint8List data, DateTime? modifiedAt) {
    _addHeader(
      name: path,
      size: data.length,
      type: _TarEntryType.file,
      modifiedAt: modifiedAt,
    );
    _bytes.add(data);
    final padding = 512 - (data.length % 512);
    if (padding < 512) {
      _bytes.add(Uint8List(padding));
    }
  }

  Uint8List finish() {
    _bytes.add(Uint8List(1024));
    return _bytes.takeBytes();
  }

  void _addHeader({
    required String name,
    required int size,
    required _TarEntryType type,
    DateTime? modifiedAt,
  }) {
    final header = Uint8List(512);
    final split = _splitPath(name);
    _writeString(header, 0, 100, split.name);
    _writeOctal(
      header,
      100,
      8,
      type == _TarEntryType.directory ? 0x1ED : 0x1A4,
    );
    _writeOctal(header, 108, 8, 0);
    _writeOctal(header, 116, 8, 0);
    _writeOctal(header, 124, 12, size);
    _writeOctal(
      header,
      136,
      12,
      (modifiedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
    );
    for (var index = 148; index < 156; index += 1) {
      header[index] = 0x20;
    }
    header[156] = type == _TarEntryType.directory ? 0x35 : 0x30;
    _writeString(header, 257, 6, 'ustar');
    _writeString(header, 263, 2, '00');
    _writeString(header, 345, 155, split.prefix);

    final checksum = header.fold<int>(0, (sum, byte) => sum + byte);
    _writeChecksum(header, checksum);
    _bytes.add(header);
  }

  ({String name, String prefix}) _splitPath(String path) {
    if (utf8.encode(path).length <= 100) {
      return (name: path, prefix: '');
    }
    final parts = path.split('/');
    for (var index = parts.length - 1; index > 0; index -= 1) {
      final prefix = parts.take(index).join('/');
      final name = parts.skip(index).join('/');
      if (utf8.encode(prefix).length <= 155 &&
          utf8.encode(name).length <= 100) {
        return (name: name, prefix: prefix);
      }
    }
    throw AppFailure(AppLocalizationsHolder.current.sftpErrorPathTooLong(path));
  }

  void _writeString(Uint8List header, int offset, int length, String value) {
    final encoded = utf8.encode(value);
    final count = encoded.length > length ? length : encoded.length;
    header.setRange(offset, offset + count, encoded);
  }

  void _writeOctal(Uint8List header, int offset, int length, int value) {
    final encoded = ascii.encode(
      value.toRadixString(8).padLeft(length - 1, '0'),
    );
    header.setRange(offset, offset + encoded.length, encoded);
    header[offset + length - 1] = 0;
  }

  void _writeChecksum(Uint8List header, int checksum) {
    final encoded = ascii.encode(checksum.toRadixString(8).padLeft(6, '0'));
    header.setRange(148, 148 + encoded.length, encoded);
    header[154] = 0;
    header[155] = 0x20;
  }
}

enum _TarEntryType { file, directory }
