enum EmployeeType {
  hourly,
  daily,
}

enum OvertimeType {
  hourwise,
  slotwise,
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

  OvertimeSlot copyWith({
    int? startHour,
    int? endHour,
    double? rate,
  }) {
    return OvertimeSlot(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      rate: rate ?? this.rate,
    );
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String employeeCode;
  final String mobileNo;
  final String position;
  final String department;
  final double salary;
  final DateTime createdAt;
  
  // New fields for attendance system
  final EmployeeType employeeType;
  final double? hourlyRate;
  final double? dailyRate;
  final OvertimeType overtimeType;
  final double overtimeRate;
  final List<OvertimeSlot> overtimeSlots;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.mobileNo,
    required this.position,
    required this.department,
    required this.salary,
    required this.createdAt,
    this.employeeType = EmployeeType.hourly,
    this.hourlyRate,
    this.dailyRate,
    this.overtimeType = OvertimeType.hourwise,
    this.overtimeRate = 100.0,
    this.overtimeSlots = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeCode': employeeCode,
      'mobileNo': mobileNo,
      'position': position,
      'department': department,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
      'employeeType': employeeType.name,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'overtimeType': overtimeType.name,
      'overtimeRate': overtimeRate,
      'overtimeSlots': overtimeSlots.map((s) => s.toJson()).toList(),
    };
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      employeeCode: json['employeeCode'] as String,
      mobileNo: json['mobileNo'] as String,
      position: json['position'] as String,
      department: json['department'] as String,
      salary: (json['salary'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      employeeType: json['employeeType'] != null
          ? EmployeeType.values.firstWhere(
              (e) => e.name == json['employeeType'],
              orElse: () => EmployeeType.hourly,
            )
          : EmployeeType.hourly,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      overtimeType: json['overtimeType'] != null
          ? OvertimeType.values.firstWhere(
              (e) => e.name == json['overtimeType'],
              orElse: () => OvertimeType.hourwise,
            )
          : OvertimeType.hourwise,
      overtimeRate: (json['overtimeRate'] as num?)?.toDouble() ?? 100.0,
      overtimeSlots: (json['overtimeSlots'] as List<dynamic>?)
              ?.map((s) => OvertimeSlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? employeeCode,
    String? mobileNo,
    String? position,
    String? department,
    double? salary,
    DateTime? createdAt,
    EmployeeType? employeeType,
    double? hourlyRate,
    double? dailyRate,
    OvertimeType? overtimeType,
    double? overtimeRate,
    List<OvertimeSlot>? overtimeSlots,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      mobileNo: mobileNo ?? this.mobileNo,
      position: position ?? this.position,
      department: department ?? this.department,
      salary: salary ?? this.salary,
      createdAt: createdAt ?? this.createdAt,
      employeeType: employeeType ?? this.employeeType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      overtimeType: overtimeType ?? this.overtimeType,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      overtimeSlots: overtimeSlots ?? this.overtimeSlots,
    );
  }
}
