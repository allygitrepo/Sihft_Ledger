enum OvertimeType {
  hourwise,
  slotwise,
}

enum PayrollAttendanceType {
  daily,
  hourly,
  unit,
}

enum SalaryCycle {
  monthly,
  weekly,
  custom,
}

class OvertimeSlot {
  final int startHour;
  final int endHour;
  final double rate;

  const OvertimeSlot({
    required this.startHour,
    required this.endHour,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'startHour': startHour,
      'endHour': endHour,
      'rate': rate,
    };
  }

  factory OvertimeSlot.fromJson(Map<String, dynamic> json) {
    return OvertimeSlot(
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}

class SettingsModel {
  // Working hours (for new attendance module)
  final double fullDayHours;
  final double halfDayHours;
  final int breakMinutes;
  
  // Overtime (for new attendance module)
  final bool overtimeEnabled;
  final OvertimeType overtimeType;
  final double overtimeRate; // Default rate for hourwise
  final List<OvertimeSlot> overtimeSlots; // For slotwise

  // Old fields (for backward compatibility with payroll)
  final PayrollAttendanceType attendanceType;
  final double overtimeMultiplier;
  final SalaryCycle salaryCycle;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double minimumHours;

  const SettingsModel({
    required this.fullDayHours,
    required this.halfDayHours,
    required this.breakMinutes,
    required this.overtimeEnabled,
    required this.overtimeType,
    required this.overtimeRate,
    required this.overtimeSlots,
    required this.attendanceType,
    required this.overtimeMultiplier,
    required this.salaryCycle,
    this.customStartDate,
    this.customEndDate,
    this.minimumHours = 8.0,
  });

  factory SettingsModel.defaultSettings() {
    return const SettingsModel(
      fullDayHours: 8.0,
      halfDayHours: 4.0,
      breakMinutes: 60,
      overtimeEnabled: true,
      overtimeType: OvertimeType.hourwise,
      overtimeRate: 100.0,
      overtimeSlots: [
        OvertimeSlot(startHour: 0, endHour: 2, rate: 100),
        OvertimeSlot(startHour: 2, endHour: 5, rate: 150),
        OvertimeSlot(startHour: 5, endHour: 10, rate: 200),
      ],
      attendanceType: PayrollAttendanceType.daily,
      overtimeMultiplier: 1.5,
      salaryCycle: SalaryCycle.monthly,
      minimumHours: 8.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullDayHours': fullDayHours,
      'halfDayHours': halfDayHours,
      'breakMinutes': breakMinutes,
      'overtimeEnabled': overtimeEnabled,
      'overtimeType': overtimeType.name,
      'overtimeRate': overtimeRate,
      'overtimeSlots': overtimeSlots.map((s) => s.toJson()).toList(),
      'attendanceType': attendanceType.name,
      'overtimeMultiplier': overtimeMultiplier,
      'salaryCycle': salaryCycle.name,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'minimumHours': minimumHours,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      fullDayHours: (json['fullDayHours'] as num?)?.toDouble() ?? 8.0,
      halfDayHours: (json['halfDayHours'] as num?)?.toDouble() ?? 4.0,
      breakMinutes: (json['breakMinutes'] as int?) ?? 60,
      overtimeEnabled: (json['overtimeEnabled'] as bool?) ?? true,
      overtimeType: OvertimeType.values.firstWhere(
        (e) => e.name == json['overtimeType'],
        orElse: () => OvertimeType.hourwise,
      ),
      overtimeRate: (json['overtimeRate'] as num?)?.toDouble() ?? 100.0,
      overtimeSlots: (json['overtimeSlots'] as List<dynamic>?)
              ?.map((s) => OvertimeSlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [
            OvertimeSlot(startHour: 0, endHour: 2, rate: 100),
            OvertimeSlot(startHour: 2, endHour: 5, rate: 150),
            OvertimeSlot(startHour: 5, endHour: 10, rate: 200),
          ],
      attendanceType: PayrollAttendanceType.values.firstWhere(
        (e) => e.name == json['attendanceType'],
        orElse: () => PayrollAttendanceType.daily,
      ),
      overtimeMultiplier: (json['overtimeMultiplier'] as num?)?.toDouble() ?? 1.5,
      salaryCycle: SalaryCycle.values.firstWhere(
        (e) => e.name == json['salaryCycle'],
        orElse: () => SalaryCycle.monthly,
      ),
      customStartDate: json['customStartDate'] != null
          ? DateTime.parse(json['customStartDate'])
          : null,
      customEndDate: json['customEndDate'] != null
          ? DateTime.parse(json['customEndDate'])
          : null,
      minimumHours: (json['minimumHours'] as num?)?.toDouble() ?? 8.0,
    );
  }

  SettingsModel copyWith({
    double? fullDayHours,
    double? halfDayHours,
    int? breakMinutes,
    bool? overtimeEnabled,
    OvertimeType? overtimeType,
    double? overtimeRate,
    List<OvertimeSlot>? overtimeSlots,
    PayrollAttendanceType? attendanceType,
    double? overtimeMultiplier,
    SalaryCycle? salaryCycle,
    DateTime? customStartDate,
    DateTime? customEndDate,
    double? minimumHours,
  }) {
    return SettingsModel(
      fullDayHours: fullDayHours ?? this.fullDayHours,
      halfDayHours: halfDayHours ?? this.halfDayHours,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
      overtimeType: overtimeType ?? this.overtimeType,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      overtimeSlots: overtimeSlots ?? this.overtimeSlots,
      attendanceType: attendanceType ?? this.attendanceType,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      salaryCycle: salaryCycle ?? this.salaryCycle,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      minimumHours: minimumHours ?? this.minimumHours,
    );
  }
}
