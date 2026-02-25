import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../widgets/toast.dart';

class EmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
  });

  EmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EmployeeNotifier extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    print('[EmployeeProvider] Initializing provider, loading employees...');
    loadEmployees();
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    print('[EmployeeProvider] loadEmployees() called');
    state = state.copyWith(isLoading: true);
    final employees = await EmployeeService.loadEmployees();
    print('[EmployeeProvider] Loaded ${employees.length} employees from storage');
    state = state.copyWith(employees: employees, isLoading: false);
    print('[EmployeeProvider] State updated with ${state.employees.length} employees');
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    state = state.copyWith(isLoading: true);
    await EmployeeService.addEmployee(employee);
    await loadEmployees();
    ToastHelper.success('Employee added successfully');
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    state = state.copyWith(isLoading: true);
    await EmployeeService.updateEmployee(employee);
    await loadEmployees();
    ToastHelper.success('Employee updated successfully');
  }

  Future<void> deleteEmployee(String employeeId) async {
    state = state.copyWith(isLoading: true);
    await EmployeeService.deleteEmployee(employeeId);
    await loadEmployees();
    ToastHelper.success('Employee deleted successfully');
  }

  Future<void> importEmployees(List<EmployeeModel> employees) async {
    state = state.copyWith(isLoading: true);
    print('[EmployeeProvider] Starting import of ${employees.length} employees');
    
    final currentEmployees = await EmployeeService.loadEmployees();
    print('[EmployeeProvider] Current employees count: ${currentEmployees.length}');
    
    currentEmployees.addAll(employees);
    print('[EmployeeProvider] Total after adding: ${currentEmployees.length}');
    
    await EmployeeService.saveEmployees(currentEmployees);
    print('[EmployeeProvider] Employees saved to storage');
    
    await loadEmployees();
    print('[EmployeeProvider] Employees reloaded, new count: ${state.employees.length}');
    
    ToastHelper.success('${employees.length} employees imported successfully');
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
