enum AttendanceType {
  daily,
  hourly,
  unit,
}

enum SalaryCycle {
  monthly,
  weekly,
  custom,
}

class SettingsModel {
  final AttendanceType attendanceType;
  final double overtimeMultiplier;
  final SalaryCycle salaryCycle;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double minimumHours; // New field for hourly basis

  const SettingsModel({
    required this.attendanceType,
    required this.overtimeMultiplier,
    required this.salaryCycle,
    this.customStartDate,
    this.customEndDate,
    this.minimumHours = 8.0, // Default 8 hours
  });

  factory SettingsModel.defaultSettings() {
    return const SettingsModel(
      attendanceType: AttendanceType.daily,
      overtimeMultiplier: 1.5,
      salaryCycle: SalaryCycle.monthly,
      minimumHours: 8.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      attendanceType: AttendanceType.values.firstWhere(
        (e) => e.name == json['attendanceType'],
        orElse: () => AttendanceType.daily,
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
    AttendanceType? attendanceType,
    double? overtimeMultiplier,
    SalaryCycle? salaryCycle,
    DateTime? customStartDate,
    DateTime? customEndDate,
    double? minimumHours,
  }) {
    return SettingsModel(
      attendanceType: attendanceType ?? this.attendanceType,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      salaryCycle: salaryCycle ?? this.salaryCycle,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      minimumHours: minimumHours ?? this.minimumHours,
    );
  }
}
