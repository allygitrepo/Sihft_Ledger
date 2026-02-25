import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payroll_model.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import 'attendance_service.dart';
import 'salary_calculator_service.dart';
import 'employee_service.dart';

class PayrollService {
  static const String _payrollKey = 'payroll_data';

  // Generate payroll for all employees
  static Future<List<PayrollModel>> generatePayroll({
    required DateTime startDate,
    required DateTime endDate,
    required SettingsModel settings,
  }) async {
    final employees = await EmployeeService.loadEmployees();
    final List<PayrollModel> payrollList = [];

    for (final employee in employees) {
      final payroll = await _generateEmployeePayroll(
        employee: employee,
        startDate: startDate,
        endDate: endDate,
        settings: settings,
      );
      payrollList.add(payroll);
    }

    await savePayroll(payrollList);
    return payrollList;
  }

  // Generate payroll for single employee
  static Future<PayrollModel> _generateEmployeePayroll({
    required EmployeeModel employee,
    required DateTime startDate,
    required DateTime endDate,
    required SettingsModel settings,
  }) async {
    final attendanceRecords =
        await AttendanceService.getAttendanceByEmployeeAndDateRange(
      employee.id,
      startDate,
      endDate,
    );

    final salaryData = SalaryCalculatorService.calculateSalary(
      employee: employee,
      attendanceRecords: attendanceRecords,
      settings: settings,
    );

    final stats = SalaryCalculatorService.getAttendanceStats(
      attendanceRecords,
      settings.attendanceType,
    );

    final payrollId = DateTime.now().millisecondsSinceEpoch.toString() +
        employee.id.substring(0, 5);

    return PayrollModel(
      id: payrollId,
      employeeId: employee.id,
      employeeName: employee.name,
      startDate: startDate,
      endDate: endDate,
      basePay: salaryData['basePay']!,
      overtimePay: salaryData['overtimePay']!,
      totalPay: salaryData['totalPay']!,
      daysPresent: stats['daysPresent'] as int?,
      totalHoursWorked: stats['totalHours'] as double?,
      totalUnitsProduced: stats['totalUnits'] as int?,
      generatedAt: DateTime.now(),
    );
  }

  // Save payroll records
  static Future<void> savePayroll(List<PayrollModel> payrollList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = payrollList.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_payrollKey, jsonString);
  }

  // Load payroll records
  static Future<List<PayrollModel>> loadPayroll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_payrollKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => PayrollModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Clear payroll
  static Future<void> clearPayroll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_payrollKey);
  }
}
