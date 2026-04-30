import 'dart:convert';

class DepartmentModel {
  final int id;
  final int companyId;
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
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    int parseId(dynamic id) {
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
      return 0;
    }

    return DepartmentModel(
      id: parseId(map['id']),
      companyId: parseId(map['company_id']),
      departmentName: map['department_name'] ?? 'Unknown',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      status: map['status'] == true || map['status'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory DepartmentModel.fromJson(String source) =>
      DepartmentModel.fromMap(json.decode(source));

  DepartmentModel copyWith({
    int? id,
    int? companyId,
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
