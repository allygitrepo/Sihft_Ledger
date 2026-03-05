import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../widgets/toast.dart';

class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    _loadSettings();
    return SettingsModel.defaultSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.loadSettings();
    state = settings;
  }

  Future<void> updateSettings(SettingsModel settings) async {
    state = settings;
    await SettingsService.saveSettings(state);
  }

  Future<void> updateAttendanceType(PayrollAttendanceType type) async {
    state = state.copyWith(attendanceType: type);
    await SettingsService.saveSettings(state);
    ToastHelper.success('Attendance type updated');
  }

  Future<void> updateOvertimeMultiplier(double multiplier) async {
    if (multiplier < 1.0 || multiplier > 5.0) {
      ToastHelper.error('Overtime multiplier must be between 1.0 and 5.0');
      return;
    }
    state = state.copyWith(overtimeMultiplier: multiplier);
    await SettingsService.saveSettings(state);
    ToastHelper.success('Overtime multiplier updated');
  }

  Future<void> updateSalaryCycle(SalaryCycle cycle) async {
    state = state.copyWith(salaryCycle: cycle);
    await SettingsService.saveSettings(state);
    ToastHelper.success('Salary cycle updated');
  }

  Future<void> updateCustomDateRange(DateTime? start, DateTime? end) async {
    state = state.copyWith(customStartDate: start, customEndDate: end);
    await SettingsService.saveSettings(state);
    ToastHelper.success('Custom date range updated');
  }

  Future<void> updateMinimumHours(double hours) async {
    if (hours < 1.0 || hours > 24.0) {
      ToastHelper.error('Minimum hours must be between 1.0 and 24.0');
      return;
    }
    state = state.copyWith(minimumHours: hours);
    await SettingsService.saveSettings(state);
    ToastHelper.success('Minimum hours updated');
  }

  Future<void> resetSettings() async {
    state = SettingsModel.defaultSettings();
    await SettingsService.saveSettings(state);
    ToastHelper.success('Settings reset to default');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(() {
  return SettingsNotifier();
});
