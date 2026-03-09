import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../models/employee_model.dart';

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

  /// Static method to map frontend settings to backend format
  static Map<String, dynamic> toApiJson(SettingsModel settings, int companyId) {
    String overtimeTypeStr = 'None';
    if (settings.defaultOvertimeType == OvertimeType.hourwise) {
      overtimeTypeStr = 'Hour-wise';
    } else if (settings.defaultOvertimeType == OvertimeType.slotwise) {
      overtimeTypeStr = 'Slot-wise';
    }

    return {
      'company_id': companyId,
      'salary_calculation_method':
          settings.defaultSalaryType == DefaultSalaryType.hourwise
          ? 'Hour-wise'
          : 'Day-wise',
      'hours_per_day': settings.fixedHoursPerDay,
      'days_per_month': settings.workingDaysPerMonth,
      'salary_input_type':
          settings.salaryInputType.name[0].toUpperCase() +
          settings.salaryInputType.name.substring(1),
      'overtime_enabled': settings.overtimeEnabled,
      'overtime_type': overtimeTypeStr,
      'default_overtime_rate': settings.defaultOvertimeRate,
    };
  }

  /// Static method to map backend response to SettingsModel updates
  static SettingsModel fromApiJson(
    Map<String, dynamic> json,
    SettingsModel current,
  ) {
    OvertimeType ovType = OvertimeType.none;
    final ovTypeStr = json['overtime_type'] as String?;
    if (ovTypeStr == 'Hour-wise') {
      ovType = OvertimeType.hourwise;
    } else if (ovTypeStr == 'Slot-wise') {
      ovType = OvertimeType.slotwise;
    }

    return current.copyWith(
      defaultSalaryType: json['salary_calculation_method'] == 'Hour-wise'
          ? DefaultSalaryType.hourwise
          : DefaultSalaryType.daywise,
      fixedHoursPerDay: (json['hours_per_day'] as num?)?.toDouble() ?? 8.0,
      workingDaysPerMonth: (json['days_per_month'] as int?) ?? 26,
      salaryInputType: SalaryInputType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['salary_input_type'] as String?)?.toLowerCase(),
        orElse: () => SalaryInputType.monthly,
      ),
      overtimeEnabled:
          json['overtime_enabled'] == true || json['overtime_enabled'] == 1,
      defaultOvertimeType: ovType,
      defaultOvertimeRate:
          (json['default_overtime_rate'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}
