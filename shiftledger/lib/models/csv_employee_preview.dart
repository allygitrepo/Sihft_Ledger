import 'employee_model.dart';

class CsvEmployeePreview {
  final String employeeCode;
  final String firstName;
  final String lastName;
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
    required this.firstName,
    required this.lastName,
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
      firstName: firstName,
      lastName: lastName,
      employeeCode: employeeCode,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      salaryOriginal: salary, // Store original monthly salary
      salaryType: employeeType == EmployeeType.hourly ? 'hourwise' : 'daywise',
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
    String? firstName,
    String? lastName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
