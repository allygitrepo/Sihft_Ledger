class EmployeeModel {
  final String id;
  final String name;
  final String employeeCode;
  final String mobileNo;
  final String position;
  final String department;
  final double salary;
  final DateTime createdAt;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.mobileNo,
    required this.position,
    required this.department,
    required this.salary,
    required this.createdAt,
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
    );
  }
}
