import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../services/attendance_service.dart';
import '../services/salary_calculator_service.dart';
import '../providers/settings_provider.dart';
import '../providers/company_provider.dart';
import '../providers/employee_provider.dart';

// Attendance Form State
class AttendanceFormState {
  final EmployeeModel? selectedEmployee;
  final DateTime selectedDate;

  // Time tracking
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  // Calculated values
  final double calculatedWorkingHours;
  final double workSalary;
  final double overtimeHours;
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
    this.calculatedWorkingHours = 0.0,
    this.workSalary = 0.0,
    this.overtimeHours = 0.0,
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
    double? calculatedWorkingHours,
    double? workSalary,
    double? overtimeHours,
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
      calculatedWorkingHours:
          calculatedWorkingHours ?? this.calculatedWorkingHours,
      workSalary: workSalary ?? this.workSalary,
      overtimeHours: overtimeHours ?? this.overtimeHours,
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
    // Watch settings to recalculate if they change
    ref.watch(settingsProvider);
    return AttendanceFormState(selectedDate: DateTime.now());
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

  void setManualOvertimeHours(double hours) {
    state = state.copyWith(overtimeHours: hours);
    _recalculate(useManualOvertime: true);
  }

  void _recalculate({bool useManualOvertime = false}) {
    if (state.selectedEmployee == null || state.calculatedWorkingHours <= 0) {
      return;
    }

    final employee = state.selectedEmployee!;
    final settings = ref.read(settingsProvider);

    // Calculate all salary components using the new service
    final calculation = SalaryCalculatorService.calculateAttendanceSalary(
      employee: employee,
      workingHours: state.calculatedWorkingHours,
      settings: settings,
      manualOvertimeHours: useManualOvertime ? state.overtimeHours : null,
    );

    // Determine attendance status based on working hours
    final status = _determineStatusFromHours(
      state.calculatedWorkingHours,
      settings.fixedHoursPerDay,
    );

    state = state.copyWith(
      workSalary: calculation['workSalary']!,
      overtimeHours: calculation['overtimeHours']!,
      overtimeSalary: calculation['overtimeSalary']!,
      totalSalary: calculation['totalSalary']!,
      attendanceStatus: status,
    );
  }

  AttendanceStatus _determineStatusFromHours(double hours, double fixedHours) {
    if (hours >= fixedHours) {
      return AttendanceStatus.fullDay;
    } else if (hours >= fixedHours / 2) {
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
    if (state.calculatedWorkingHours > 24) {
      return false;
    }

    // Check for duplicate attendance (optional since backend upserts, but prevents accidental submits)
    final exists = await AttendanceService.checkAttendanceExists(
      state.selectedEmployee!.id,
      state.selectedDate,
    );
    if (exists) {
      return false; // Duplicate attendance
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

      // Refresh attendance list
      ref.read(attendanceListProvider.notifier).loadAttendance();

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
    state = AttendanceFormState(selectedDate: DateTime.now());
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
    // Watch for company and settings changes to reload attendance
    ref.watch(companyProvider);
    ref.watch(settingsProvider);

    // Load attendance asynchronously after build - load ALL records
    Future.microtask(() => loadEmployeesThenAttendance());
    return const AttendanceListState(isLoading: true);
  }

  Future<void> loadEmployeesThenAttendance() async {
    // Ensure employees are loaded before attendance to have names/metadata
    await ref.read(employeeProvider.notifier).loadEmployees();
    await loadAttendance();
  }

  Future<void> loadAttendance({DateTime? date}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Get current company ID for filtering
      final companyId = ref.read(companyProvider).company?.id;
      
      // If a specific date is provided, load only that date
      // Otherwise, load ALL attendance records
      final List<AttendanceModel> records;
      if (date != null) {
        records = await AttendanceService.getAttendanceByDate(
          date,
          companyId: companyId,
        );
      } else {
        records = await AttendanceService.loadAttendance(
          companyId: companyId,
        );
      }
      
      state = state.copyWith(attendanceRecords: records, isLoading: false);
    } catch (e) {
      print('Error loading attendance: $e');
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

// Attendance Edit State
class AttendanceEditState {
  final AttendanceModel? originalAttendance;
  final EmployeeModel? employee;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  // Calculated values
  final double calculatedWorkingHours;
  final double workSalary;
  final double overtimeHours;
  final double overtimeSalary;
  final double totalSalary;

  final bool isLoading;

  const AttendanceEditState({
    this.originalAttendance,
    this.employee,
    this.checkInTime,
    this.checkOutTime,
    this.calculatedWorkingHours = 0.0,
    this.workSalary = 0.0,
    this.overtimeHours = 0.0,
    this.overtimeSalary = 0.0,
    this.totalSalary = 0.0,
    this.isLoading = false,
  });

  AttendanceEditState copyWith({
    AttendanceModel? originalAttendance,
    EmployeeModel? employee,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? calculatedWorkingHours,
    double? workSalary,
    double? overtimeHours,
    double? overtimeSalary,
    double? totalSalary,
    bool? isLoading,
  }) {
    return AttendanceEditState(
      originalAttendance: originalAttendance ?? this.originalAttendance,
      employee: employee ?? this.employee,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      calculatedWorkingHours:
          calculatedWorkingHours ?? this.calculatedWorkingHours,
      workSalary: workSalary ?? this.workSalary,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeSalary: overtimeSalary ?? this.overtimeSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Attendance Edit Notifier
class AttendanceEditNotifier extends Notifier<AttendanceEditState> {
  @override
  AttendanceEditState build() {
    return const AttendanceEditState();
  }

  void initialize(AttendanceModel attendance, EmployeeModel employee) {
    state = AttendanceEditState(
      originalAttendance: attendance,
      employee: employee,
      checkInTime: attendance.checkIn,
      checkOutTime: attendance.checkOut,
      calculatedWorkingHours: attendance.workingHours,
      workSalary: attendance.workSalary,
      overtimeHours: attendance.overtimeHours,
      overtimeSalary: attendance.overtimeSalary,
      totalSalary: attendance.totalSalary,
    );
  }

  void setCheckIn(DateTime time) {
    state = state.copyWith(checkInTime: time);
    _recalculate();
  }

  void setCheckOut(DateTime time) {
    state = state.copyWith(checkOutTime: time);
    _recalculate();
  }

  void setManualOvertimeHours(double hours) {
    state = state.copyWith(overtimeHours: hours);
    _recalculate(useManualOvertime: true);
  }

  void _recalculate({bool useManualOvertime = false}) {
    if (state.employee == null ||
        state.checkInTime == null ||
        state.checkOutTime == null) {
      return;
    }

    // Calculate working hours
    final workingHours = SalaryCalculatorService.calculateWorkingHours(
      checkIn: state.checkInTime!,
      checkOut: state.checkOutTime!,
    );

    if (workingHours <= 0) {
      return;
    }

    // Get settings and calculate salary
    final settings = ref.read(settingsProvider);
    final calculation = SalaryCalculatorService.calculateAttendanceSalary(
      employee: state.employee!,
      workingHours: workingHours,
      settings: settings,
      manualOvertimeHours: useManualOvertime ? state.overtimeHours : null,
    );

    state = state.copyWith(
      calculatedWorkingHours: calculation['workingHours']!,
      workSalary: calculation['workSalary']!,
      overtimeHours: calculation['overtimeHours']!,
      overtimeSalary: calculation['overtimeSalary']!,
      totalSalary: calculation['totalSalary']!,
    );
  }

  Future<bool> saveChanges() async {
    if (state.originalAttendance == null || state.employee == null) {
      return false;
    }

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
    if (state.calculatedWorkingHours > 24) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Determine attendance status
      final settings = ref.read(settingsProvider);
      final status = state.calculatedWorkingHours >= settings.fixedHoursPerDay
          ? AttendanceStatus.fullDay
          : state.calculatedWorkingHours >= settings.fixedHoursPerDay / 2
          ? AttendanceStatus.halfDay
          : AttendanceStatus.absent;

      final updatedAttendance = state.originalAttendance!.copyWith(
        checkIn: state.checkInTime,
        checkOut: state.checkOutTime,
        workingHours: state.calculatedWorkingHours,
        workSalary: state.workSalary,
        overtimeHours: state.overtimeHours,
        overtimeSalary: state.overtimeSalary,
        totalSalary: state.totalSalary,
        attendanceStatus: status,
      );

      await AttendanceService.updateAttendance(updatedAttendance);

      // Refresh attendance list
      ref.read(attendanceListProvider.notifier).loadAttendance();

      state = const AttendanceEditState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void reset() {
    state = const AttendanceEditState();
  }
}

// Providers
final attendanceEditProvider =
    NotifierProvider<AttendanceEditNotifier, AttendanceEditState>(() {
      return AttendanceEditNotifier();
    });
