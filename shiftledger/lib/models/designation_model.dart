import 'dart:convert';

class DesignationModel {
  final int id;
  final int companyId;
  final int departmentId;
  final String designationName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool status;

  DesignationModel({
    required this.id,
    required this.companyId,
    required this.departmentId,
    required this.designationName,
    required this.createdAt,
    required this.updatedAt,
    this.status = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'department_id': departmentId,
      'designation_name': designationName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory DesignationModel.fromMap(Map<String, dynamic> map) {
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

    return DesignationModel(
      id: parseId(map['id']),
      companyId: parseId(map['company_id']),
      departmentId: parseId(map['department_id']),
      designationName: map['designation_name'] ?? 'Unknown',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      status: map['status'] == true || map['status'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory DesignationModel.fromJson(String source) =>
      DesignationModel.fromMap(json.decode(source));

  DesignationModel copyWith({
    int? id,
    int? companyId,
    int? departmentId,
    String? designationName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? status,
  }) {
    return DesignationModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      departmentId: departmentId ?? this.departmentId,
      designationName: designationName ?? this.designationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
