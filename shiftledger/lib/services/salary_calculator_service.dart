import '../models/employee_model.dart';
import '../models/attendance_model.dart';

class SalaryCalculatorService {
  /// Calculate working hours from check-in and check-out times
  static double calculateWorkingHours({
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    if (checkOut.isBefore(checkIn)) return 0.0;

    final duration = checkOut.difference(checkIn);
    final totalMinutes = duration.inMinutes;

    if (totalMinutes <= 0) return 0.0;

    return totalMinutes / 60.0; // Convert to hours
  }

  /// Calculate work salary for hourly employee
  static double calculateHourlyWorkSalary({
    required double workingHours,
    required double hourlyRate,
  }) {
    if (workingHours <= 0 || hourlyRate <= 0) return 0.0;
    return workingHours * hourlyRate;
  }

  /// Calculate work salary for daily employee
  static double calculateDailyWorkSalary({
    required AttendanceStatus status,
    required double dailyRate,
  }) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return dailyRate;
      case AttendanceStatus.halfDay:
        return dailyRate / 2;
      case AttendanceStatus.absent:
        return 0.0;
    }
  }

  /// Calculate work salary based on employee type
  static double calculateWorkSalary({
    required EmployeeModel employee,
    required double workingHours,
    required AttendanceStatus status,
  }) {
    if (employee.employeeType == EmployeeType.hourly) {
      return calculateHourlyWorkSalary(
        workingHours: workingHours,
        hourlyRate: employee.hourlyRate ?? 0.0,
      );
    } else {
      return calculateDailyWorkSalary(
        status: status,
        dailyRate: employee.dailyRate ?? 0.0,
      );
    }
  }

  /// Calculate total salary (work salary + overtime salary)
  static double calculateTotalSalary({
    required double workSalary,
    required double overtimeSalary,
  }) {
    return workSalary + overtimeSalary;
  }

  /// Calculate salary for an employee based on attendance records (for payroll system)
  static Map<String, double> calculateSalary({
    required dynamic employee,
    required List attendanceRecords,
    required dynamic settings,
  }) {
    double basePay = 0.0;
    double overtimePay = 0.0;

    // Handle new AttendanceModel
    for (final record in attendanceRecords) {
      // New attendance model - use workSalary and overtimeSalary directly
      if (record.workSalary != null) {
        basePay += record.workSalary as double;
      }
      if (record.overtimeSalary != null) {
        overtimePay += record.overtimeSalary as double;
      }
    }

    return {
      'basePay': basePay,
      'overtimePay': overtimePay,
      'totalPay': basePay + overtimePay,
    };
  }

  /// Get attendance statistics (for payroll system)
  static Map<String, dynamic> getAttendanceStats(
    List attendanceRecords,
    dynamic attendanceType,
  ) {
    int daysPresent = 0;
    double totalHours = 0.0;
    int totalUnits = 0;

    // Handle new AttendanceModel
    for (final record in attendanceRecords) {
      // Count all records as present (they wouldn't exist if absent)
      // Only count Full Day and Half Day as present
      if (record.attendanceStatus.toString().contains('fullDay') ||
          record.attendanceStatus.toString().contains('halfDay')) {
        daysPresent++;
      }
      
      // Sum up working hours
      if (record.workingHours != null) {
        totalHours += record.workingHours as double;
      }
      
      // Add overtime hours to total hours
      if (record.overtimeHours != null) {
        totalHours += record.overtimeHours as double;
      }
    }

    return {
      'daysPresent': daysPresent,
      'totalHours': totalHours,
      'totalUnits': totalUnits, // Not used in new model
    };
  }
}
