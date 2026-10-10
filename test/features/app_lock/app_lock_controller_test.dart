import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/app_lock/domain/app_authenticator.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/test_doubles.dart';

void main() {
  group('AppLockController', () {
    test('unavailable device shows continue-anyway path', () async {
      final controller = AppLockController(UnavailableAuthenticator());
      await controller.unlock(AppLocalizationsHolder.current);
      expect(controller.status, AppLockStatus.unavailable);
      controller.continueWithoutAuth();
      expect(controller.isUnlocked, isTrue);
    });

    test('cancelled auth keeps the app locked', () async {
      final controller = AppLockController(
        ScriptedAuthenticator(AppAuthenticationResult.cancelled),
      );
      await controller.unlock(AppLocalizationsHolder.current);
      expect(controller.status, AppLockStatus.locked);
      expect(controller.notice, isNotNull);
    });

    test('successful auth unlocks', () async {
      final controller = AppLockController(AlwaysAuthenticates());
      await controller.unlock(AppLocalizationsHolder.current);
      expect(controller.isUnlocked, isTrue);
    });

    test('auth errors return to the locked state', () async {
      final controller = AppLockController(const ThrowingAuthenticator());
      await controller.unlock(AppLocalizationsHolder.current);
      expect(controller.status, AppLockStatus.locked);
      expect(controller.notice, isNotNull);
    });

    test('availability errors show the unavailable path', () async {
      final controller = AppLockController(
        const ThrowingAuthenticator(throwFromCanAuthenticate: true),
      );
      await controller.unlock(AppLocalizationsHolder.current);
      expect(controller.status, AppLockStatus.unavailable);
    });
  });
}
