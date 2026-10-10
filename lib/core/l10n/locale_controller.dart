import 'package:conduit/core/l10n/locale_preferences_repository.dart';
import 'package:flutter/material.dart';

/// Holds the active app language.
///
/// A `null` [locale] means "follow the system locale"; otherwise the value is
/// one of `AppLocalizations.supportedLocales`.
class LocaleController extends ChangeNotifier {
  LocaleController(this._repository);

  final LocalePreferencesRepository _repository;

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    _locale = await _repository.load();
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) {
      return;
    }
    _locale = locale;
    notifyListeners();
    await _repository.save(locale);
  }
}
