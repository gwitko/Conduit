import 'dart:io';

import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';
import 'package:http/http.dart' as http;

enum DownloadFailureKind { network, lowDisk, corrupt, unknown }

class DownloadException implements Exception {
  const DownloadException(this.kind, this.message);

  final DownloadFailureKind kind;
  final String message;

  @override
  String toString() => 'DownloadException($kind, $message)';
}

abstract interface class RootfsDownloader {
  Future<void> download({
    required RootfsManifest manifest,
    required String destination,
    void Function(double progress)? onProgress,
  });
}

class HttpRootfsDownloader implements RootfsDownloader {
  HttpRootfsDownloader([http.Client? client])
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> download({
    required RootfsManifest manifest,
    required String destination,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(destination);
    await file.parent.create(recursive: true);

    final total = manifest.downloadSizeBytes;
    var existing = await file.exists() ? await file.length() : 0;
    if (total > 0 && existing > total) {
      await file.delete();
      existing = 0;
    }

    final verifier = Sha256Verifier(manifest.sha256);
    final alreadyComplete = total > 0 && existing == total;
    if (alreadyComplete) {
      await _hashFile(file, verifier);
    } else {
      await _fetch(
        manifest: manifest,
        file: file,
        existing: existing,
        total: total,
        verifier: verifier,
        onProgress: onProgress,
      );
    }

    if (!verifier.verify()) {
      await file.delete().catchError((_) => file);
      throw const DownloadException(
        DownloadFailureKind.corrupt,
        'Downloaded archive failed checksum verification.',
      );
    }
    onProgress?.call(1);
  }

  Future<void> _fetch({
    required RootfsManifest manifest,
    required File file,
    required int existing,
    required int total,
    required Sha256Verifier verifier,
    required void Function(double)? onProgress,
  }) async {
    final request = http.Request('GET', manifest.archiveUrl);
    if (existing > 0) {
      request.headers['Range'] = 'bytes=$existing-';
    }

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (error) {
      throw DownloadException(DownloadFailureKind.network, '$error');
    }

    if (response.statusCode != 200 && response.statusCode != 206) {
      throw DownloadException(
        DownloadFailureKind.network,
        'Unexpected HTTP status ${response.statusCode}',
      );
    }

    final resuming = response.statusCode == 206;
    if (resuming) {
      await _hashFile(file, verifier);
    }
    final sink = file.openWrite(
      mode: resuming ? FileMode.append : FileMode.write,
    );
    var received = resuming ? existing : 0;
    final grandTotal = total > 0
        ? total
        : received + (response.contentLength ?? 0);

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        verifier.addChunk(chunk);
        received += chunk.length;
        if (grandTotal > 0) {
          onProgress?.call((received / grandTotal).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      await sink.close();
    } on FileSystemException catch (error) {
      await sink.close().catchError((_) {});
      if (error.osError?.errorCode == 28) {
        throw const DownloadException(
          DownloadFailureKind.lowDisk,
          'No space left on device.',
        );
      }
      throw DownloadException(DownloadFailureKind.unknown, '$error');
    } catch (error) {
      await sink.close().catchError((_) {});
      throw DownloadException(DownloadFailureKind.network, '$error');
    }
  }

  Future<void> _hashFile(File file, Sha256Verifier verifier) async {
    await for (final chunk in file.openRead()) {
      verifier.addChunk(chunk);
    }
  }
}
