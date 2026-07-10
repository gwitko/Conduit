import 'dart:convert';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/backup/data/app_backup_service.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  group('AppBackupPasswordPolicy', () {
    test('enforces length, whitespace, and character variety', () {
      expect(AppBackupPasswordPolicy.validate('Short1!'), isNotNull);
      expect(AppBackupPasswordPolicy.validate(' StrongPass123!'), isNotNull);
      expect(AppBackupPasswordPolicy.validate('strongpassword12'), isNotNull);
      expect(AppBackupPasswordPolicy.validate('StrongPass123!'), isNull);
    });
  });

  group('AppBackupService', () {
    test('exports public backups without login secrets', () async {
      final fixture = await _Fixture.create();

      final bytes = await fixture.service.exportBackup(includeSecrets: false);
      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      final payload = decoded['payload'] as Map<String, Object?>;
      final hosts = payload['hosts'] as List<Object?>;
      final host = hosts.single as Map<String, Object?>;
      final hardwareKeys = host['hardwareKeys'] as List<Object?>;
      final hardwareKey = hardwareKeys.single as Map<String, Object?>;

      expect(decoded['encrypted'], isFalse);
      expect(host['password'], isEmpty);
      expect(host['privateKey'], isEmpty);
      expect(host['passphrase'], isEmpty);
      expect(hardwareKey['privateKey'], isEmpty);
      expect(hardwareKey['passphrase'], isEmpty);
      expect(payload['trustedHostKeys'], isNotEmpty);
    });

    test(
      'encrypts secret backups and imports them with the password',
      () async {
        final source = await _Fixture.create();

        final bytes = await source.service.exportBackup(
          includeSecrets: true,
          password: 'StrongPass123!',
        );
        final exported = utf8.decode(bytes);

        expect(exported, isNot(contains('secret-password')));
        expect(exported, isNot(contains('hardware-stub')));

        final target = await _Fixture.create(empty: true);
        final result = await target.service.importBackup(
          bytes,
          password: 'StrongPass123!',
        );

        expect(result.hostsImported, 1);
        expect(target.hostsRepository.persisted, hasLength(1));
        expect(
          target.hostsRepository.persisted.single.password,
          'secret-password',
        );
        expect(
          target.hostsRepository.persisted.single.privateKey,
          'hardware-stub',
        );
        expect(target.verifier.records, hasLength(1));
        expect(target.themeController.palette, AppPalette.catppuccin);
        expect(target.themeController.terminalKeyboardRows, [
          const TerminalKeyboardRow(
            items: [
              TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
            ],
          ),
        ]);
      },
    );

    test(
      'imports by merging matching hosts and keeping unrelated hosts',
      () async {
        final source = await _Fixture.create();
        final bytes = await source.service.exportBackup(includeSecrets: false);
        final target = await _Fixture.create(empty: true);
        target.hostsRepository.persisted = [
          buildHost('existing', username: 'before'),
          buildHost('unrelated', username: 'keep'),
        ];
        await target.hostsController.load();

        await target.service.importBackup(bytes);

        expect(target.hostsRepository.persisted, hasLength(2));
        expect(
          target.hostsRepository.persisted
              .firstWhere((host) => host.id == 'existing')
              .username,
          'alice',
        );
        expect(
          target.hostsRepository.persisted
              .firstWhere((host) => host.id == 'unrelated')
              .username,
          'keep',
        );
        expect(
          target.hostsRepository.persistedSortMode,
          HostListSortMode.manual,
        );
        expect(target.hostsRepository.persistedManualOrder.first, 'existing');
      },
    );
  });
}

class _Fixture {
  _Fixture({
    required this.hostsRepository,
    required this.hostsController,
    required this.themeController,
    required this.verifier,
    required this.service,
  });

  final FakeHostsRepository hostsRepository;
  final HostsController hostsController;
  final ThemeController themeController;
  final _MemoryVerifier verifier;
  final AppBackupService service;

  static Future<_Fixture> create({bool empty = false}) async {
    final hostsRepository = FakeHostsRepository();
    if (!empty) {
      hostsRepository.persisted = [
        const SavedHost(
          id: 'existing',
          name: 'Production',
          host: 'example.com',
          port: 2222,
          username: 'alice',
          authMethod: SshAuthMethod.hardwareKey,
          password: 'secret-password',
          hardwareKeys: [
            HardwareKeyEntry(
              id: 'key-1',
              label: 'YubiKey',
              privateKey: 'hardware-stub',
              passphrase: 'hardware-passphrase',
            ),
          ],
          tags: ['prod'],
        ),
      ];
      hostsRepository.persistedSortMode = HostListSortMode.manual;
      hostsRepository.persistedManualOrder = ['existing'];
    }
    final hostsController = HostsController(hostsRepository);
    await hostsController.load();

    final themeController = ThemeController(
      InMemoryThemePreferences(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.catppuccin,
          terminalKeyboardRows: [
            TerminalKeyboardRow(
              items: [
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
              ],
            ),
          ],
        ),
      ),
    );
    await themeController.load();

    final verifier = _MemoryVerifier(
      empty
          ? const []
          : [
              HostKeyRecord(
                host: 'example.com',
                port: 2222,
                type: 'ssh-ed25519',
                fingerprint: 'SHA256:test',
                trustedAt: DateTime.parse('2026-01-02T03:04:05Z'),
              ),
            ],
    );
    final service = AppBackupService(
      hostsController: hostsController,
      themeController: themeController,
      hostKeyVerifier: verifier,
      now: () => DateTime.parse('2026-02-03T04:05:06Z'),
    );

    return _Fixture(
      hostsRepository: hostsRepository,
      hostsController: hostsController,
      themeController: themeController,
      verifier: verifier,
      service: service,
    );
  }
}

class _MemoryVerifier implements HostKeyVerifier {
  _MemoryVerifier(List<HostKeyRecord> records) : records = List.of(records);

  List<HostKeyRecord> records;

  @override
  Future<List<HostKeyRecord>> loadTrustedKeys() async => List.of(records);

  @override
  Future<void> saveTrustedKeys(List<HostKeyRecord> records) async {
    this.records = List.of(records);
  }

  @override
  Future<void> removeTrustedKey(String host, int port) async {
    records.removeWhere((record) => record.host == host && record.port == port);
  }

  @override
  Future<bool> verify({
    required String host,
    required int port,
    required String type,
    required String fingerprint,
  }) async => true;
}
