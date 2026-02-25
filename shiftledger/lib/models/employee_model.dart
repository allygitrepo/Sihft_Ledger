class EmployeeModel {
  final String id;
  final String name;
  final String employeeCode;
  final double? baseSalary;
  final double? hourlyRate;
  final double? perUnitRate;
  final DateTime createdAt;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.employeeCode,
    this.baseSalary,
    this.hourlyRate,
    this.perUnitRate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeCode': employeeCode,
      'baseSalary': baseSalary,
      'hourlyRate': hourlyRate,
      'perUnitRate': perUnitRate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      employeeCode: json['employeeCode'] as String,
      baseSalary: (json['baseSalary'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      perUnitRate: (json['perUnitRate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? employeeCode,
    double? baseSalary,
    double? hourlyRate,
    double? perUnitRate,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      baseSalary: baseSalary ?? this.baseSalary,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      perUnitRate: perUnitRate ?? this.perUnitRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
