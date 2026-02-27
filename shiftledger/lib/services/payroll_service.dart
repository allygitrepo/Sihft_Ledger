import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payroll_model.dart';
import '../models/attendance_model.dart';

class PayrollService {
  static const String _payrollKey = 'payroll_data';

  /// Generate payroll for employees based on attendance records
  static List<PayrollModel> generatePayroll({
    required List<AttendanceModel> attendanceRecords,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Filter attendance by date range
    final filteredAttendance = filterAttendanceByDateRange(
      attendanceRecords,
      startDate,
      endDate,
    );

    // Group attendance by employee
    final groupedAttendance = groupAttendanceByEmployee(filteredAttendance);

    // Calculate payroll for each employee
    final payrollList = <PayrollModel>[];
    
    for (final entry in groupedAttendance.entries) {
      final employeeId = entry.key;
      final employeeAttendance = entry.value;
      
      if (employeeAttendance.isEmpty) continue;
      
      final payroll = calculateEmployeePayroll(
        employeeId: employeeId,
        employeeName: employeeAttendance.first.employeeName,
        attendance: employeeAttendance,
        startDate: startDate,
        endDate: endDate,
      );
      
      payrollList.add(payroll);
    }

    return payrollList;
  }

  /// Filter attendance records by date range
  static List<AttendanceModel> filterAttendanceByDateRange(
    List<AttendanceModel> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    return records.where((record) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      return (recordDate.isAtSameMomentAs(start) || recordDate.isAfter(start)) &&
             (recordDate.isAtSameMomentAs(end) || recordDate.isBefore(end));
    }).toList();
  }

  /// Group attendance records by employee ID
  static Map<String, List<AttendanceModel>> groupAttendanceByEmployee(
    List<AttendanceModel> records,
  ) {
    final grouped = <String, List<AttendanceModel>>{};
    
    for (final record in records) {
      if (!grouped.containsKey(record.employeeId)) {
        grouped[record.employeeId] = [];
      }
      grouped[record.employeeId]!.add(record);
    }
    
    return grouped;
  }

  /// Calculate payroll for a single employee
  static PayrollModel calculateEmployeePayroll({
    required String employeeId,
    required String employeeName,
    required List<AttendanceModel> attendance,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Calculate totals by summing attendance values
    int workingDays = attendance.length;
    double totalWorkingHours = 0.0;
    double totalWorkSalary = 0.0;
    double totalOvertimeHours = 0.0;
    double totalOvertimeSalary = 0.0;
    double totalSalary = 0.0;

    for (final record in attendance) {
      totalWorkingHours += record.workingHours;
      totalWorkSalary += record.workSalary;
      totalOvertimeHours += record.overtimeHours;
      totalOvertimeSalary += record.overtimeSalary;
      totalSalary += record.totalSalary;
    }

    return PayrollModel(
      id: DateTime.now().millisecondsSinceEpoch.toString() + employeeId,
      employeeId: employeeId,
      employeeName: employeeName,
      startDate: startDate,
      endDate: endDate,
      workingDays: workingDays,
      workingHours: totalWorkingHours,
      workSalary: totalWorkSalary,
      overtimeHours: totalOvertimeHours,
      overtimeSalary: totalOvertimeSalary,
      totalSalary: totalSalary,
      generatedAt: DateTime.now(),
    );
  }

  /// Save payroll records to SharedPreferences
  static Future<void> savePayroll(List<PayrollModel> payrollList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = payrollList.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_payrollKey, jsonString);
  }

  /// Load payroll records from SharedPreferences
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

  /// Clear all payroll records
  static Future<void> clearPayroll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_payrollKey);
  }

  /// Get payroll by date range
  static Future<List<PayrollModel>> getPayrollByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allPayroll = await loadPayroll();
    return allPayroll.where((payroll) {
      return (payroll.startDate.isAtSameMomentAs(startDate) ||
              payroll.startDate.isAfter(startDate)) &&
             (payroll.endDate.isAtSameMomentAs(endDate) ||
              payroll.endDate.isBefore(endDate));
    }).toList();
  }
}
