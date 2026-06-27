import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_coordinator.dart';
import 'package:conduit/features/terminal/presentation/terminal_page.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/main.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/test_doubles.dart';

void main() {
  group('system navigation insets', () {
    test('keeps Android gesture navigation edge-to-edge', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.android,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isFalse,
      );
    });

    test('protects Android three-button navigation', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.android,
          systemGestureInsets: EdgeInsets.zero,
        ),
        isTrue,
      );
      expect(
        shouldPaintAndroidThreeButtonNavigationBackgroundFor(
          platform: TargetPlatform.android,
          systemGestureInsets: EdgeInsets.zero,
        ),
        isTrue,
      );
    });

    test('preserves safe areas on non-Android platforms', () {
      expect(
        shouldApplyBottomSafeAreaFor(
          platform: TargetPlatform.iOS,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isTrue,
      );
      expect(
        shouldPaintAndroidThreeButtonNavigationBackgroundFor(
          platform: TargetPlatform.iOS,
          systemGestureInsets: const EdgeInsets.only(bottom: 24),
        ),
        isFalse,
      );
    });
  });

  testWidgets('unlocks into the saved machine list', (tester) async {
    final promptCoordinator = HostKeyPromptCoordinator();
    final verifier = NoopVerifier();
    await tester.pumpWidget(
      ConduitApp(
        lockController: AppLockController(AlwaysAuthenticates()),
        themeController: ThemeController(InMemoryThemePreferences()),
        hostsController: HostsController(EmptyHostsRepository()),
        terminalRepository: NoNetworkTerminalRepository(),
        workspaceController: TerminalWorkspaceController(
          NoNetworkTerminalRepository(),
        ),
        localShellController: LocalShellController(),
        hostKeyVerifier: verifier,
        promptCoordinator: promptCoordinator,
        sftpRepository: NoNetworkSftpRepository(),
        fileExport: RecordingFileExport(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Saved machines'), findsOneWidget);
    expect(find.text('No saved machines yet'), findsOneWidget);
    expect(find.text('Add machine'), findsOneWidget);
    expect(find.text('New machine'), findsNothing);
  });

  testWidgets('hides local shell entry when disabled in appearance', (
    tester,
  ) async {
    final promptCoordinator = HostKeyPromptCoordinator();
    final verifier = NoopVerifier();
    final themeController = ThemeController(
      InMemoryThemePreferences(
        const ThemePreferences(
          themeMode: ThemeMode.system,
          palette: AppPalette.catppuccin,
          showLocalShell: false,
        ),
      ),
    );
    await themeController.load();

    await tester.pumpWidget(
      ConduitApp(
        lockController: AppLockController(AlwaysAuthenticates()),
        themeController: themeController,
        hostsController: HostsController(EmptyHostsRepository()),
        terminalRepository: NoNetworkTerminalRepository(),
        workspaceController: TerminalWorkspaceController(
          NoNetworkTerminalRepository(),
        ),
        localShellController: _VisibleLocalShellController(),
        hostKeyVerifier: verifier,
        promptCoordinator: promptCoordinator,
        sftpRepository: NoNetworkSftpRepository(),
        fileExport: RecordingFileExport(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Device'), findsNothing);
    expect(find.text('Local shell'), findsNothing);
    expect(find.text('Saved machines'), findsOneWidget);
  });

  test('workspace opens, focuses, and closes machine tabs', () async {
    final workspace = TerminalWorkspaceController(
      CompletingTerminalRepository(),
    );
    const firstHost = SavedHost(
      id: 'first',
      name: 'First',
      host: '192.168.1.10',
      port: 22,
      username: 'user',
      authMethod: SshAuthMethod.password,
      password: 'password',
    );
    const secondHost = SavedHost(
      id: 'second',
      name: 'Second',
      host: '192.168.1.11',
      port: 22,
      username: 'user',
      authMethod: SshAuthMethod.password,
      password: 'password',
    );

    final firstSession = workspace.open(firstHost);
    final duplicateFirstSession = workspace.open(firstHost);
    final secondSession = workspace.open(secondHost);

    expect(workspace.sessions, hasLength(2));
    expect(duplicateFirstSession, same(firstSession));
    expect(workspace.activeSession, same(secondSession));
    expect(workspace.liveSessionCount, 0);

    await firstSession.connect();
    expect(workspace.liveSessionCount, 1);
    await secondSession.connect();
    expect(workspace.liveSessionCount, 2);

    workspace.activate(firstSession);
    expect(workspace.activeSession, same(firstSession));

    await workspace.close(firstSession);
    expect(workspace.sessions, hasLength(1));
    expect(workspace.activeSession, same(secondSession));
    expect(workspace.liveSessionCount, 1);

    await workspace.closeAll();
    expect(workspace.sessions, isEmpty);
    expect(workspace.liveSessionCount, 0);
  });

  testWidgets('pinch zoom changes the terminal appearance font size', (
    tester,
  ) async {
    final themeController = ThemeController(InMemoryThemePreferences());
    await themeController.load();
    final workspace = TerminalWorkspaceController(
      ImmediateTerminalRepository(FakeTerminalSession()),
    );
    addTearDown(workspace.dispose);
    workspace.open(buildHost('zoom'));

    await tester.pumpWidget(
      MaterialApp(
        home: TerminalPage(
          workspace: workspace,
          themeController: themeController,
        ),
      ),
    );
    await tester.pump();

    final initialFontSize = themeController.terminalFontSize;
    final terminalCenter = tester.getCenter(find.byType(TerminalView));
    final firstFinger = await tester.createGesture(pointer: 1);
    final secondFinger = await tester.createGesture(pointer: 2);

    await firstFinger.down(terminalCenter.translate(-40, 0));
    await secondFinger.down(terminalCenter.translate(40, 0));
    await tester.pump();
    await firstFinger.moveTo(terminalCenter.translate(-80, 0));
    await secondFinger.moveTo(terminalCenter.translate(80, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump(const Duration(milliseconds: 300));

    expect(themeController.terminalFontSize, greaterThan(initialFontSize));
  });

  test('terminal font size supports the wider zoom range', () async {
    final themeController = ThemeController(InMemoryThemePreferences());
    await themeController.load();

    await themeController.setTerminalFontSize(terminalFontSizeMin - 1);
    expect(themeController.terminalFontSize, terminalFontSizeMin);

    await themeController.setTerminalFontSize(terminalFontSizeMax + 1);
    expect(themeController.terminalFontSize, terminalFontSizeMax);
  });
}

class _VisibleLocalShellController extends LocalShellController {
  @override
  LocalShellState get state => LocalShellState.notInstalled;

  @override
  Future<void> refresh() async {}
}
