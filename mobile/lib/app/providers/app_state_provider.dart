import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('uz', 'LATN'));

  void setLocale(String lang) {
    if (lang.contains('Ru') || lang.contains('Рус')) {
      state = const Locale('ru', 'RU');
    } else if (lang.contains('En') || lang.contains('Eng')) {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('uz', 'LATN');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
