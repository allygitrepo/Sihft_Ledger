import 'dart:convert';

class DepartmentModel {
  final String id;
  final String companyId;
  final String departmentName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool status;

  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.departmentName,
    required this.createdAt,
    required this.updatedAt,
    this.status = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'department_name': departmentName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      departmentName: map['department_name'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      status: map['status'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory DepartmentModel.fromJson(String source) =>
      DepartmentModel.fromMap(json.decode(source));

  DepartmentModel copyWith({
    String? id,
    String? companyId,
    String? departmentName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? status,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      departmentName: departmentName ?? this.departmentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
