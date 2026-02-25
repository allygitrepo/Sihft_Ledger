import '../models/settings_model.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';
import 'overtime_service.dart';

class SalaryCalculatorService {
  // Calculate salary based on attendance type
  static Map<String, double> calculateSalary({
    required EmployeeModel employee,
    required List<AttendanceModel> attendanceRecords,
    required SettingsModel settings,
  }) {
    double basePay = 0.0;
    double overtimePay = 0.0;

    switch (settings.attendanceType) {
      case AttendanceType.daily:
        basePay = _calculateDailySalary(employee, attendanceRecords);
        overtimePay = _calculateDailyOvertimePay(
          employee,
          attendanceRecords,
          settings.overtimeMultiplier,
        );
        break;
      case AttendanceType.hourly:
        final result = _calculateHourlySalary(
          employee,
          attendanceRecords,
          settings.overtimeMultiplier,
        );
        basePay = result['basePay']!;
        overtimePay = result['overtimePay']!;
        break;
      case AttendanceType.unit:
        basePay = _calculateUnitSalary(employee, attendanceRecords);
        break;
    }

    return {
      'basePay': basePay,
      'overtimePay': overtimePay,
      'totalPay': basePay + overtimePay,
    };
  }

  // Calculate daily-based salary
  static double _calculateDailySalary(
    EmployeeModel employee,
    List<AttendanceModel> attendanceRecords,
  ) {
    final daysPresent = attendanceRecords.where((r) => r.present).length;
    return daysPresent * (employee.baseSalary ?? 0.0);
  }

  // Calculate daily overtime pay (if overtime hours are provided)
  static double _calculateDailyOvertimePay(
    EmployeeModel employee,
    List<AttendanceModel> attendanceRecords,
    double overtimeMultiplier,
  ) {
    double totalOvertimeHours = 0.0;

    for (final record in attendanceRecords) {
      if (record.overtimeHours != null) {
        totalOvertimeHours += record.overtimeHours!;
      }
    }

    // Calculate hourly rate from daily salary (assuming 8 hours per day)
    final dailySalary = employee.baseSalary ?? 0.0;
    final hourlyRate = dailySalary / 8.0;

    return OvertimeService.calculateOvertimePay(
      overtimeHours: totalOvertimeHours,
      hourlyRate: hourlyRate,
      overtimeMultiplier: overtimeMultiplier,
    );
  }

  // Calculate hourly-based salary
  static Map<String, double> _calculateHourlySalary(
    EmployeeModel employee,
    List<AttendanceModel> attendanceRecords,
    double overtimeMultiplier,
  ) {
    double totalHours = 0.0;
    double totalOvertimeHours = 0.0;

    for (final record in attendanceRecords) {
      if (record.hoursWorked != null) {
        totalHours += record.hoursWorked!;
      }
      if (record.overtimeHours != null) {
        totalOvertimeHours += record.overtimeHours!;
      }
    }

    final hourlyRate = employee.hourlyRate ?? 0.0;
    final basePay = totalHours * hourlyRate;
    final overtimePay = OvertimeService.calculateOvertimePay(
      overtimeHours: totalOvertimeHours,
      hourlyRate: hourlyRate,
      overtimeMultiplier: overtimeMultiplier,
    );

    return {
      'basePay': basePay,
      'overtimePay': overtimePay,
    };
  }

  // Calculate unit-based salary
  static double _calculateUnitSalary(
    EmployeeModel employee,
    List<AttendanceModel> attendanceRecords,
  ) {
    int totalUnits = 0;

    for (final record in attendanceRecords) {
      if (record.unitProduced != null) {
        totalUnits += record.unitProduced!;
      }
    }

    return totalUnits * (employee.perUnitRate ?? 0.0);
  }

  // Get attendance statistics
  static Map<String, dynamic> getAttendanceStats(
    List<AttendanceModel> attendanceRecords,
    AttendanceType attendanceType,
  ) {
    int daysPresent = 0;
    double totalHours = 0.0;
    int totalUnits = 0;
    double totalOvertimeHours = 0.0;

    for (final record in attendanceRecords) {
      if (record.present) daysPresent++;
      if (record.hoursWorked != null) totalHours += record.hoursWorked!;
      if (record.unitProduced != null) totalUnits += record.unitProduced!;
      if (record.overtimeHours != null) {
        totalOvertimeHours += record.overtimeHours!;
      }
    }

    return {
      'daysPresent': daysPresent,
      'totalHours': totalHours,
      'totalUnits': totalUnits,
      'totalOvertimeHours': totalOvertimeHours,
    };
  }
}
