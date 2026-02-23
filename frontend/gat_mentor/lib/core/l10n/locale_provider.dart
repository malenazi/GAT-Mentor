import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSaved();
  }

  static const _key = 'app_locale';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'en';
    state = Locale(lang);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  void toggleLocale() {
    final next =
        state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    setLocale(next);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
