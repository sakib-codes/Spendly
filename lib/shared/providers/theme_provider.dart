import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeStr = prefs.getString('themeMode') ?? 'dark';
    return _fromString(themeStr);
  }
  
  ThemeMode _fromString(String str) {
    switch (str) {
      case 'light': return ThemeMode.light;
      case 'system': return ThemeMode.system;
      case 'dark': 
      default: return ThemeMode.dark;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    prefs.setString('themeMode', str);
  }
}
