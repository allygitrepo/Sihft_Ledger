import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'attendance_settings';

  /// Load settings from SharedPreferences
  static Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      // Return default settings if none exist
      return SettingsModel.defaultSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SettingsModel.fromJson(json);
    } catch (e) {
      return SettingsModel.defaultSettings();
    }
  }

  /// Save settings to SharedPreferences
  static Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  /// Clear settings
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }

  /// Reset to default settings
  static Future<void> resetToDefault() async {
    await saveSettings(SettingsModel.defaultSettings());
  }
}
