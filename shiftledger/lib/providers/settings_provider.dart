import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'company_provider.dart';
import '../widgets/toast.dart';

/// Provider to track when settings are being synchronized with the backend.
final settingsSyncProvider = StateProvider<bool>((ref) => false);

/// Provider to track if settings have been loaded from API at least once
final settingsLoadedProvider = StateProvider<bool>((ref) => false);

class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    // Watch for dependencies
    ref.watch(authProvider);
    ref.watch(companyProvider);

    // Initial load from local storage
    _loadLocalSettings();

    // Trigger async load from API if already ready
    Future.microtask(() => loadApiSettings());

    return SettingsModel.defaultSettings();
  }

  Future<void> _loadLocalSettings() async {
    final settings = await SettingsService.loadSettings();
    state = settings;
  }

  Future<void> loadApiSettings() async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      print('[SettingsProvider] Aborting loadApiSettings: token=$token, companyId=$companyId');
      ref.read(settingsLoadedProvider.notifier).state = true;
      return;
    }

    print('[SettingsProvider] Loading API settings for companyId: $companyId');
    ref.read(settingsSyncProvider.notifier).state = true;

    try {
      final response = await ApiService.getSalaryConfig(companyId, token);

      if (response['success'] == true) {
        // Try multiple possible keys for config data
        dynamic configData = response['config'] ?? 
                            response['salary_config'] ?? 
                            response['data'] ?? 
                            response['salaryConfig'];
        
        if (configData == null) {
          print('[SettingsProvider] No config data found in response keys: config, salary_config, data, salaryConfig');
          ref.read(settingsLoadedProvider.notifier).state = true;
          return;
        }
        
        // Handle case where config might be returned as a list with one item
        if (configData is List && configData.isNotEmpty) {
          configData = configData[0];
          print('[SettingsProvider] Config data extracted from singleton list');
        }

        if (configData is Map<String, dynamic>) {
          print('[SettingsProvider] Config data: $configData');
          final updatedSettings = SettingsService.fromApiJson(
            configData,
            state,
          );
          state = updatedSettings;
          print('[SettingsProvider] API Settings loaded: ${state.fixedHoursPerDay} hrs, ${state.workingDaysPerMonth} days');
          
          // Also save locally to keep in sync
          await SettingsService.saveSettings(state);
          ref.read(settingsLoadedProvider.notifier).state = true;
        } else {
          print('[SettingsProvider] Invalid config data format: ${configData.runtimeType}');
          ref.read(settingsLoadedProvider.notifier).state = true;
        }
      }
    } catch (e) {
      print('[SettingsProvider] Error loading API settings: $e');
      // Mark as loaded even on error to prevent blocking UI
      ref.read(settingsLoadedProvider.notifier).state = true;
    } finally {
      ref.read(settingsSyncProvider.notifier).state = false;
    }
  }

  Future<bool> updateSettings(SettingsModel settings) async {
    state = settings;

    // Save locally
    await SettingsService.saveSettings(state);

    // Save to API
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token != null && companyId != null) {
      ref.read(settingsSyncProvider.notifier).state = true;
      try {
        final apiData = SettingsService.toApiJson(state, companyId);
        final response = await ApiService.saveSalaryConfig(apiData, token);

        return response['success'] == true;
      } catch (e) {
        print('[SettingsProvider] Error saving to API: $e');
        return false;
      } finally {
        ref.read(settingsSyncProvider.notifier).state = false;
      }
    }

    return true; // Successfully saved locally even if no API available
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

    // Also reset on API if possible
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;
    if (token != null && companyId != null) {
      ref.read(settingsSyncProvider.notifier).state = true;
      try {
        final apiData = SettingsService.toApiJson(state, companyId);
        await ApiService.saveSalaryConfig(apiData, token);
      } catch (e) {
        print('[SettingsProvider] Error resetting API settings: $e');
      } finally {
        ref.read(settingsSyncProvider.notifier).state = false;
      }
    }

    ToastHelper.success('Settings reset to default');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(() {
  return SettingsNotifier();
});
