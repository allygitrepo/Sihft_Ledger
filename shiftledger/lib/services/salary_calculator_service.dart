import '../models/employee_model.dart';
import '../models/settings_model.dart';

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
  /// Formula: workSalary = workingHours × hourlyRate
  static double calculateHourlyWorkSalary({
    required double workingHours,
    required double hourlyRate,
  }) {
    if (workingHours <= 0 || hourlyRate <= 0) return 0.0;
    return workingHours * hourlyRate;
  }

  /// Calculate work salary for daily employee
  /// If workingHours <= fixedHours: workSalary = (workingHours / fixedHours) × dailyRate
  /// If workingHours > fixedHours: workSalary = dailyRate
  static double calculateDailyWorkSalary({
    required double workingHours,
    required double dailyRate,
    required double fixedHoursPerDay,
  }) {
    if (workingHours <= 0 || dailyRate <= 0) return 0.0;

    if (workingHours <= fixedHoursPerDay) {
      // Proportional calculation for partial day
      return (workingHours / fixedHoursPerDay) * dailyRate;
    } else {
      // Full day rate if working hours exceed fixed hours
      return dailyRate;
    }
  }

  /// Calculate overtime hours
  /// overtimeHours = workingHours - fixedHours (minimum 0)
  static double calculateOvertimeHours({
    required double workingHours,
    required double fixedHoursPerDay,
  }) {
    final overtime = workingHours - fixedHoursPerDay;
    return overtime > 0 ? overtime : 0.0;
  }

  /// Calculate overtime salary for hourwise overtime
  /// overtimeSalary = overtimeHours × overtimeRate
  static double calculateHourwiseOvertimeSalary({
    required double overtimeHours,
    required double overtimeRate,
  }) {
    if (overtimeHours <= 0 || overtimeRate <= 0) return 0.0;
    return overtimeHours * overtimeRate;
  }

  /// Calculate overtime salary for slotwise overtime
  /// Find matching slot and return its rate
  static double calculateSlotwiseOvertimeSalary({
    required double overtimeHours,
    required List<OvertimeSlot> overtimeSlots,
  }) {
    if (overtimeHours <= 0 || overtimeSlots.isEmpty) return 0.0;

    // Find the slot that matches the overtime hours
    for (final slot in overtimeSlots) {
      if (overtimeHours >= slot.startHour && overtimeHours < slot.endHour) {
        return slot.rate;
      }
    }

    // If no slot matches, use the last slot's rate
    return overtimeSlots.last.rate;
  }

  /// Calculate work salary based on employee type and settings
  static double calculateWorkSalary({
    required EmployeeModel employee,
    required double workingHours,
    required SettingsModel settings,
  }) {
    // Determine if we should use hour-wise or day-wise calculation
    // Priority: employee.salaryType > settings.defaultSalaryType
    final useHourwise = employee.salaryType == 'hourwise';
    
    if (useHourwise) {
      // Hour-wise calculation
      double effectiveHourlyRate = employee.hourlyRate ?? 0.0;
      
      // If hourlyRate is not set or is 0, calculate it from monthly salary
      if (effectiveHourlyRate <= 0 && employee.salary > 0) {
        final totalHoursPerMonth = settings.workingDaysPerMonth * settings.fixedHoursPerDay;
        effectiveHourlyRate = employee.salary / totalHoursPerMonth;
      }
      
      return calculateHourlyWorkSalary(
        workingHours: workingHours,
        hourlyRate: effectiveHourlyRate,
      );
    } else {
      // Day-wise calculation
      double effectiveDailyRate = employee.dailyRate ?? 0.0;
      
      // If dailyRate is not set or is 0, calculate it from monthly salary
      if (effectiveDailyRate <= 0 && employee.salary > 0) {
        effectiveDailyRate = employee.salary / settings.workingDaysPerMonth;
      }
      
      return calculateDailyWorkSalary(
        workingHours: workingHours,
        dailyRate: effectiveDailyRate,
        fixedHoursPerDay: settings.fixedHoursPerDay,
      );
    }
  }

  /// Calculate overtime salary based on employee overtime type
  /// Falls back to [settingsOvertimeRate] if the employee has no individual rate set (rate == 0).
  static double calculateOvertimeSalary({
    required EmployeeModel employee,
    required double overtimeHours,
    double settingsOvertimeRate = 0.0, // fallback from org settings
  }) {
    if (overtimeHours <= 0) return 0.0;

    if (employee.overtimeType == OvertimeType.hourwise) {
      // Use employee's own rate if set, otherwise use the org-wide setting
      final effectiveRate = employee.overtimeRate > 0
          ? employee.overtimeRate
          : settingsOvertimeRate;
      return calculateHourwiseOvertimeSalary(
        overtimeHours: overtimeHours,
        overtimeRate: effectiveRate,
      );
    } else if (employee.overtimeType == OvertimeType.slotwise) {
      // Slot-wise overtime
      return calculateSlotwiseOvertimeSalary(
        overtimeHours: overtimeHours,
        overtimeSlots: employee.overtimeSlots,
      );
    } else {
      // OvertimeType.none — no overtime
      return 0.0;
    }
  }

  /// Calculate total salary (work salary + overtime salary)
  static double calculateTotalSalary({
    required double workSalary,
    required double overtimeSalary,
  }) {
    return workSalary + overtimeSalary;
  }

  /// Calculate complete attendance with all salary components
  static Map<String, double> calculateAttendanceSalary({
    required EmployeeModel employee,
    required double workingHours,
    required SettingsModel settings,
  }) {
    // Calculate work salary
    final workSalary = calculateWorkSalary(
      employee: employee,
      workingHours: workingHours,
      settings: settings,
    );

    // Calculate overtime hours
    final overtimeHours = calculateOvertimeHours(
      workingHours: workingHours,
      fixedHoursPerDay: settings.fixedHoursPerDay,
    );

    // Calculate overtime salary, passing the org-level setting as fallback
    final overtimeSalary = calculateOvertimeSalary(
      employee: employee,
      overtimeHours: overtimeHours,
      settingsOvertimeRate: settings.defaultOvertimeRate,
    );

    // Calculate total salary
    final totalSalary = calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    return {
      'workingHours': workingHours,
      'workSalary': workSalary,
      'overtimeHours': overtimeHours,
      'overtimeSalary': overtimeSalary,
      'totalSalary': totalSalary,
    };
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
