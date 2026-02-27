import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import 'settings_service.dart';

class SetupService {
  static const String _setupCompletedKey = 'is_setup_completed';

  /// Check if setup is completed
  static Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompletedKey) ?? false;
  }

  /// Mark setup as completed
  static Future<void> completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, true);
  }

  /// Reset setup (for testing or re-registration)
  static Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupCompletedKey);
  }

  /// Initialize default settings after company registration
  static Future<void> initializeDefaultSettings() async {
    final defaultSettings = SettingsModel.defaultSettings();
    await SettingsService.saveSettings(defaultSettings);
  }

  /// Complete the entire setup process
  /// This should be called after company registration
  static Future<void> finalizeSetup() async {
    // Initialize default settings
    await initializeDefaultSettings();
    
    // Mark setup as completed
    await completeSetup();
  }
}
