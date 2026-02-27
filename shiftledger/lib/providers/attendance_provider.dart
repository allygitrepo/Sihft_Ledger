import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../services/attendance_service.dart';
import '../services/overtime_service.dart';
import '../services/salary_calculator_service.dart';

// Attendance Form State
class AttendanceFormState {
  final EmployeeModel? selectedEmployee;
  final DateTime selectedDate;
  
  // Time tracking
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  
  // Overtime
  final double overtimeHours;
  
  // Calculated values
  final double calculatedWorkingHours;
  final double workSalary;
  final double overtimeSalary;
  final double totalSalary;
  final AttendanceStatus attendanceStatus;
  
  // Loading state
  final bool isLoading;

  const AttendanceFormState({
    this.selectedEmployee,
    required this.selectedDate,
    this.checkInTime,
    this.checkOutTime,
    this.overtimeHours = 0.0,
    this.calculatedWorkingHours = 0.0,
    this.workSalary = 0.0,
    this.overtimeSalary = 0.0,
    this.totalSalary = 0.0,
    this.attendanceStatus = AttendanceStatus.absent,
    this.isLoading = false,
  });

  AttendanceFormState copyWith({
    EmployeeModel? selectedEmployee,
    DateTime? selectedDate,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? overtimeHours,
    double? calculatedWorkingHours,
    double? workSalary,
    double? overtimeSalary,
    double? totalSalary,
    AttendanceStatus? attendanceStatus,
    bool? isLoading,
  }) {
    return AttendanceFormState(
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedDate: selectedDate ?? this.selectedDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      calculatedWorkingHours: calculatedWorkingHours ?? this.calculatedWorkingHours,
      workSalary: workSalary ?? this.workSalary,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Attendance Form Notifier
class AttendanceFormNotifier extends Notifier<AttendanceFormState> {
  @override
  AttendanceFormState build() {
    return AttendanceFormState(
      selectedDate: DateTime.now(),
    );
  }

  void setEmployee(EmployeeModel employee) {
    state = state.copyWith(selectedEmployee: employee);
    _recalculate();
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setCheckIn(DateTime time) {
    state = state.copyWith(checkInTime: time);
    _calculateWorkingHours();
  }

  void setCheckOut(DateTime time) {
    state = state.copyWith(checkOutTime: time);
    _calculateWorkingHours();
  }

  void setOvertimeHours(double hours) {
    state = state.copyWith(overtimeHours: hours);
    _recalculate();
  }

  void setAttendanceStatus(AttendanceStatus status) {
    state = state.copyWith(attendanceStatus: status);
    _recalculate();
  }

  void _calculateWorkingHours() {
    if (state.checkInTime == null || state.checkOutTime == null) {
      return;
    }

    final hours = SalaryCalculatorService.calculateWorkingHours(
      checkIn: state.checkInTime!,
      checkOut: state.checkOutTime!,
    );

    state = state.copyWith(calculatedWorkingHours: hours);
    _recalculate();
  }

  void _recalculate() {
    if (state.selectedEmployee == null) return;

    final employee = state.selectedEmployee!;

    // Calculate work salary based on employee type
    final workSalary = SalaryCalculatorService.calculateWorkSalary(
      employee: employee,
      workingHours: state.calculatedWorkingHours,
      status: state.attendanceStatus,
    );

    // Calculate overtime
    final overtimeSalary = state.overtimeHours > 0
        ? OvertimeService.calculateOvertimeSalary(
            overtimeHours: state.overtimeHours,
            employee: employee,
          )
        : 0.0;

    // Calculate total
    final totalSalary = SalaryCalculatorService.calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    // Determine status for daily employees
    AttendanceStatus status = state.attendanceStatus;
    if (employee.employeeType == EmployeeType.daily) {
      // For daily employees, status is manually set
      // Keep the current status
    } else {
      // For hourly employees, determine status based on hours
      status = _determineStatusFromHours(state.calculatedWorkingHours);
    }

    state = state.copyWith(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
      totalSalary: totalSalary,
      attendanceStatus: status,
    );
  }

  AttendanceStatus _determineStatusFromHours(double hours) {
    if (hours >= 8.0) {
      return AttendanceStatus.fullDay;
    } else if (hours >= 4.0) {
      return AttendanceStatus.halfDay;
    } else {
      return AttendanceStatus.absent;
    }
  }

  Future<bool> saveAttendance() async {
    if (state.selectedEmployee == null) return false;

    // Validation
    if (state.checkInTime == null || state.checkOutTime == null) {
      return false;
    }
    if (state.checkOutTime!.isBefore(state.checkInTime!)) {
      return false;
    }
    if (state.calculatedWorkingHours <= 0) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final attendance = AttendanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: state.selectedEmployee!.id,
        employeeName: state.selectedEmployee!.name,
        date: state.selectedDate,
        checkIn: state.checkInTime!,
        checkOut: state.checkOutTime!,
        workingHours: state.calculatedWorkingHours,
        attendanceStatus: state.attendanceStatus,
        workSalary: state.workSalary,
        overtimeHours: state.overtimeHours,
        overtimeSalary: state.overtimeSalary,
        totalSalary: state.totalSalary,
      );

      await AttendanceService.addAttendance(attendance);
      
      // Reset form
      state = AttendanceFormState(
        selectedDate: DateTime.now(),
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void reset() {
    state = AttendanceFormState(
      selectedDate: DateTime.now(),
    );
  }
}

// Attendance List State
class AttendanceListState {
  final List<AttendanceModel> attendanceRecords;
  final bool isLoading;

  const AttendanceListState({
    this.attendanceRecords = const [],
    this.isLoading = false,
  });

  AttendanceListState copyWith({
    List<AttendanceModel>? attendanceRecords,
    bool? isLoading,
  }) {
    return AttendanceListState(
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Attendance List Notifier
class AttendanceListNotifier extends Notifier<AttendanceListState> {
  @override
  AttendanceListState build() {
    // Load attendance asynchronously after build
    Future.microtask(() => loadAttendance());
    return const AttendanceListState(isLoading: true);
  }

  Future<void> loadAttendance() async {
    try {
      state = state.copyWith(isLoading: true);
      final records = await AttendanceService.loadAttendance();
      state = state.copyWith(attendanceRecords: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(attendanceRecords: [], isLoading: false);
    }
  }

  Future<void> deleteAttendance(String id) async {
    state = state.copyWith(isLoading: true);
    await AttendanceService.deleteAttendance(id);
    await loadAttendance();
  }

  List<AttendanceModel> getAttendanceByDate(DateTime date) {
    return state.attendanceRecords.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  List<AttendanceModel> getAttendanceByEmployee(String employeeId) {
    return state.attendanceRecords
        .where((r) => r.employeeId == employeeId)
        .toList();
  }
}

// Providers
final attendanceFormProvider =
    NotifierProvider<AttendanceFormNotifier, AttendanceFormState>(() {
  return AttendanceFormNotifier();
});

final attendanceListProvider =
    NotifierProvider<AttendanceListNotifier, AttendanceListState>(() {
  return AttendanceListNotifier();
});
