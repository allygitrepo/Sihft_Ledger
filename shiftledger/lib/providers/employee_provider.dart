import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import '../services/employee_service.dart';
import '../widgets/toast.dart';

class EmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;
  final bool isParsingCSV;
  final bool isImporting;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.isParsingCSV = false,
    this.isImporting = false,
  });

  EmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    bool? isParsingCSV,
    bool? isImporting,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isParsingCSV: isParsingCSV ?? this.isParsingCSV,
      isImporting: isImporting ?? this.isImporting,
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
    print(
      '[EmployeeProvider] Loaded ${employees.length} employees from storage',
    );
    state = state.copyWith(employees: employees, isLoading: false);
    print(
      '[EmployeeProvider] State updated with ${state.employees.length} employees',
    );
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
    state = state.copyWith(isImporting: true);
    print(
      '[EmployeeProvider] Starting import of ${employees.length} employees',
    );

    final currentEmployees = await EmployeeService.loadEmployees();
    currentEmployees.addAll(employees);

    await EmployeeService.saveEmployees(currentEmployees);
    await loadEmployees();

    state = state.copyWith(isImporting: false);
    ToastHelper.success('${employees.length} employees imported successfully');
  }

  // Recalculate all employee salaries when settings change
  Future<void> recalculateEmployeeSalaries(SettingsModel settings) async {
    state = state.copyWith(isLoading: true);
    print(
      '[EmployeeProvider] Recalculating salaries for ${state.employees.length} employees',
    );

    final updatedEmployees = <EmployeeModel>[];

    for (final employee in state.employees) {
      final conversion = EmployeeService.convertSalary(
        employee.salaryOriginal,
        settings,
      );

      final updatedEmployee = employee.copyWith(
        salaryType: conversion['salaryType'] as String,
        hourlyRate: conversion['hourlyRate'] as double?,
        dailyRate: conversion['dailyRate'] as double?,
        salary: employee.salaryOriginal, // Keep original salary
      );

      updatedEmployees.add(updatedEmployee);
    }

    await EmployeeService.saveEmployees(updatedEmployees);
    await loadEmployees();

    print('[EmployeeProvider] Salary recalculation completed');
    ToastHelper.success('Employee salaries recalculated');
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
