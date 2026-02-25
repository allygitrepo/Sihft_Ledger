import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import '../services/attendance_service.dart';
import '../services/settings_service.dart';
import '../services/overtime_service.dart';
import '../services/salary_calculator_service.dart';

// Attendance Form State
class AttendanceFormState {
  final EmployeeModel? selectedEmployee;
  final DateTime selectedDate;
  final AttendanceType attendanceType;
  
  // Day-wise
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  
  // Hour-wise
  final double workingHours;
  
  // Overtime
  final double overtimeHours;
  
  // Calculated values
  final double calculatedWorkingHours;
  final double workSalary;
  final double overtimeSalary;
  final double totalSalary;
  final AttendanceStatus attendanceStatus;
  final double overtimeRate;
  
  // Settings
  final SettingsModel settings;
  
  // Loading state
  final bool isLoading;

  const AttendanceFormState({
    this.selectedEmployee,
    required this.selectedDate,
    required this.attendanceType,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours = 0.0,
    this.overtimeHours = 0.0,
    this.calculatedWorkingHours = 0.0,
    this.workSalary = 0.0,
    this.overtimeSalary = 0.0,
    this.totalSalary = 0.0,
    this.attendanceStatus = AttendanceStatus.absent,
    this.overtimeRate = 0.0,
    required this.settings,
    this.isLoading = false,
  });

  AttendanceFormState copyWith({
    EmployeeModel? selectedEmployee,
    DateTime? selectedDate,
    AttendanceType? attendanceType,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? workingHours,
    double? overtimeHours,
    double? calculatedWorkingHours,
    double? workSalary,
    double? overtimeSalary,
    double? totalSalary,
    AttendanceStatus? attendanceStatus,
    double? overtimeRate,
    SettingsModel? settings,
    bool? isLoading,
  }) {
    return AttendanceFormState(
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedDate: selectedDate ?? this.selectedDate,
      attendanceType: attendanceType ?? this.attendanceType,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      workingHours: workingHours ?? this.workingHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      calculatedWorkingHours: calculatedWorkingHours ?? this.calculatedWorkingHours,
      workSalary: workSalary ?? this.workSalary,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Attendance Form Notifier
class AttendanceFormNotifier extends Notifier<AttendanceFormState> {
  @override
  AttendanceFormState build() {
    // Load settings asynchronously after build
    Future.microtask(() => _loadSettings());
    return AttendanceFormState(
      selectedDate: DateTime.now(),
      attendanceType: AttendanceType.daywise,
      settings: SettingsModel.defaultSettings(),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadSettings();
      state = state.copyWith(settings: settings);
    } catch (e) {
      print('[AttendanceFormNotifier] Error loading settings: $e');
      // Keep default settings if loading fails
    }
  }

  void setEmployee(EmployeeModel employee) {
    state = state.copyWith(selectedEmployee: employee);
    _recalculate();
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setAttendanceType(AttendanceType type) {
    state = state.copyWith(
      attendanceType: type,
      checkInTime: null,
      checkOutTime: null,
      workingHours: 0.0,
      calculatedWorkingHours: 0.0,
    );
    _recalculate();
  }

  void setCheckIn(DateTime time) {
    state = state.copyWith(checkInTime: time);
    _calculateWorkingHours();
  }

  void setCheckOut(DateTime time) {
    state = state.copyWith(checkOutTime: time);
    _calculateWorkingHours();
  }

  void setWorkingHours(double hours) {
    state = state.copyWith(
      workingHours: hours,
      calculatedWorkingHours: hours,
    );
    _recalculate();
  }

  void setOvertimeHours(double hours) {
    state = state.copyWith(overtimeHours: hours);
    _recalculate();
  }

  void _calculateWorkingHours() {
    if (state.checkInTime == null || state.checkOutTime == null) {
      return;
    }

    final hours = SalaryCalculatorService.calculateWorkingHours(
      checkIn: state.checkInTime!,
      checkOut: state.checkOutTime!,
      breakMinutes: state.settings.breakMinutes,
    );

    state = state.copyWith(calculatedWorkingHours: hours);
    _recalculate();
  }

  void _recalculate() {
    if (state.selectedEmployee == null) return;

    final hourlySalary = SalaryCalculatorService.calculateHourlySalary(
      monthlySalary: state.selectedEmployee!.salary,
    );

    // Calculate work salary
    final workSalary = SalaryCalculatorService.calculateWorkSalary(
      workingHours: state.calculatedWorkingHours,
      hourlySalary: hourlySalary,
    );

    // Calculate overtime
    final overtimeSalary = state.settings.overtimeEnabled
        ? OvertimeService.calculateOvertimeSalary(
            overtimeHours: state.overtimeHours,
            settings: state.settings,
          )
        : 0.0;

    final overtimeRate = state.settings.overtimeEnabled
        ? OvertimeService.getOvertimeRate(
            overtimeHours: state.overtimeHours,
            settings: state.settings,
          )
        : 0.0;

    // Calculate total
    final totalSalary = SalaryCalculatorService.calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    // Determine status
    final status = _determineStatus(state.calculatedWorkingHours);

    state = state.copyWith(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
      totalSalary: totalSalary,
      attendanceStatus: status,
      overtimeRate: overtimeRate,
    );
  }

  AttendanceStatus _determineStatus(double hours) {
    if (hours >= state.settings.fullDayHours) {
      return AttendanceStatus.fullDay;
    } else if (hours >= state.settings.halfDayHours) {
      return AttendanceStatus.halfDay;
    } else {
      return AttendanceStatus.absent;
    }
  }

  Future<bool> saveAttendance() async {
    if (state.selectedEmployee == null) return false;

    // Validation
    if (state.attendanceType == AttendanceType.daywise) {
      if (state.checkInTime == null || state.checkOutTime == null) {
        return false;
      }
      if (state.checkOutTime!.isBefore(state.checkInTime!)) {
        return false;
      }
    } else {
      if (state.calculatedWorkingHours <= 0) {
        return false;
      }
    }

    state = state.copyWith(isLoading: true);

    try {
      final hourlySalary = SalaryCalculatorService.calculateHourlySalary(
        monthlySalary: state.selectedEmployee!.salary,
      );

      final attendance = AttendanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: state.selectedEmployee!.id,
        employeeName: state.selectedEmployee!.name,
        date: state.selectedDate,
        attendanceType: state.attendanceType,
        checkInTime: state.checkInTime,
        checkOutTime: state.checkOutTime,
        workingHours: state.calculatedWorkingHours,
        overtimeHours: state.overtimeHours,
        overtimeRate: state.overtimeRate,
        overtimeSalary: state.overtimeSalary,
        hourlySalary: hourlySalary,
        workSalary: state.workSalary,
        totalSalary: state.totalSalary,
        attendanceStatus: state.attendanceStatus,
      );

      await AttendanceService.addAttendance(attendance);
      
      // Reset form
      state = AttendanceFormState(
        selectedDate: DateTime.now(),
        attendanceType: AttendanceType.daywise,
        settings: state.settings,
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
      attendanceType: AttendanceType.daywise,
      settings: state.settings,
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
      print('[AttendanceListNotifier] Starting to load attendance...');
      state = state.copyWith(isLoading: true);
      final records = await AttendanceService.loadAttendance();
      print('[AttendanceListNotifier] Loaded ${records.length} attendance records');
      state = state.copyWith(attendanceRecords: records, isLoading: false);
      print('[AttendanceListNotifier] State updated successfully');
    } catch (e) {
      print('[AttendanceListNotifier] Error loading attendance: $e');
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
