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
  static Map<String, dynamic> toApiJson(SettingsModel settings, dynamic companyId) {
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
      'overtime_slots': settings.overtimeSlots.map((s) => s.toJson()).toList(),
      'full_day_hours': settings.fullDayHours,
      'half_day_hours': settings.halfDayHours,
      'break_minutes': settings.breakMinutes,
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
      defaultSalaryType: (json['salary_calculation_method'] == 'Hour-wise' ||
              json['salary_calculation_method'] == 'hourwise')
          ? DefaultSalaryType.hourwise
          : (json['salary_calculation_method'] == 'Day-wise' ||
                  json['salary_calculation_method'] == 'daywise')
              ? DefaultSalaryType.daywise
              : current.defaultSalaryType,
      fixedHoursPerDay: _parseDouble(
        json['hours_per_day'] ?? json['fixedHoursPerDay'],
        defaultValue: current.fixedHoursPerDay,
      ),
      workingDaysPerMonth:
          _parseInt(json['days_per_month'] ?? json['workingDaysPerMonth']) ??
          current.workingDaysPerMonth,
      salaryInputType: SalaryInputType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['salary_input_type'] as String?)?.toLowerCase(),
        orElse: () => current.salaryInputType,
      ),
      overtimeEnabled: json['overtime_enabled'] != null
          ? (json['overtime_enabled'] == true ||
              json['overtime_enabled'] == 1 ||
              json['overtime_enabled'] == '1' ||
              json['overtime_enabled'] == 'true')
          : current.overtimeEnabled,
      defaultOvertimeType: ovType != OvertimeType.none
          ? ovType
          : (json['overtimeType'] != null || json['overtime_type_name'] != null)
              ? OvertimeType.values.firstWhere(
                (e) =>
                    e.name == json['overtimeType'] ||
                    e.name == json['overtime_type_name'],
                orElse: () => current.defaultOvertimeType,
              )
              : current.defaultOvertimeType,
      defaultOvertimeRate: _parseDouble(
        json['default_overtime_rate'] ??
            json['defaultOvertimeRate'] ??
            json['overtime_rate'] ??
            json['overtimeRate'],
        defaultValue: current.defaultOvertimeRate,
      ),
      overtimeSlots:
          (json['overtime_slots'] as List<dynamic>?)
              ?.map((s) => OvertimeSlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          current.overtimeSlots,
      fullDayHours: _parseDouble(
        json['full_day_hours'] ?? json['fullDayHours'],
        defaultValue: current.fullDayHours,
      ),
      halfDayHours: _parseDouble(
        json['half_day_hours'] ?? json['halfDayHours'],
        defaultValue: current.halfDayHours,
      ),
      breakMinutes:
          _parseInt(json['break_minutes'] ?? json['breakMinutes']) ??
          current.breakMinutes,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : current.updatedAt ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
