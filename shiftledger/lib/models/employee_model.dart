enum EmployeeType { hourly, daily }

enum OvertimeType { none, hourwise, slotwise }

class OvertimeSlot {
  final int? id;
  final String? slotName;
  final int startHour;
  final int endHour;
  final double rate;

  const OvertimeSlot({
    this.id,
    this.slotName,
    required this.startHour,
    required this.endHour,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'slot_name': slotName ?? 'Slot',
      'start_time': '${startHour.toString().padLeft(2, '0')}:00:00',
      'end_time': '${endHour.toString().padLeft(2, '0')}:00:00',
      'rate_multiplier': rate, // Mapping rate to multiplier for now
      'startHour': startHour,
      'endHour': endHour,
      'rate': rate,
    };
  }

  factory OvertimeSlot.fromJson(Map<String, dynamic> json) {
    int start = json['startHour'] as int? ?? 0;
    int end = json['endHour'] as int? ?? 0;

    if (json['start_time'] != null && json['start_time'] is String) {
      start = int.tryParse(json['start_time'].split(':')[0]) ?? start;
    }
    if (json['end_time'] != null && json['end_time'] is String) {
      end = int.tryParse(json['end_time'].split(':')[0]) ?? end;
    }

    return OvertimeSlot(
      id: json['id'] as int?,
      slotName: json['slot_name'] as String?,
      startHour: start,
      endHour: end,
      rate: (json['rate_multiplier'] as num? ?? json['rate'] as num? ?? 1.0)
          .toDouble(),
    );
  }

  OvertimeSlot copyWith({
    int? id,
    String? slotName,
    int? startHour,
    int? endHour,
    double? rate,
  }) {
    return OvertimeSlot(
      id: id ?? this.id,
      slotName: slotName ?? this.slotName,
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
  final int? salaryConfigId;
  final bool status;
  final double salary; // Kept for backward compatibility
  final DateTime createdAt;
  final DateTime? joinDate;

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
    this.salaryConfigId,
    this.status = true,
    required this.salary,
    required this.createdAt,
    this.joinDate,
    required this.salaryOriginal,
    required this.salaryType,
    this.employeeType = EmployeeType.hourly,
    this.hourlyRate,
    this.dailyRate,
    this.overtimeType = OvertimeType.hourwise,
    this.overtimeRate = 0.0,
    this.overtimeSlots = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'employee_code': employeeCode,
      'phone': mobileNo,
      'position': position,
      'department': department,
      'department_id': departmentId,
      'designation_id': designationId,
      'salary_config_id': salaryConfigId,
      'status': status,
      'salary': salary,
      'created_at': createdAt.toIso8601String(),
      'join_date': joinDate?.toIso8601String(),
      'salary_original': salaryOriginal,
      'salary_type': salaryType,
      'employee_type': employeeType.name,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'overtime_type': overtimeType.name,
      'overtime_rate': overtimeRate,
      'overtime_slots': overtimeSlots.map((s) => s.toJson()).toList(),
    };
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Handle both frontend (name) and backend (first_name, last_name, full_name)
    String fName = json['first_name'] ?? '';
    String lName = json['last_name'] ?? '';
    String fullName = json['full_name'] ?? json['name'] ?? '';

    if (fName.isEmpty && fullName.isNotEmpty) {
      final nameParts = fullName
          .trim()
          .split(' ')
          .where((s) => s.isNotEmpty)
          .toList();
      fName = nameParts.isNotEmpty ? nameParts[0] : '';
      lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    // Overtime Type mapping from snake_case or camelCase
    OvertimeType ovType = OvertimeType.hourwise;
    final ovTypeStr = json['overtime_type'] ?? json['overtimeType'];
    if (ovTypeStr != null) {
      ovType = OvertimeType.values.firstWhere(
        (e) => e.name == ovTypeStr,
        orElse: () => OvertimeType.hourwise,
      );
    }

    // Employee Type mapping
    EmployeeType empType = EmployeeType.hourly;
    final empTypeStr = json['employee_type'] ?? json['employeeType'];
    if (empTypeStr != null) {
      empType = EmployeeType.values.firstWhere(
        (e) => e.name == empTypeStr,
        orElse: () => EmployeeType.hourly,
      );
    }

    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: fName,
      lastName: lName,
      employeeCode: json['employee_code'] ?? json['employeeCode'] ?? '',
      mobileNo: json['phone'] ?? json['mobileNo'] ?? '',
      department: json['Department'] != null
          ? json['Department']['department_name'] ?? ''
          : (json['department_name'] ?? json['department'] ?? ''),
      position: json['Designation'] != null
          ? json['Designation']['designation_name'] ?? ''
          : (json['designation_name'] ?? json['position'] ?? ''),
      departmentId: _parseId(json['department_id']),
      designationId: _parseId(json['designation_id']),
      salaryConfigId: _parseId(json['salary_config_id'] ?? json['salaryConfigId']),
      status: json['status'] is bool ? json['status'] : (json['status'] == 1 || json['status'] == '1'),
      salary: _parseDouble(json['salary'] ?? json['monthly_salary']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      joinDate: _parseOptionalDate(json['join_date'] ?? json['joinDate']),
      salaryOriginal: _parseDouble(
        json['salary_original'] ?? json['salaryOriginal'] ?? json['monthly_salary'] ?? json['salary'],
      ),
      salaryType: (json['salary_type'] ?? json['salaryType'] as String?) ?? 'hourwise',
      employeeType: empType,
      hourlyRate: _parseDouble(json['hourly_rate'] ?? json['hourlyRate']),
      dailyRate: _parseDouble(json['daily_rate'] ?? json['dailyRate']),
      overtimeType: ovType,
      overtimeRate: _parseDouble(json['overtime_rate'] ?? json['overtimeRate']),
      overtimeSlots:
          (json['overtime_slots'] ?? json['overtimeSlots'] as List<dynamic>?)
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
    int? salaryConfigId,
    bool? status,
    double? salary,
    DateTime? createdAt,
    DateTime? joinDate,
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
      salaryConfigId: salaryConfigId ?? this.salaryConfigId,
      status: status ?? this.status,
      salary: salary ?? this.salary,
      createdAt: createdAt ?? this.createdAt,
      joinDate: joinDate ?? this.joinDate,
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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) return DateTime.parse(value);
      return null;
    } catch (e) {
      return null;
    }
  }
}
