import '../models/employee_model.dart';

class OvertimeService {
  /// Calculate overtime salary based on employee overtime configuration
  static double calculateOvertimeSalary({
    required double overtimeHours,
    required EmployeeModel employee,
  }) {
    if (overtimeHours <= 0) return 0.0;

    if (employee.overtimeType == OvertimeType.hourwise) {
      // Simple hourwise calculation
      return overtimeHours * employee.overtimeRate;
    } else {
      // Slotwise calculation
      return _calculateSlotwiseSalary(overtimeHours, employee.overtimeSlots);
    }
  }

  /// Calculate slotwise overtime salary
  static double _calculateSlotwiseSalary(
    double overtimeHours,
    List<OvertimeSlot> slots,
  ) {
    // Find the appropriate slot for the overtime hours
    for (final slot in slots) {
      if (overtimeHours >= slot.startHour && overtimeHours <= slot.endHour) {
        return overtimeHours * slot.rate;
      }
    }

    // If no slot matches, use the last slot's rate
    if (slots.isNotEmpty) {
      return overtimeHours * slots.last.rate;
    }

    return 0.0;
  }

  /// Get overtime rate for given hours (useful for display)
  static double getOvertimeRate({
    required double overtimeHours,
    required EmployeeModel employee,
  }) {
    if (employee.overtimeType == OvertimeType.hourwise) {
      return employee.overtimeRate;
    } else {
      // Find the slot rate
      for (final slot in employee.overtimeSlots) {
        if (overtimeHours >= slot.startHour && overtimeHours <= slot.endHour) {
          return slot.rate;
        }
      }

      // Return last slot rate if no match
      if (employee.overtimeSlots.isNotEmpty) {
        return employee.overtimeSlots.last.rate;
      }

      return employee.overtimeRate;
    }
  }

  /// Get slot information for given overtime hours
  static OvertimeSlot? getOvertimeSlot({
    required double overtimeHours,
    required List<OvertimeSlot> slots,
  }) {
    for (final slot in slots) {
      if (overtimeHours >= slot.startHour && overtimeHours <= slot.endHour) {
        return slot;
      }
    }
    return null;
  }
}
