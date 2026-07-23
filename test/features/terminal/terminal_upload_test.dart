import 'dart:convert';
import 'dart:typed_data';

import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/upload_manifest.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart'
    show SftpUploadFile;
import 'package:conduit/features/terminal/presentation/terminal_page.dart';
import 'package:conduit/features/terminal/presentation/terminal_upload_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/features/terminal/presentation/widgets/terminal_upload_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import '../../support/test_doubles.dart';

class _NoopWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

SftpEntry _entryNamed(String name) {
  return SftpEntry(name: name, path: '/x/$name', kind: SftpEntryKind.file);
}

SftpUploadFile _file(String name, List<int> bytes) {
  return SftpUploadFile(
    source: () => Stream.value(Uint8List.fromList(bytes)),
    name: name,
    size: bytes.length,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WakelockPlusPlatformInterface.instance = _NoopWakelock();

  final fixedNow = DateTime(2026, 7, 4, 14, 35, 2);

  group('TerminalUploadController', () {
    late FakeSftpSession session;
    late InMemoryUploadManifest manifest;

    TerminalUploadController buildController({
      SavedHost? host,
      Object? writeError,
    }) {
      session = FakeSftpSession(
        home: '/home/u',
        tree: {'/home/u': []},
        writeError: writeError,
      );
      manifest = InMemoryUploadManifest();
      return TerminalUploadController(
        host: host ?? buildHost('h1'),
        repository: FakeSftpRepository(session),
        manifest: manifest,
        now: () => fixedNow,
      );
    }

    test(
      'creates the dated directory chain and uploads with progress',
      () async {
        final controller = buildController();
        final progress = <TerminalUploadPhase>[];
        controller.addListener(() => progress.add(controller.phase));
        controller.prepare([
          _file('photo one.jpg', [1, 2, 3, 4]),
        ]);

        await controller.uploadAll();

        expect(controller.phase, TerminalUploadPhase.success);
        expect(session.madeDirectories, [
          '/home',
          '/home/u',
          '/home/u/.conduit',
          '/home/u/.conduit/uploads',
          '/home/u/.conduit/uploads/2026-07-04',
        ]);
        const path = '/home/u/.conduit/uploads/2026-07-04/photo one.jpg';
        expect(session.writtenFiles[path], [1, 2, 3, 4]);
        expect(controller.uploadedPaths, [path]);
        expect(
          controller.quotedPathsForInsertion,
          "'/home/u/.conduit/uploads/2026-07-04/photo one.jpg'",
        );
        expect(manifest.entries['h1'], hasLength(1));
        expect(session.closeCount, 1);
      },
    );

    test('sanitizes hostile names and resolves collisions', () async {
      final controller = buildController();
      session.tree['/home/u/.conduit/uploads/2026-07-04'] = [
        _entryNamed('photo.jpg'),
      ];
      // Pre-seeding the tree means makeDirectory must not clobber it.
      controller.prepare([
        _file('../../photo.jpg', [1]),
        _file('photo.jpg', [2]),
      ]);

      await controller.uploadAll();

      expect(controller.phase, TerminalUploadPhase.success);
      expect(controller.uploadedPaths, [
        '/home/u/.conduit/uploads/2026-07-04/photo-143502.jpg',
        '/home/u/.conduit/uploads/2026-07-04/photo-143502-2.jpg',
      ]);
    });

    test('uploads to a custom per-host directory', () async {
      final controller = buildController(
        host: buildHost('h1').copyWith(uploadDirectory: '~/drop zone'),
      );
      controller.prepare([
        _file('a.txt', [7]),
      ]);

      await controller.uploadAll();

      expect(controller.uploadedPaths, ['/home/u/drop zone/a.txt']);
      expect(controller.quotedPathsForInsertion, "'/home/u/drop zone/a.txt'");
    });

    test(
      'reports failure and keeps state recoverable on write errors',
      () async {
        final controller = buildController(writeError: StateError('disk full'));
        controller.prepare([
          _file('a.txt', [1]),
        ]);

        await controller.uploadAll();

        expect(controller.phase, TerminalUploadPhase.failed);
        expect(controller.error, contains('disk full'));
        expect(controller.uploadedPaths, isEmpty);
        expect(manifest.entries, isEmpty);
        expect(session.closeCount, 1);
      },
    );

    test('records already-uploaded files in the manifest when a later file '
        'fails', () async {
      session = FakeSftpSession(
        home: '/home/u',
        tree: {'/home/u': []},
        failWriteAtIndex: 1,
      );
      manifest = InMemoryUploadManifest();
      final controller = TerminalUploadController(
        host: buildHost('h1'),
        repository: FakeSftpRepository(session),
        manifest: manifest,
        now: () => fixedNow,
      );
      controller.prepare([
        _file('first.txt', [1]),
        _file('second.txt', [2]),
      ]);

      await controller.uploadAll();

      expect(controller.phase, TerminalUploadPhase.failed);
      // The first file reached the server, so cleanup must know about it.
      expect(manifest.entries['h1']!.map((e) => e.path), [
        '/home/u/.conduit/uploads/2026-07-04/first.txt',
      ]);
      // A failed batch never deletes anything.
      expect(session.deletedPaths, isEmpty);
    });

    test('a cancelled batch records uploads but never deletes', () async {
      final controller = buildController(
        host: buildHost('h1').copyWith(uploadCleanupDays: 7),
      );
      manifest.entries['h1'] = [
        UploadManifestEntry(
          path: '/old/expired.png',
          uploadedAt: DateTime.utc(2020),
        ),
      ];
      controller.prepare([
        _file('a.txt', [1]),
        _file('b.txt', [2]),
      ]);
      controller.addListener(() {
        if (controller.items.first.done &&
            controller.phase == TerminalUploadPhase.uploading) {
          controller.cancel();
        }
      });

      await controller.uploadAll();

      expect(controller.phase, TerminalUploadPhase.cancelled);
      expect(session.deletedPaths, isEmpty);
      expect(
        manifest.entries['h1']!.map((e) => e.path),
        containsAll([
          '/old/expired.png',
          '/home/u/.conduit/uploads/2026-07-04/a.txt',
        ]),
      );
    });

    test('fails cleanly when the connection cannot be opened', () async {
      final controller = TerminalUploadController(
        host: buildHost('h1'),
        repository: ThrowingSftpRepository(),
        manifest: InMemoryUploadManifest(),
        now: () => fixedNow,
      );
      controller.prepare([
        _file('a.txt', [1]),
      ]);

      await controller.uploadAll();

      expect(controller.phase, TerminalUploadPhase.failed);
      expect(controller.error, isNotNull);
    });

    test(
      'cancelling between files stops the batch and closes the session',
      () async {
        final controller = buildController();
        controller.prepare([
          _file('a.txt', [1]),
          _file('b.txt', [2]),
        ]);
        controller.addListener(() {
          if (controller.items.first.done &&
              controller.phase == TerminalUploadPhase.uploading) {
            controller.cancel();
          }
        });

        await controller.uploadAll();

        expect(controller.phase, TerminalUploadPhase.cancelled);
        expect(controller.uploadedPaths, hasLength(1));
        expect(session.writtenFiles.keys, hasLength(1));
        expect(session.closeCount, greaterThanOrEqualTo(1));
      },
    );

    test('zero-byte files upload successfully', () async {
      final controller = buildController();
      controller.prepare([_file('empty.txt', [])]);

      await controller.uploadAll();

      expect(controller.phase, TerminalUploadPhase.success);
      expect(
        session.writtenFiles['/home/u/.conduit/uploads/2026-07-04/empty.txt'],
        isEmpty,
      );
    });

    test(
      'cleanup deletes only manifest-listed files past the cutoff',
      () async {
        final controller = buildController(
          host: buildHost('h1').copyWith(uploadCleanupDays: 7),
        );
        manifest.entries['h1'] = [
          UploadManifestEntry(
            path: '/home/u/.conduit/uploads/2026-06-01/old.png',
            uploadedAt: DateTime.utc(2026, 6),
          ),
          UploadManifestEntry(
            path: '/home/u/.conduit/uploads/2026-07-03/fresh.png',
            uploadedAt: DateTime.utc(2026, 7, 3),
          ),
        ];
        controller.prepare([
          _file('new.txt', [1]),
        ]);

        await controller.uploadAll();

        expect(session.deletedPaths, [
          '/home/u/.conduit/uploads/2026-06-01/old.png',
        ]);
        final kept = manifest.entries['h1']!.map((e) => e.path).toList();
        expect(
          kept,
          isNot(contains('/home/u/.conduit/uploads/2026-06-01/old.png')),
        );
        expect(kept, contains('/home/u/.conduit/uploads/2026-07-03/fresh.png'));
        expect(kept, contains('/home/u/.conduit/uploads/2026-07-04/new.txt'));
      },
    );

    test('never deletes when cleanup is disabled', () async {
      final controller = buildController();
      manifest.entries['h1'] = [
        UploadManifestEntry(
          path: '/somewhere/ancient.png',
          uploadedAt: DateTime.utc(2020),
        ),
      ];
      controller.prepare([
        _file('new.txt', [1]),
      ]);

      await controller.uploadAll();

      expect(session.deletedPaths, isEmpty);
      expect(
        manifest.entries['h1']!.map((e) => e.path),
        contains('/somewhere/ancient.png'),
      );
    });
  });

  group('Terminal upload flow', () {
    testWidgets('picker → confirm → progress → insert quoted path', (
      tester,
    ) async {
      final terminalSession = TrackableTerminalSession();
      final workspace = TerminalWorkspaceController(
        ImmediateTerminalRepository(terminalSession),
      );
      final themeController = ThemeController(InMemoryThemePreferences());
      final sftpSession = FakeSftpSession(
        home: '/home/u',
        tree: {'/home/u': []},
      );
      final controller = workspace.open(buildHost('h1'));
      await tester.runAsync(controller.connect);
      addTearDown(workspace.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: TerminalPage(
            workspace: workspace,
            themeController: themeController,
            sftpRepository: FakeSftpRepository(sftpSession),
            uploadManifestRepository: InMemoryUploadManifest(),
            uploadFilePicker: () async => [
              _file('my shot.png', [9, 9]),
            ],
          ),
        ),
      );
      await tester.pump();
      await themeController.setTerminalKeyboardRows(const [
        TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.upload)],
        ),
      ]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.upload_file_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Confirmation state: filename, size, and explicit Upload action.
      expect(find.byType(TerminalUploadSheet), findsOneWidget);
      expect(find.text('my shot.png'), findsOneWidget);
      expect(find.text('2 B'), findsOneWidget);
      expect(sftpSession.writtenFiles, isEmpty);

      await tester.tap(find.text('Upload'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uploaded'), findsOneWidget);
      expect(sftpSession.writtenFiles.keys.single, endsWith('/my shot.png'));

      await tester.tap(find.text('Insert path'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TerminalUploadSheet), findsNothing);
      final sent = terminalSession.sent
          .map((bytes) => utf8.decode(bytes))
          .join();
      expect(sent, contains("'"));
      expect(sent, contains('/my shot.png'));
      // Inserted, not executed: no Enter was sent.
      expect(sent, isNot(contains('\r')));

      // Flush the terminal resize debounce timer.
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('failed uploads surface an error state', (tester) async {
      final workspace = TerminalWorkspaceController(
        ImmediateTerminalRepository(TrackableTerminalSession()),
      );
      final themeController = ThemeController(InMemoryThemePreferences());
      final controller = workspace.open(buildHost('h1'));
      await tester.runAsync(controller.connect);
      addTearDown(workspace.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: TerminalPage(
            workspace: workspace,
            themeController: themeController,
            sftpRepository: ThrowingSftpRepository(),
            uploadManifestRepository: InMemoryUploadManifest(),
            uploadFilePicker: () async => [
              _file('a.txt', [1]),
            ],
          ),
        ),
      );
      await tester.pump();
      await themeController.setTerminalKeyboardRows(const [
        TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.upload)],
        ),
      ]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.upload_file_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Upload'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.textContaining('Nothing was inserted'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(TerminalUploadSheet), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
