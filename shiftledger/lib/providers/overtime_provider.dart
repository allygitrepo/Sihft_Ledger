import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'company_provider.dart';

class OvertimeState {
  final List<OvertimeSlot> slots;
  final Map<String, EmployeeOvertimeConfig> employeeConfigs;
  final bool isLoading;
  final String? error;

  OvertimeState({
    this.slots = const [],
    this.employeeConfigs = const {},
    this.isLoading = false,
    this.error,
  });

  OvertimeState copyWith({
    List<OvertimeSlot>? slots,
    Map<String, EmployeeOvertimeConfig>? employeeConfigs,
    bool? isLoading,
    String? error,
  }) {
    return OvertimeState(
      slots: slots ?? this.slots,
      employeeConfigs: employeeConfigs ?? this.employeeConfigs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmployeeOvertimeConfig {
  final bool overtimeEnabled;
  final double hourlyRate;

  EmployeeOvertimeConfig({
    required this.overtimeEnabled,
    required this.hourlyRate,
  });

  factory EmployeeOvertimeConfig.fromJson(Map<String, dynamic> json) {
    return EmployeeOvertimeConfig(
      overtimeEnabled: json['overtime_enabled'] as bool? ?? false,
      hourlyRate: (json['hourly_rate'] as num? ?? 0.0).toDouble(),
    );
  }
}

class OvertimeNotifier extends Notifier<OvertimeState> {
  @override
  OvertimeState build() {
    // Re-load when company or auth changes
    ref.watch(authProvider);
    ref.watch(companyProvider);

    // Initial check in case they are already ready
    Future.microtask(() => _checkAndLoad());

    return OvertimeState();
  }

  void _checkAndLoad() {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token != null && companyId != null) {
      loadSlots();
    }
  }

  Future<void> loadSlots() async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.getOvertimeSlots(companyId, token);
      if (response['success'] == true) {
        final List<dynamic> data = response['slots'] ?? [];
        final slots = data.map((json) => OvertimeSlot.fromJson(json)).toList();
        state = state.copyWith(slots: slots, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load overtime slots',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveSlots(List<OvertimeSlot> slotsToSave) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // For simplicity, we create new ones or delete all and recreate
      // The backend has create and update. Let's try to handle them.
      for (var slot in slotsToSave) {
        final data = slot.toJson();
        data['company_id'] = companyId;

        final Map<String, dynamic> response;
        if (slot.id != null) {
          response = await ApiService.updateOvertimeSlot(
            slot.id.toString(),
            data,
            token,
          );
        } else {
          response = await ApiService.createOvertimeSlot(data, token);
        }

        if (response['success'] != true) {
          state = state.copyWith(
            isLoading: false,
            error: response['message'] ?? 'Failed to save a slot',
          );
          return false;
        }
      }

      // Reload slots to get fresh state including IDs for new slots
      await loadSlots();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadEmployeeConfig(String employeeId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final response = await ApiService.getEmployeeOvertimeConfig(
        employeeId,
        token,
      );
      if (response['success'] == true && response['config'] != null) {
        final config = EmployeeOvertimeConfig.fromJson(response['config']);
        final updatedConfigs = Map<String, EmployeeOvertimeConfig>.from(
          state.employeeConfigs,
        );
        updatedConfigs[employeeId] = config;
        state = state.copyWith(employeeConfigs: updatedConfigs);
      }
    } catch (e) {
      print('Error loading employee overtime config: $e');
    }
  }

  Future<bool> saveEmployeeConfig({
    required String employeeId,
    required bool overtimeEnabled,
    required double hourlyRate,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    try {
      final response = await ApiService.saveEmployeeOvertimeConfig({
        'employee_id': int.parse(employeeId),
        'overtime_enabled': overtimeEnabled,
        'hourly_rate': hourlyRate,
      }, token);

      if (response['success'] == true) {
        await loadEmployeeConfig(employeeId);
        return true;
      } else {
        state = state.copyWith(
          error:
              response['message'] ?? 'Failed to save employee overtime config',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSlot(int slotId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    try {
      final response = await ApiService.deleteOvertimeSlot(
        slotId.toString(),
        token,
      );
      if (response['success'] == true) {
        await loadSlots();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final overtimeProvider = NotifierProvider<OvertimeNotifier, OvertimeState>(() {
  return OvertimeNotifier();
});
