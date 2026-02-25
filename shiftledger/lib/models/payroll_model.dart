class PayrollModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  final double basePay;
  final double overtimePay;
  final double totalPay;
  final int? daysPresent;
  final double? totalHoursWorked;
  final int? totalUnitsProduced;
  final DateTime generatedAt;

  const PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.basePay,
    required this.overtimePay,
    required this.totalPay,
    this.daysPresent,
    this.totalHoursWorked,
    this.totalUnitsProduced,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'basePay': basePay,
      'overtimePay': overtimePay,
      'totalPay': totalPay,
      'daysPresent': daysPresent,
      'totalHoursWorked': totalHoursWorked,
      'totalUnitsProduced': totalUnitsProduced,
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
      basePay: (json['basePay'] as num).toDouble(),
      overtimePay: (json['overtimePay'] as num).toDouble(),
      totalPay: (json['totalPay'] as num).toDouble(),
      daysPresent: json['daysPresent'] as int?,
      totalHoursWorked: (json['totalHoursWorked'] as num?)?.toDouble(),
      totalUnitsProduced: json['totalUnitsProduced'] as int?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}
