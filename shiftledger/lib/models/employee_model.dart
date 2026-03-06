enum EmployeeType { hourly, daily }

enum OvertimeType { none, hourwise, slotwise }

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
    return {'startHour': startHour, 'endHour': endHour, 'rate': rate};
  }

  factory OvertimeSlot.fromJson(Map<String, dynamic> json) {
    return OvertimeSlot(
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }

  OvertimeSlot copyWith({int? startHour, int? endHour, double? rate}) {
    return OvertimeSlot(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      rate: rate ?? this.rate,
    );
  }
}

class EmployeeModel {
  final String id;
  final String firstName;
  final String lastName;
  final String employeeCode;
  final String mobileNo;
  final String position; // Kept for name display if needed
  final String department; // Kept for name display if needed
  final int? departmentId;
  final int? designationId;
  final double salary; // Kept for backward compatibility
  final DateTime createdAt;

  // Salary conversion fields
  final double
  salaryOriginal; // Original monthly salary from CSV or manual entry
  final String
  salaryType; // 'hourwise' or 'daywise' - matches company configuration

  // New fields for attendance system
  final EmployeeType employeeType;
  final double? hourlyRate;
  final double? dailyRate;
  final OvertimeType overtimeType;
  final double overtimeRate;
  final List<OvertimeSlot> overtimeSlots;

  String get name => '$firstName $lastName'.trim();

  const EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.employeeCode,
    required this.mobileNo,
    required this.position,
    required this.department,
    this.departmentId,
    this.designationId,
    required this.salary,
    required this.createdAt,
    required this.salaryOriginal,
    required this.salaryType,
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
      'first_name': firstName,
      'last_name': lastName,
      'employee_code': employeeCode,
      'mobileNo': mobileNo, // Frontend uses mobileNo, backend might use phone
      'phone': mobileNo, // Add phone for backend
      'position': position,
      'department': department,
      'department_id': departmentId,
      'designation_id': designationId,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
      'salaryOriginal': salaryOriginal,
      'salaryType': salaryType,
      'employeeType': employeeType.name,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'overtimeType': overtimeType.name,
      'overtimeRate': overtimeRate,
      'overtimeSlots': overtimeSlots.map((s) => s.toJson()).toList(),
    };
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Handle both frontend (name) and backend (first_name, last_name)
    String fName = json['first_name'] ?? '';
    String lName = json['last_name'] ?? '';
    if (fName.isEmpty && json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      fName = nameParts[0];
      lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: fName,
      lastName: lName,
      employeeCode: json['employee_code'] ?? json['employeeCode'] ?? '',
      mobileNo: json['phone'] ?? json['mobileNo'] ?? '',
      department: json['Department'] != null
          ? json['Department']['department_name'] ?? ''
          : (json['department'] ?? ''),
      position: json['Designation'] != null
          ? json['Designation']['designation_name'] ?? ''
          : (json['position'] ?? ''),
      departmentId: json['department_id'] is int
          ? json['department_id']
          : int.tryParse(json['department_id']?.toString() ?? ''),
      designationId: json['designation_id'] is int
          ? json['designation_id']
          : int.tryParse(json['designation_id']?.toString() ?? ''),
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
      salaryOriginal:
          (json['salaryOriginal'] as num?)?.toDouble() ??
          (json['salary'] as num?)?.toDouble() ??
          0.0,
      salaryType: (json['salaryType'] as String?) ?? 'hourwise',
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
      overtimeSlots:
          (json['overtimeSlots'] as List<dynamic>?)
              ?.map((s) => OvertimeSlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? employeeCode,
    String? mobileNo,
    String? position,
    String? department,
    int? departmentId,
    int? designationId,
    double? salary,
    DateTime? createdAt,
    double? salaryOriginal,
    String? salaryType,
    EmployeeType? employeeType,
    double? hourlyRate,
    double? dailyRate,
    OvertimeType? overtimeType,
    double? overtimeRate,
    List<OvertimeSlot>? overtimeSlots,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      employeeCode: employeeCode ?? this.employeeCode,
      mobileNo: mobileNo ?? this.mobileNo,
      position: position ?? this.position,
      department: department ?? this.department,
      departmentId: departmentId ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      salary: salary ?? this.salary,
      createdAt: createdAt ?? this.createdAt,
      salaryOriginal: salaryOriginal ?? this.salaryOriginal,
      salaryType: salaryType ?? this.salaryType,
      employeeType: employeeType ?? this.employeeType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      overtimeType: overtimeType ?? this.overtimeType,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      overtimeSlots: overtimeSlots ?? this.overtimeSlots,
    );
  }
}
