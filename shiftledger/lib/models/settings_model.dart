import 'employee_model.dart';

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

enum SalaryInputType {
  monthly,
  daily,
  hourly,
}

enum DefaultSalaryType {
  hourwise,
  daywise,
}

class SettingsModel {
  // Salary Configuration
  final DefaultSalaryType defaultSalaryType;
  final double fixedHoursPerDay;
  final int workingDaysPerMonth;
  final SalaryInputType salaryInputType;
  
  // Working hours (for attendance module)
  final double fullDayHours;
  final double halfDayHours;
  final int breakMinutes;
  
  // Overtime Configuration
  final bool overtimeEnabled;
  final OvertimeType defaultOvertimeType;
  final double defaultOvertimeRate;
  final List<OvertimeSlot> overtimeSlots;

  // Old fields (for backward compatibility with payroll)
  final PayrollAttendanceType attendanceType;
  final double overtimeMultiplier;
  final SalaryCycle salaryCycle;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double minimumHours;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SettingsModel({
    required this.defaultSalaryType,
    required this.fixedHoursPerDay,
    required this.workingDaysPerMonth,
    required this.salaryInputType,
    required this.fullDayHours,
    required this.halfDayHours,
    required this.breakMinutes,
    required this.overtimeEnabled,
    required this.defaultOvertimeType,
    required this.defaultOvertimeRate,
    required this.overtimeSlots,
    required this.attendanceType,
    required this.overtimeMultiplier,
    required this.salaryCycle,
    this.customStartDate,
    this.customEndDate,
    this.minimumHours = 8.0,
    this.createdAt,
    this.updatedAt,
  });

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      defaultSalaryType: DefaultSalaryType.hourwise,
      fixedHoursPerDay: 8.0,
      workingDaysPerMonth: 26,
      salaryInputType: SalaryInputType.monthly,
      fullDayHours: 8.0,
      halfDayHours: 4.0,
      breakMinutes: 60,
      overtimeEnabled: true,
      defaultOvertimeType: OvertimeType.hourwise,
      defaultOvertimeRate: 100.0,
      overtimeSlots: const [
        OvertimeSlot(startHour: 0, endHour: 2, rate: 100),
        OvertimeSlot(startHour: 2, endHour: 5, rate: 150),
        OvertimeSlot(startHour: 5, endHour: 10, rate: 200),
      ],
      attendanceType: PayrollAttendanceType.daily,
      overtimeMultiplier: 1.5,
      salaryCycle: SalaryCycle.monthly,
      minimumHours: 8.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultSalaryType': defaultSalaryType.name,
      'fixedHoursPerDay': fixedHoursPerDay,
      'workingDaysPerMonth': workingDaysPerMonth,
      'salaryInputType': salaryInputType.name,
      'fullDayHours': fullDayHours,
      'halfDayHours': halfDayHours,
      'breakMinutes': breakMinutes,
      'overtimeEnabled': overtimeEnabled,
      'defaultOvertimeType': defaultOvertimeType.name,
      'defaultOvertimeRate': defaultOvertimeRate,
      'overtimeSlots': overtimeSlots.map((s) => s.toJson()).toList(),
      'attendanceType': attendanceType.name,
      'overtimeMultiplier': overtimeMultiplier,
      'salaryCycle': salaryCycle.name,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'minimumHours': minimumHours,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      defaultSalaryType: DefaultSalaryType.values.firstWhere(
        (e) => e.name == json['defaultSalaryType'],
        orElse: () => DefaultSalaryType.hourwise,
      ),
      fixedHoursPerDay: (json['fixedHoursPerDay'] as num?)?.toDouble() ?? 8.0,
      workingDaysPerMonth: (json['workingDaysPerMonth'] as int?) ?? 26,
      salaryInputType: SalaryInputType.values.firstWhere(
        (e) => e.name == json['salaryInputType'],
        orElse: () => SalaryInputType.monthly,
      ),
      fullDayHours: (json['fullDayHours'] as num?)?.toDouble() ?? 8.0,
      halfDayHours: (json['halfDayHours'] as num?)?.toDouble() ?? 4.0,
      breakMinutes: (json['breakMinutes'] as int?) ?? 60,
      overtimeEnabled: (json['overtimeEnabled'] as bool?) ?? true,
      defaultOvertimeType: OvertimeType.values.firstWhere(
        (e) => e.name == json['defaultOvertimeType'] || e.name == json['overtimeType'],
        orElse: () => OvertimeType.hourwise,
      ),
      defaultOvertimeRate: (json['defaultOvertimeRate'] as num?)?.toDouble() ?? 
                          (json['overtimeRate'] as num?)?.toDouble() ?? 100.0,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  SettingsModel copyWith({
    DefaultSalaryType? defaultSalaryType,
    double? fixedHoursPerDay,
    int? workingDaysPerMonth,
    SalaryInputType? salaryInputType,
    double? fullDayHours,
    double? halfDayHours,
    int? breakMinutes,
    bool? overtimeEnabled,
    OvertimeType? defaultOvertimeType,
    double? defaultOvertimeRate,
    List<OvertimeSlot>? overtimeSlots,
    PayrollAttendanceType? attendanceType,
    double? overtimeMultiplier,
    SalaryCycle? salaryCycle,
    DateTime? customStartDate,
    DateTime? customEndDate,
    double? minimumHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      defaultSalaryType: defaultSalaryType ?? this.defaultSalaryType,
      fixedHoursPerDay: fixedHoursPerDay ?? this.fixedHoursPerDay,
      workingDaysPerMonth: workingDaysPerMonth ?? this.workingDaysPerMonth,
      salaryInputType: salaryInputType ?? this.salaryInputType,
      fullDayHours: fullDayHours ?? this.fullDayHours,
      halfDayHours: halfDayHours ?? this.halfDayHours,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
      defaultOvertimeType: defaultOvertimeType ?? this.defaultOvertimeType,
      defaultOvertimeRate: defaultOvertimeRate ?? this.defaultOvertimeRate,
      overtimeSlots: overtimeSlots ?? this.overtimeSlots,
      attendanceType: attendanceType ?? this.attendanceType,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      salaryCycle: salaryCycle ?? this.salaryCycle,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      minimumHours: minimumHours ?? this.minimumHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
