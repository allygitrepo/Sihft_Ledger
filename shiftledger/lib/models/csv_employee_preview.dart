import 'employee_model.dart';

class CsvEmployeePreview {
  final String employeeCode;
  final String name;
  final String mobileNo;
  final String position;
  final String department;
  final double salary;
  
  // Configurable fields
  EmployeeType employeeType;
  double? hourlyRate;
  double? dailyRate;
  bool useCustomOvertime;
  OvertimeType overtimeType;
  double overtimeRate;
  List<OvertimeSlot> overtimeSlots;

  CsvEmployeePreview({
    required this.employeeCode,
    required this.name,
    required this.mobileNo,
    required this.position,
    required this.department,
    required this.salary,
    this.employeeType = EmployeeType.hourly,
    this.hourlyRate,
    this.dailyRate,
    this.useCustomOvertime = false,
    this.overtimeType = OvertimeType.hourwise,
    this.overtimeRate = 100.0,
    this.overtimeSlots = const [],
  });

  EmployeeModel toEmployeeModel() {
    return EmployeeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString() + employeeCode,
      name: name,
      employeeCode: employeeCode,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      createdAt: DateTime.now(),
      employeeType: employeeType,
      hourlyRate: hourlyRate,
      dailyRate: dailyRate,
      overtimeType: overtimeType,
      overtimeRate: overtimeRate,
      overtimeSlots: overtimeSlots,
    );
  }

  CsvEmployeePreview copyWith({
    String? employeeCode,
    String? name,
    String? mobileNo,
    String? position,
    String? department,
    double? salary,
    EmployeeType? employeeType,
    double? hourlyRate,
    double? dailyRate,
    bool? useCustomOvertime,
    OvertimeType? overtimeType,
    double? overtimeRate,
    List<OvertimeSlot>? overtimeSlots,
  }) {
    return CsvEmployeePreview(
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      mobileNo: mobileNo ?? this.mobileNo,
      position: position ?? this.position,
      department: department ?? this.department,
      salary: salary ?? this.salary,
      employeeType: employeeType ?? this.employeeType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      useCustomOvertime: useCustomOvertime ?? this.useCustomOvertime,
      overtimeType: overtimeType ?? this.overtimeType,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      overtimeSlots: overtimeSlots ?? this.overtimeSlots,
    );
  }
}
