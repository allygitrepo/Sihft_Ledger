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
    loadEmployees();
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true);
    final employees = await EmployeeService.loadEmployees();
    state = state.copyWith(employees: employees, isLoading: false);
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
    final currentEmployees = await EmployeeService.loadEmployees();
    currentEmployees.addAll(employees);
    await EmployeeService.saveEmployees(currentEmployees);
    await loadEmployees();
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
