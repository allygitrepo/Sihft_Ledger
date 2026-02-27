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
  
  // Time tracking
  final DateTime checkIn;
  final DateTime checkOut;
  final double workingHours;
  
  // Status (for daily employees)
  final AttendanceStatus attendanceStatus;
  
  // Salary
  final double workSalary;
  final double overtimeHours;
  final double overtimeSalary;
  final double totalSalary;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.workingHours,
    required this.attendanceStatus,
    required this.workSalary,
    this.overtimeHours = 0.0,
    this.overtimeSalary = 0.0,
    required this.totalSalary,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'workingHours': workingHours,
      'attendanceStatus': attendanceStatus.name,
      'workSalary': workSalary,
      'overtimeHours': overtimeHours,
      'overtimeSalary': overtimeSalary,
      'totalSalary': totalSalary,
    };
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      date: DateTime.parse(json['date'] as String),
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      workingHours: (json['workingHours'] as num).toDouble(),
      attendanceStatus: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['attendanceStatus'],
        orElse: () => AttendanceStatus.absent,
      ),
      workSalary: (json['workSalary'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
      overtimeSalary: (json['overtimeSalary'] as num?)?.toDouble() ?? 0.0,
      totalSalary: (json['totalSalary'] as num).toDouble(),
    );
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    double? workingHours,
    AttendanceStatus? attendanceStatus,
    double? workSalary,
    double? overtimeHours,
    double? overtimeSalary,
    double? totalSalary,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      workingHours: workingHours ?? this.workingHours,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      workSalary: workSalary ?? this.workSalary,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      totalSalary: totalSalary ?? this.totalSalary,
    );
  }
}
