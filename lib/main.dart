import 'dart:async';

import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/app_lock/data/local_app_authenticator.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:conduit/features/app_lock/presentation/lock_page.dart';
import 'package:conduit/features/backup/data/app_backup_service.dart';
import 'package:conduit/features/hosts/data/secure_saved_hosts_repository.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/hosts/presentation/hosts_page.dart';
import 'package:conduit/features/local_shell/data/local_terminal_repository.dart';
import 'package:conduit/features/local_shell/local_shell_licenses.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/sftp/data/dart_ssh_sftp_repository.dart';
import 'package:conduit/features/sftp/data/file_picker_file_export.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/terminal/data/connectivity_plus_network.dart';
import 'package:conduit/features/terminal/data/dart_ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/data/mosh_terminal_repository.dart';
import 'package:conduit/features/terminal/data/routing_terminal_repository.dart';
import 'package:conduit/features/terminal/data/secure_host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_coordinator.dart';
import 'package:conduit/features/terminal/presentation/terminal_background_keepalive.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerLocalShellLicenses();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  const secureStorage = FlutterSecureStorage();
  final themeController = ThemeController(
    const ThemePreferencesRepository(secureStorage),
  );
  final lockController = AppLockController(LocalAppAuthenticator());
  final hostsController = HostsController(
    const SecureSavedHostsRepository(secureStorage),
  );
  final promptCoordinator = HostKeyPromptCoordinator();
  final hostKeyVerifier = SecureHostKeyVerifier(
    secureStorage,
    promptCoordinator,
  );
  final localShellController = LocalShellController();
  final terminalRepository = RoutingTerminalRepository(
    ssh: DartSshTerminalRepository(hostKeyVerifier),
    mosh: MoshTerminalRepository(hostKeyVerifier),
    local: LocalTerminalRepository(
      resolvePaths: localShellController.requirePaths,
    ),
  );
  final workspaceController = TerminalWorkspaceController(
    terminalRepository,
    ConnectivityPlusNetwork(),
  );
  final sftpRepository = DartSshSftpRepository(hostKeyVerifier);
  final backupService = AppBackupService(
    hostsController: hostsController,
    themeController: themeController,
    hostKeyVerifier: hostKeyVerifier,
  );
  const fileExport = FilePickerFileExport();

  unawaited(themeController.load());

  runApp(
    ConduitApp(
      themeController: themeController,
      lockController: lockController,
      hostsController: hostsController,
      terminalRepository: terminalRepository,
      workspaceController: workspaceController,
      localShellController: localShellController,
      hostKeyVerifier: hostKeyVerifier,
      promptCoordinator: promptCoordinator,
      sftpRepository: sftpRepository,
      backupService: backupService,
      fileExport: fileExport,
    ),
  );
}

class ConduitApp extends StatefulWidget {
  const ConduitApp({
    required this.themeController,
    required this.lockController,
    required this.hostsController,
    required this.terminalRepository,
    required this.workspaceController,
    required this.localShellController,
    required this.hostKeyVerifier,
    required this.promptCoordinator,
    required this.sftpRepository,
    required this.backupService,
    required this.fileExport,
    super.key,
  });

  final ThemeController themeController;
  final AppLockController lockController;
  final HostsController hostsController;
  final SshTerminalRepository terminalRepository;
  final TerminalWorkspaceController workspaceController;
  final LocalShellController localShellController;
  final HostKeyVerifier hostKeyVerifier;
  final HostKeyPromptCoordinator promptCoordinator;
  final SftpRepository sftpRepository;
  final AppBackupService backupService;
  final FileExport fileExport;

  @override
  State<ConduitApp> createState() => _ConduitAppState();
}

class _ConduitAppState extends State<ConduitApp> with WidgetsBindingObserver {
  final _backgroundKeepalive = const TerminalBackgroundKeepalive();
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _keepaliveRunning = false;
  int _keepaliveSessionCount = 0;
  bool _notificationPermissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.workspaceController.addListener(_syncBackgroundKeepalive);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncBackgroundKeepalive();

    if (state == AppLifecycleState.resumed) {
      for (final session in widget.workspaceController.sessions) {
        session.forceResize();
      }
    }
  }

  void _syncBackgroundKeepalive() {
    final sessionCount = widget.workspaceController.liveSessionCount;
    _maybeRequestNotificationPermission(sessionCount);
    final shouldRun =
        sessionCount > 0 &&
        (_lifecycleState == AppLifecycleState.hidden ||
            _lifecycleState == AppLifecycleState.paused);

    if (shouldRun == _keepaliveRunning &&
        (!shouldRun || sessionCount == _keepaliveSessionCount)) {
      return;
    }

    _keepaliveRunning = shouldRun;
    _keepaliveSessionCount = shouldRun ? sessionCount : 0;
    unawaited(
      (shouldRun
              ? _backgroundKeepalive.start(sessionCount: sessionCount)
              : _backgroundKeepalive.stop())
          .catchError((_) {
            _keepaliveRunning = !shouldRun;
            _keepaliveSessionCount = 0;
          }),
    );
  }

  void _maybeRequestNotificationPermission(int sessionCount) {
    if (_notificationPermissionRequested ||
        sessionCount == 0 ||
        _lifecycleState != AppLifecycleState.resumed ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _notificationPermissionRequested = true;
    unawaited(
      _backgroundKeepalive.requestNotificationPermission().catchError((_) {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.workspaceController.removeListener(_syncBackgroundKeepalive);
    unawaited(_backgroundKeepalive.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Conduit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(
            brightness: Brightness.light,
            palette: widget.themeController.palette,
          ),
          darkTheme: AppTheme.build(
            brightness: Brightness.dark,
            palette: widget.themeController.palette,
          ),
          themeMode: widget.themeController.themeMode,
          builder: (context, child) {
            final overlayStyle = AppTheme.systemUiOverlayStyle(
              Theme.of(context).brightness,
            );
            SystemChrome.setSystemUIOverlayStyle(overlayStyle);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  AndroidThreeButtonNavigationBackground(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ],
              ),
            );
          },
          home: ListenableBuilder(
            listenable: widget.lockController,
            builder: (context, _) {
              if (!widget.lockController.isUnlocked) {
                return LockPage(
                  controller: widget.lockController,
                  themeController: widget.themeController,
                );
              }

              return HostsPage(
                hostsController: widget.hostsController,
                lockController: widget.lockController,
                terminalRepository: widget.terminalRepository,
                workspaceController: widget.workspaceController,
                localShellController: widget.localShellController,
                themeController: widget.themeController,
                hostKeyVerifier: widget.hostKeyVerifier,
                promptCoordinator: widget.promptCoordinator,
                sftpRepository: widget.sftpRepository,
                backupService: widget.backupService,
                fileExport: widget.fileExport,
              );
            },
          ),
        );
      },
    );
  }
}
