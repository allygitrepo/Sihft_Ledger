import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../providers/department_provider.dart';
import '../providers/designation_provider.dart';
import '../widgets/toast.dart';

class EmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;
  final bool isParsingCSV;
  final bool isImporting;
  final String? error;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.isParsingCSV = false,
    this.isImporting = false,
    this.error,
  });

  EmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    bool? isParsingCSV,
    bool? isImporting,
    String? error,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isParsingCSV: isParsingCSV ?? this.isParsingCSV,
      isImporting: isImporting ?? this.isImporting,
      error: error ?? this.error,
    );
  }
}

class EmployeeNotifier extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    print('[EmployeeProvider] Initializing provider...');
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      print('[EmployeeProvider] Token or CompanyId missing, skipping load');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    print('[EmployeeProvider] Fetching employees for company: $companyId');

    final response = await ApiService.getEmployees(companyId, token);

    if (response['success'] == true) {
      final List<dynamic> employeesJson = response['employees'] ?? [];
      final employees = employeesJson
          .map((json) => EmployeeModel.fromJson(json))
          .toList();
      state = state.copyWith(employees: employees, isLoading: false);
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
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      ToastHelper.error('Session expired. Please login again.');
      return;
    }

    state = state.copyWith(isLoading: true);

    // Map model to backend request body
    final data = {
      'company_id': companyId,
      'department_id': employee.departmentId,
      'designation_id': employee.designationId,
      'employee_code': employee.employeeCode,
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'phone': employee.mobileNo,
      'email': null, // Optional
      'join_date': DateTime.now().toIso8601String().split('T')[0],
      'basic_salary': employee.salaryOriginal,
      'allowances': 0,
      'deductions': 0,
      'net_salary': employee.salaryOriginal,
      'overtime_enabled': employee.overtimeType != OvertimeType.none,
      'hourly_rate': employee.overtimeRate,
    };

    final response = await ApiService.createEmployee(data, token);

    if (response['success'] == true) {
      await loadEmployees();
      ToastHelper.success('Employee added successfully');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Failed to add employee');
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true);

    final data = {
      'department_id': employee.departmentId,
      'designation_id': employee.designationId,
      'employee_code': employee.employeeCode,
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'phone': employee.mobileNo,
      'basic_salary': employee.salaryOriginal,
      'overtime_enabled': employee.overtimeType != OvertimeType.none,
      'hourly_rate': employee.overtimeRate,
    };

    final response = await ApiService.updateEmployee(employee.id, data, token);

    if (response['success'] == true) {
      await loadEmployees();
      ToastHelper.success('Employee updated successfully');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Failed to update employee');
    }
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

  Future<void> importEmployees(List<EmployeeModel> employees) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) {
      ToastHelper.error('Session expired. Please login again.');
      return;
    }

    state = state.copyWith(isImporting: true);

    // Get current departments and all designations (if loaded)
    final departments = ref.read(departmentProvider).departments;
    final designations = ref.read(designationProvider).designations;

    print(
      '[EmployeeProvider] Resolving IDs for ${employees.length} employees. Departments: ${departments.length}, Designations: ${designations.length}',
    );

    final employeeList = employees.map((employee) {
      // Try to resolve department ID from name if missing
      int? resolvedDeptId = employee.departmentId;
      if (resolvedDeptId == null && employee.department.isNotEmpty) {
        final matches = departments.where(
          (d) =>
              d.departmentName.toLowerCase() ==
              employee.department.toLowerCase(),
        );
        if (matches.isNotEmpty) {
          resolvedDeptId = int.tryParse(matches.first.id);
        } else if (departments.isNotEmpty) {
          resolvedDeptId = int.tryParse(departments.first.id);
        }
      }

      // Try to resolve designation ID from name if missing
      int? resolvedDesigId = employee.designationId;
      if (resolvedDesigId == null && employee.position.isNotEmpty) {
        final matches = designations.where(
          (d) =>
              d.designationName.toLowerCase() ==
              employee.position.toLowerCase(),
        );
        if (matches.isNotEmpty) {
          resolvedDesigId = int.tryParse(matches.first.id);
        } else if (designations.isNotEmpty) {
          resolvedDesigId = int.tryParse(designations.first.id);
        }
      }

      return {
        'company_id': companyId,
        'department_id': resolvedDeptId ?? 1,
        'designation_id': resolvedDesigId ?? 1,
        'employee_code': employee.employeeCode,
        'first_name': employee.firstName,
        'last_name': employee.lastName,
        'phone': employee.mobileNo,
        'email': null,
        'join_date': DateTime.now().toIso8601String().split('T')[0],
        'basic_salary': employee.salaryOriginal,
        'allowances': 0,
        'deductions': 0,
        'net_salary': employee.salaryOriginal,
        'overtime_enabled': employee.overtimeType != OvertimeType.none,
        'hourly_rate': employee.overtimeRate,
      };
    }).toList();

    final response = await ApiService.bulkCreateEmployees(employeeList, token);

    if (response['success'] == true) {
      await loadEmployees();
      state = state.copyWith(isImporting: false);
      ToastHelper.success(
        '${employees.length} employees imported successfully',
      );
    } else {
      state = state.copyWith(isImporting: false);
      ToastHelper.error(response['message'] ?? 'Failed to import employees');
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
