import 'package:conduit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's language choice.
///
/// A stored [Locale] means the user picked that language explicitly; `null`
/// means "follow the system locale".
class LocalePreferencesRepository {
  const LocalePreferencesRepository(this._storage);

  static const _localeKey = 'conduit.locale.v1';

  final FlutterSecureStorage _storage;

  Future<Locale?> load() async {
    final raw = await _storage.read(key: _localeKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == raw) {
        return locale;
      }
    }
    return null;
  }

  Future<void> save(Locale? locale) async {
    await _storage.write(key: _localeKey, value: locale?.languageCode ?? '');
  }
}
