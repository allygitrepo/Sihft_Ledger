import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum AppThemeMode { system, light, dark }

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'theme_mode';
  
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadThemeFromStorage();
  }
  
  Future<void> _loadThemeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getInt(_themeKey);
    if (savedTheme != null && savedTheme < AppThemeMode.values.length) {
      state = AppThemeMode.values[savedTheme];
    }
  }
  
  Future<void> changeThemeMode(AppThemeMode themeMode) async {
    state = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }
  
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
  
  bool isDarkMode(BuildContext context) {
    if (state == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return state == AppThemeMode.dark;
  }
}

// Provider for theme management
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});