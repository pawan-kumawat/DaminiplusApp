// ─────────────────────────────────────────────────────────────
// LocaleProvider.dart
// ChangeNotifier that holds the current Locale.
// Wrap MaterialApp with ChangeNotifierProvider<LocaleProvider>.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'AppLocalizations.dart';
import 'AppSharedPreferencesData.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = kLocaleEn;

  Locale get locale => _locale;

  /// Call once at startup to restore saved preference.
  Future<void> init() async {
    final saved = await AppSharedPreferencesData.getAppLanguage();
    _locale = saved == 'hi' ? kLocaleHi : kLocaleEn;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    // Persist even when the selected locale matches the in-memory default.
    // On a fresh install English is already the default, so returning early
    // here used to leave the preference unset and made Save appear broken.
    await AppSharedPreferencesData.saveAppLanguage(locale.languageCode);
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  bool get isHindi => _locale.languageCode == 'hi';
}
