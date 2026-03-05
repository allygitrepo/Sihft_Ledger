import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';

class EmployeeService {
  static const String _employeesKey = 'employees_data';

  // Convert salary based on company settings
  static Map<String, dynamic> convertSalary(
    double monthlySalary,
    SettingsModel settings,
  ) {
    final salaryType = settings.defaultSalaryType.name;
    double? hourlyRate;
    double? dailyRate;

    if (settings.defaultSalaryType == DefaultSalaryType.hourwise) {
      // Hour-wise calculation
      final totalHoursPerMonth = settings.workingDaysPerMonth * settings.fixedHoursPerDay;
      hourlyRate = monthlySalary / totalHoursPerMonth;
      dailyRate = null;
    } else {
      // Day-wise calculation
      dailyRate = monthlySalary / settings.workingDaysPerMonth;
      hourlyRate = null;
    }

    return {
      'salaryType': salaryType,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
    };
  }

  // Save employees to SharedPreferences
  static Future<void> saveEmployees(List<EmployeeModel> employees) async {
    print('[EmployeeService] Saving ${employees.length} employees to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final jsonList = employees.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    print('[EmployeeService] JSON length: ${jsonString.length} characters');
    
    final success = await prefs.setString(_employeesKey, jsonString);
    print('[EmployeeService] Save success: $success');
    
    // Verify save
    final saved = prefs.getString(_employeesKey);
    print('[EmployeeService] Verification - Data exists: ${saved != null}, Length: ${saved?.length}');
  }

  // Load employees from SharedPreferences
  static Future<List<EmployeeModel>> loadEmployees() async {
    print('[EmployeeService] Loading employees from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_employeesKey);
    
    print('[EmployeeService] Data found: ${jsonString != null}, Length: ${jsonString?.length}');
    
    if (jsonString == null) {
      print('[EmployeeService] No data found, returning empty list');
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final employees = jsonList
          .map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>))
          .toList();
      print('[EmployeeService] Successfully loaded ${employees.length} employees');
      return employees;
    } catch (e) {
      print('[EmployeeService] Error loading employees: $e');
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
