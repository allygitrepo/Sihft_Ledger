class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final bool present;
  final double? hoursWorked;
  final int? unitProduced;
  final double? overtimeHours;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.present,
    this.hoursWorked,
    this.unitProduced,
    this.overtimeHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'present': present,
      'hoursWorked': hoursWorked,
      'unitProduced': unitProduced,
      'overtimeHours': overtimeHours,
    };
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      date: DateTime.parse(json['date'] as String),
      present: json['present'] as bool,
      hoursWorked: (json['hoursWorked'] as num?)?.toDouble(),
      unitProduced: json['unitProduced'] as int?,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble(),
    );
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    bool? present,
    double? hoursWorked,
    int? unitProduced,
    double? overtimeHours,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      present: present ?? this.present,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      unitProduced: unitProduced ?? this.unitProduced,
      overtimeHours: overtimeHours ?? this.overtimeHours,
    );
  }
}
