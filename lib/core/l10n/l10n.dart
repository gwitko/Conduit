import 'package:conduit/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:conduit/l10n/app_localizations.dart' show AppLocalizations;

/// Shorthand for `AppLocalizations.of(context)`.
///
/// `l10n.yaml` sets `nullable-getter: false`, so this never returns null and
/// callers can use `context.l10n.someMessage` directly.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Ambient access to the [AppLocalizations] the app is currently rendering.
///
/// Widget code should keep using `context.l10n`. Some layers have no
/// [BuildContext] at all — services, repositories, controllers, and
/// stream-based helpers such as `SecurityKeyInteraction` — yet still produce
/// text that ends up on screen. Threading a localization object through every
/// one of those call sites would touch a large amount of otherwise unrelated
/// code, so the root widget publishes the active instance here instead.
///
/// [install] is called from `MaterialApp.builder`, which runs below the
/// `Localizations` widget, so the value always matches the locale that is
/// actually being rendered.
abstract final class AppLocalizationsHolder {
  static AppLocalizations? _current;

  /// The localization instance for the active locale.
  ///
  /// Falls back to English before the first frame has been built, and in
  /// non-widget entry points such as `main()`.
  static AppLocalizations get current =>
      _current ?? lookupAppLocalizations(const Locale('en'));

  /// Publishes the localization instance resolved by the widget tree.
  static void install(AppLocalizations localizations) {
    _current = localizations;
  }
}
