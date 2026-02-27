class PayrollModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  
  // Attendance summary
  final int workingDays;
  final double workingHours;
  
  // Salary breakdown
  final double workSalary;
  final double overtimeHours;
  final double overtimeSalary;
  final double totalSalary;
  
  // Metadata
  final DateTime generatedAt;

  const PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.workingHours,
    required this.workSalary,
    required this.overtimeHours,
    required this.overtimeSalary,
    required this.totalSalary,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'workingDays': workingDays,
      'workingHours': workingHours,
      'workSalary': workSalary,
      'overtimeHours': overtimeHours,
      'overtimeSalary': overtimeSalary,
      'totalSalary': totalSalary,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      workingDays: json['workingDays'] as int,
      workingHours: (json['workingHours'] as num).toDouble(),
      workSalary: (json['workSalary'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      overtimeSalary: (json['overtimeSalary'] as num).toDouble(),
      totalSalary: (json['totalSalary'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  PayrollModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? startDate,
    DateTime? endDate,
    int? workingDays,
    double? workingHours,
    double? workSalary,
    double? overtimeHours,
    double? overtimeSalary,
    double? totalSalary,
    DateTime? generatedAt,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      workingDays: workingDays ?? this.workingDays,
      workingHours: workingHours ?? this.workingHours,
      workSalary: workSalary ?? this.workSalary,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
