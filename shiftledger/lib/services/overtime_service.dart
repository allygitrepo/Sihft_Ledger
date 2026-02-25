class OvertimeService {
  // Calculate overtime pay
  static double calculateOvertimePay({
    required double overtimeHours,
    required double hourlyRate,
    required double overtimeMultiplier,
  }) {
    return overtimeHours * hourlyRate * overtimeMultiplier;
  }

  // Calculate total overtime hours for a period
  static double calculateTotalOvertimeHours(
    List<double> overtimeHoursList,
  ) {
    return overtimeHoursList.fold(0.0, (sum, hours) => sum + hours);
  }

  // Validate overtime hours
  static bool isValidOvertimeHours(double hours) {
    return hours >= 0 && hours <= 24;
  }
}
