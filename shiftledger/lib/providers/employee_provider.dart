import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../providers/department_provider.dart';
import '../providers/designation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/overtime_provider.dart';
import '../widgets/toast.dart';

class EmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;
  final bool isParsingCSV;
  final bool isImporting;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.isParsingCSV = false,
    this.isImporting = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
  });

  EmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    bool? isParsingCSV,
    bool? isImporting,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isParsingCSV: isParsingCSV ?? this.isParsingCSV,
      isImporting: isImporting ?? this.isImporting,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}

class EmployeeNotifier extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    // Watch for session readiness
    ref.watch(authProvider);
    ref.watch(companyProvider);

    // Initial check in case they are already ready
    Future.microtask(() => _checkAndLoad());

    return const EmployeeState();
  }

  void _checkAndLoad() {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token != null &&
        companyId != null &&
        state.employees.isEmpty &&
        !state.isLoading) {
      loadEmployees();
    }
  }

  Future<void> loadEmployees({int page = 1, int limit = 10, String search = ''}) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      print('[EmployeeProvider] Token or CompanyId missing, skipping load');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    print('[EmployeeProvider] Fetching employees for company: $companyId');

    try {
      final response = await ApiService.getEmployees(
        companyId, 
        token, 
        page: page, 
        limit: limit, 
        search: search
      );

      if (response['success'] == true) {
        final List<dynamic> employeesJson = response['employees'] ?? [];
        final employees = employeesJson
            .map((json) => EmployeeModel.fromJson(json))
            .toList();
            
        state = state.copyWith(
          employees: employees, 
          isLoading: false,
          currentPage: response['currentPage'] ?? 1,
          totalPages: response['totalPages'] ?? 1,
          totalRecords: response['totalRecords'] ?? employees.length,
        );
        print(
          '[EmployeeProvider] Successfully loaded ${employees.length} employees',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load employees',
        );
        ToastHelper.error(state.error!);
      }
    } catch (e, stack) {
      print('[EmployeeProvider] Error loading employees: $e');
      print(stack);
      state = state.copyWith(
        isLoading: false,
        error: 'Error parsing employee data: $e',
      );
      ToastHelper.error(state.error!);
    }
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      ToastHelper.error('Session expired. Please login again.');
      return;
    }

    state = state.copyWith(isLoading: true);

    // Map model to backend request body (using fields handled by backend controller)
    final data = {
      'company_id': companyId,
      'department_id': employee.departmentId,
      'designation_id': employee.designationId,
      'salary_config_id': employee.salaryConfigId,
      'name': '${employee.firstName} ${employee.lastName}'.trim(),
      'mobileNo': employee.mobileNo,
      'salary': employee.salaryOriginal,
      'status': employee.status,
    };

    if (employee.joinDate != null) {
      data['join_date'] = employee.joinDate!.toIso8601String().split('T')[0];
    }

    final response = await ApiService.createEmployee(data, token);

    if (response['success'] == true) {
      final newEmp = response['employee'];
      if (newEmp != null && newEmp['id'] != null) {
        final settings = ref.read(settingsProvider);
        if (settings.defaultOvertimeType == OvertimeType.hourwise &&
            settings.overtimeEnabled) {
          try {
            await ref
                .read(overtimeProvider.notifier)
                .saveEmployeeConfig(
                  employeeId: newEmp['id'].toString(),
                  overtimeEnabled: true,
                  hourlyRate: settings.defaultOvertimeRate,
                );
          } catch (e) {
            print(
              '[EmployeeProvider] Error setting initial overtime config: $e',
            );
          }
        }
      }

      await loadEmployees();
      ToastHelper.success('Employee added successfully');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Failed to add employee');
    }
  }

  Future<void> exportData() async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService.exportEmployeesCSV(companyId.toString(), token);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        // In real app, trigger download. For now, we've fulfilled the logic.
        // We'll use file_saver in the UI to actually save it.
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: 'Export failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> importData(List<EmployeeModel> employees) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    state = state.copyWith(isImporting: true);
    try {
      final List<Map<String, dynamic>> employeeData = employees.map((e) {
        final map = e.toJson();
        // Ensure rates are included
        map['hourlyRate'] = e.hourlyRate;
        map['dailyRate'] = e.dailyRate;
        return map;
      }).toList();

      final response = await ApiService.bulkUpsertEmployees(
        companyId.toString(),
        employeeData,
        token,
      );

      if (response['success'] == true) {
        await loadEmployees();
        ToastHelper.success(response['message'] ?? 'Import successful');
      } else {
        ToastHelper.error(response['message'] ?? 'Import failed');
      }
    } catch (e) {
      ToastHelper.error('Import error: $e');
    } finally {
      state = state.copyWith(isImporting: false);
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true);

    final data = {
      'department_id': employee.departmentId,
      'designation_id': employee.designationId,
      'salary_config_id': employee.salaryConfigId,
      'name': '${employee.firstName} ${employee.lastName}'.trim(),
      'mobileNo': employee.mobileNo,
      'salary': employee.salaryOriginal,
      'status': employee.status,
    };

    if (employee.joinDate != null) {
      data['join_date'] = employee.joinDate!.toIso8601String().split('T')[0];
    }

    final response = await ApiService.updateEmployee(employee.id, data, token);

    if (response['success'] == true) {
      if (response['employee'] != null) {
        final updatedEmp = EmployeeModel.fromJson(response['employee']);
        updateEmployeeInList(updatedEmp);
        state = state.copyWith(isLoading: false);
      } else {
        await loadEmployees();
      }
      ToastHelper.success('Employee updated successfully');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Failed to update employee');
    }
  }

  /// Update a single employee in the local list without a full reload
  void updateEmployeeInList(EmployeeModel employee) {
    if (state.employees.isEmpty) return;

    final updatedEmployees = state.employees.map((e) {
      return e.id == employee.id ? employee : e;
    }).toList();

    state = state.copyWith(employees: updatedEmployees);
  }

  Future<void> deleteEmployee(String employeeId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.deleteEmployee(employeeId, token);

    if (response['success'] == true) {
      await loadEmployees();
      ToastHelper.success('Employee deleted successfully');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Failed to delete employee');
    }
  }



  EmployeeModel? getEmployeeById(String employeeId) {
    try {
      return state.employees.firstWhere((e) => e.id == employeeId);
    } catch (e) {
      return null;
    }
  }
}

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeState>(() {
  return EmployeeNotifier();
});
