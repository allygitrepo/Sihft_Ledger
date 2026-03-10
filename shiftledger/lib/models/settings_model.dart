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
      defaultOvertimeRate: 0.0, // Changed from 100.0 - will be loaded from backend
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
        (e) => e.name == json['defaultSalaryType'] || e.name == json['salary_calculation_method'],
        orElse: () => DefaultSalaryType.hourwise,
      ),
      fixedHoursPerDay: _parseDouble(json['fixedHoursPerDay'] ?? json['hours_per_day']),
      workingDaysPerMonth: _parseInt(json['workingDaysPerMonth'] ?? json['days_per_month']) ?? 26,
      salaryInputType: SalaryInputType.values.firstWhere(
        (e) => e.name == json['salaryInputType'] || e.name.toLowerCase() == (json['salary_input_type'] as String?)?.toLowerCase(),
        orElse: () => SalaryInputType.monthly,
      ),
      fullDayHours: _parseDouble(json['full_day_hours'] ?? json['fullDayHours']),
      halfDayHours: _parseDouble(json['half_day_hours'] ?? json['halfDayHours']),
      breakMinutes: _parseInt(json['break_minutes'] ?? json['breakMinutes']) ?? 60,
      overtimeEnabled: json['overtime_enabled'] == true || json['overtime_enabled'] == 1 || json['overtimeEnabled'] == true,
      defaultOvertimeType: OvertimeType.values.firstWhere(
        (e) => e.name == json['defaultOvertimeType'] || e.name == json['overtimeType'] || e.name == (json['overtime_type'] as String?)?.toLowerCase().replaceAll('-', ''),
        orElse: () => OvertimeType.hourwise,
      ),
      defaultOvertimeRate: _parseDouble(
        json['default_overtime_rate'] ?? 
        json['defaultOvertimeRate'] ?? 
        json['overtime_rate'] ?? 
        json['overtimeRate']
      ),
      overtimeSlots: (json['overtime_slots'] as List<dynamic>? ?? json['overtimeSlots'] as List<dynamic>?)
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
      overtimeMultiplier: _parseDouble(json['overtimeMultiplier'] ?? json['overtime_multiplier']),
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
      minimumHours: _parseDouble(json['minimumHours'] ?? json['minimum_hours']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
