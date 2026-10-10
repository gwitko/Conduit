import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_setup_page.dart';
import 'package:conduit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalShellSetupRequest? result;

  Future<void> pumpSetupPage(
    WidgetTester tester,
    LocalShellController controller,
  ) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<LocalShellSetupRequest>(
                MaterialPageRoute(
                  builder: (_) => LocalShellSetupPage(controller: controller),
                ),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  String nameFieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller?.text ?? '';

  testWidgets('lists the catalog and prefills the name', (tester) async {
    final controller = LocalShellController();
    await pumpSetupPage(tester, controller);

    for (final distro in controller.catalog) {
      expect(find.text(distro.name), findsWidgets);
    }
    expect(nameFieldText(tester), 'Arch Linux');
  });

  testWidgets('selecting a distro updates the suggested name', (tester) async {
    await pumpSetupPage(tester, LocalShellController());

    await tester.tap(find.text('Debian'));
    await tester.pump();
    expect(nameFieldText(tester), 'Debian');
  });

  testWidgets('a custom name survives switching distros', (tester) async {
    await pumpSetupPage(tester, LocalShellController());

    await tester.enterText(find.byType(TextField), 'Sandbox');
    await tester.tap(find.text('Ubuntu'));
    await tester.pump();
    expect(nameFieldText(tester), 'Sandbox');
  });

  testWidgets('submitting returns the chosen distro and name', (tester) async {
    await pumpSetupPage(tester, LocalShellController());

    await tester.ensureVisible(find.text('Alpine Linux'));
    await tester.tap(find.text('Alpine Linux'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Tiny box');
    await tester.ensureVisible(find.textContaining('Install ·'));
    await tester.tap(find.textContaining('Install ·'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.distroId, 'alpine');
    expect(result!.name, 'Tiny box');
  });
}
