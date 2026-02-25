import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';

class EmployeeService {
  static const String _employeesKey = 'employees_data';

  // Save employees to SharedPreferences
  static Future<void> saveEmployees(List<EmployeeModel> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = employees.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_employeesKey, jsonString);
  }

  // Load employees from SharedPreferences
  static Future<List<EmployeeModel>> loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_employeesKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add employee
  static Future<void> addEmployee(EmployeeModel employee) async {
    final employees = await loadEmployees();
    employees.add(employee);
    await saveEmployees(employees);
  }

  // Update employee
  static Future<void> updateEmployee(EmployeeModel employee) async {
    final employees = await loadEmployees();
    final index = employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      employees[index] = employee;
      await saveEmployees(employees);
    }
  }

  // Delete employee
  static Future<void> deleteEmployee(String employeeId) async {
    final employees = await loadEmployees();
    employees.removeWhere((e) => e.id == employeeId);
    await saveEmployees(employees);
  }

  // Get employee by ID
  static Future<EmployeeModel?> getEmployeeById(String employeeId) async {
    final employees = await loadEmployees();
    try {
      return employees.firstWhere((e) => e.id == employeeId);
    } catch (e) {
      return null;
    }
  }

  // Clear all employees
  static Future<void> clearEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_employeesKey);
  }
}
