import '../models/settings_model.dart';

class OvertimeService {
  /// Calculate overtime salary based on settings
  static double calculateOvertimeSalary({
    required double overtimeHours,
    required SettingsModel settings,
  }) {
    if (overtimeHours <= 0) return 0.0;

    if (settings.overtimeType == OvertimeType.hourwise) {
      // Simple hourwise calculation
      return overtimeHours * settings.overtimeRate;
    } else {
      // Slotwise calculation
      return _calculateSlotwiseSalary(overtimeHours, settings.overtimeSlots);
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
    required SettingsModel settings,
  }) {
    if (settings.overtimeType == OvertimeType.hourwise) {
      return settings.overtimeRate;
    } else {
      // Find the slot rate
      for (final slot in settings.overtimeSlots) {
        if (overtimeHours >= slot.startHour && overtimeHours <= slot.endHour) {
          return slot.rate;
        }
      }

      // Return last slot rate if no match
      if (settings.overtimeSlots.isNotEmpty) {
        return settings.overtimeSlots.last.rate;
      }

      return settings.overtimeRate;
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
