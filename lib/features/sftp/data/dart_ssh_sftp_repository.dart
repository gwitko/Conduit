import 'dart:typed_data';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:dartssh2/dartssh2.dart';

class DartSshSftpRepository implements SftpRepository {
  const DartSshSftpRepository(this._hostKeyVerifier);

  final HostKeyVerifier _hostKeyVerifier;
  SshClientFactory get _clientFactory => SshClientFactory(_hostKeyVerifier);

  @override
  Future<SftpSession> connect(SavedHost host) async {
    SSHClient? client;
    try {
      client = await _clientFactory.connect(host);

      final sftp = await client.sftp();
      return DartSshSftpSession(client: client, sftp: sftp);
    } catch (error) {
      client?.close();
      throw AppFailure(
        'Could not open files on ${host.host}:${host.port}.',
        error,
      );
    }
  }
}

class DartSshSftpSession implements SftpSession {
  DartSshSftpSession({required this.client, required this.sftp});

  final SSHClient client;
  final SftpClient sftp;
  bool _closed = false;

  @override
  Future<List<SftpEntry>> list(String path) async {
    final names = await sftp.listdir(path);
    final entries = <SftpEntry>[];
    for (final name in names) {
      if (name.filename == '.' || name.filename == '..') {
        continue;
      }
      entries.add(_toEntry(path, name));
    }
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Future<String> resolve(String path) => sftp.absolute(path);

  @override
  Future<Uint8List> read(
    String path, {
    void Function(int bytesRead, int? total)? onProgress,
  }) async {
    final file = await sftp.open(path);
    try {
      int? total;
      try {
        total = (await file.stat()).size;
      } catch (_) {
        total = null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.read(
        onProgress: (read) => onProgress?.call(read, total),
      )) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> write(
    String path,
    Stream<Uint8List> data,
    int length, {
    void Function(int bytesSent)? onProgress,
  }) async {
    final file = await sftp.open(
      path,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    try {
      var bytesSent = 0;
      await for (final chunk in data) {
        await file.writeBytes(chunk, offset: bytesSent);
        bytesSent += chunk.length;
        onProgress?.call(bytesSent);
      }
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> makeDirectory(String path) => sftp.mkdir(path);

  @override
  Future<void> rename(String from, String to) => sftp.rename(from, to);

  @override
  Future<void> delete(SftpEntry entry) {
    return entry.isDirectory ? sftp.rmdir(entry.path) : sftp.remove(entry.path);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    sftp.close();
    client.close();
    await client.done;
  }

  SftpEntry _toEntry(String parent, SftpName name) {
    final attr = name.attr;
    final kind = switch (attr.type) {
      SftpFileType.directory => SftpEntryKind.directory,
      SftpFileType.regularFile => SftpEntryKind.file,
      SftpFileType.symbolicLink => SftpEntryKind.symlink,
      _ => SftpEntryKind.other,
    };
    final modifyTime = attr.modifyTime;
    return SftpEntry(
      name: name.filename,
      path: _join(parent, name.filename),
      kind: kind,
      size: attr.size,
      modifiedAt: modifyTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(modifyTime * 1000),
      permissions: attr.mode == null ? null : attr.mode!.value & 0xFFF,
    );
  }

  String _join(String parent, String name) {
    if (parent == '/') {
      return '/$name';
    }
    return '$parent/$name';
  }
}
