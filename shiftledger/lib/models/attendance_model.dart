enum AttendanceType {
  daywise,
  hourwise,
}

enum AttendanceStatus {
  fullDay,
  halfDay,
  absent,
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  
  // Attendance Type
  final AttendanceType attendanceType;
  
  // Day-wise fields
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  
  // Hour-wise fields
  final double? workingHours;
  
  // Overtime
  final double? overtimeHours;
  final double? overtimeRate;
  final double? overtimeSalary;
  
  // Salary
  final double? hourlySalary;
  final double? workSalary;
  final double? totalSalary;
  
  // Status
  final AttendanceStatus attendanceStatus;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.attendanceType,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    this.overtimeHours,
    this.overtimeRate,
    this.overtimeSalary,
    this.hourlySalary,
    this.workSalary,
    this.totalSalary,
    required this.attendanceStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'attendanceType': attendanceType.name,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'workingHours': workingHours,
      'overtimeHours': overtimeHours,
      'overtimeRate': overtimeRate,
      'overtimeSalary': overtimeSalary,
      'hourlySalary': hourlySalary,
      'workSalary': workSalary,
      'totalSalary': totalSalary,
      'attendanceStatus': attendanceStatus.name,
    };
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      date: DateTime.parse(json['date'] as String),
      attendanceType: AttendanceType.values.firstWhere(
        (e) => e.name == json['attendanceType'],
        orElse: () => AttendanceType.daywise,
      ),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      workingHours: (json['workingHours'] as num?)?.toDouble(),
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble(),
      overtimeRate: (json['overtimeRate'] as num?)?.toDouble(),
      overtimeSalary: (json['overtimeSalary'] as num?)?.toDouble(),
      hourlySalary: (json['hourlySalary'] as num?)?.toDouble(),
      workSalary: (json['workSalary'] as num?)?.toDouble(),
      totalSalary: (json['totalSalary'] as num?)?.toDouble(),
      attendanceStatus: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['attendanceStatus'],
        orElse: () => AttendanceStatus.absent,
      ),
    );
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    AttendanceType? attendanceType,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? workingHours,
    double? overtimeHours,
    double? overtimeRate,
    double? overtimeSalary,
    double? hourlySalary,
    double? workSalary,
    double? totalSalary,
    AttendanceStatus? attendanceStatus,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      attendanceType: attendanceType ?? this.attendanceType,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      workingHours: workingHours ?? this.workingHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      hourlySalary: hourlySalary ?? this.hourlySalary,
      workSalary: workSalary ?? this.workSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    );
  }
}
