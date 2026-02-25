class SalaryCalculatorService {
  /// Calculate work salary based on working hours and hourly rate
  static double calculateWorkSalary({
    required double workingHours,
    required double hourlySalary,
  }) {
    if (workingHours <= 0 || hourlySalary <= 0) return 0.0;
    return workingHours * hourlySalary;
  }

  /// Calculate total salary (work salary + overtime salary)
  static double calculateTotalSalary({
    required double workSalary,
    required double overtimeSalary,
  }) {
    return workSalary + overtimeSalary;
  }

  /// Calculate hourly salary from monthly salary
  static double calculateHourlySalary({
    required double monthlySalary,
    int workingDaysPerMonth = 26,
    double hoursPerDay = 8.0,
  }) {
    if (monthlySalary <= 0) return 0.0;
    final totalHoursPerMonth = workingDaysPerMonth * hoursPerDay;
    return monthlySalary / totalHoursPerMonth;
  }

  /// Calculate working hours from check-in and check-out times
  static double calculateWorkingHours({
    required DateTime checkIn,
    required DateTime checkOut,
    int breakMinutes = 0,
  }) {
    if (checkOut.isBefore(checkIn)) return 0.0;

    final duration = checkOut.difference(checkIn);
    final totalMinutes = duration.inMinutes - breakMinutes;

    if (totalMinutes <= 0) return 0.0;

    return totalMinutes / 60.0; // Convert to hours
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
