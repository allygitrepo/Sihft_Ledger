import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftledger/models/attendance_model.dart';
import 'package:shiftledger/providers/company_provider.dart';
import '../models/payroll_model.dart';
import '../services/payroll_service.dart';
import '../services/attendance_service.dart';

// Payroll State
class PayrollState {
  final List<PayrollModel> payrollRecords;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final bool isGenerated;

  const PayrollState({
    this.payrollRecords = const [],
    this.startDate,
    this.endDate,
    this.isLoading = false,
    this.isGenerated = false,
  });

  PayrollState copyWith({
    List<PayrollModel>? payrollRecords,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    bool? isGenerated,
  }) {
    return PayrollState(
      payrollRecords: payrollRecords ?? this.payrollRecords,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  // Calculate summary statistics
  int get totalEmployees => payrollRecords.length;
  
  double get totalSalary => payrollRecords.fold(
        0.0,
        (sum, payroll) => sum + payroll.totalSalary,
      );
  
  double get totalWorkSalary => payrollRecords.fold(
        0.0,
        (sum, payroll) => sum + payroll.workSalary,
      );
  
  double get totalOvertimeSalary => payrollRecords.fold(
        0.0,
        (sum, payroll) => sum + payroll.overtimeSalary,
      );
  
  int get totalWorkingDays => payrollRecords.fold(
        0,
        (sum, payroll) => sum + payroll.workingDays,
      );
  
  double get totalWorkingHours => payrollRecords.fold(
        0.0,
        (sum, payroll) => sum + payroll.workingHours,
      );
}

// Payroll Notifier
class PayrollNotifier extends Notifier<PayrollState> {
  @override
  PayrollState build() {
    // Initialize with current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return PayrollState(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      isGenerated: false,
    );
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(
      startDate: date,
      isGenerated: false,
    );
  }

  void setEndDate(DateTime date) {
    state = state.copyWith(
      endDate: date,
      isGenerated: false,
    );
  }

  Future<bool> generatePayroll() async {
    if (state.startDate == null || state.endDate == null) {
      return false;
    }

    if (state.endDate!.isBefore(state.startDate!)) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Load all attendance records for the period
      final companyId = ref.read(companyProvider).company?.id;
      final response = await AttendanceService.loadAttendance(
        companyId: companyId,
        startDate: state.startDate,
        endDate: state.endDate,
        limit: 10000, // Fetch a large enough number to cover all records for payroll
      );
      
      final attendanceRecords = response['attendance'] as List<AttendanceModel>;

      // Generate payroll using the service
      final payrollList = PayrollService.generatePayroll(
        attendanceRecords: attendanceRecords,
        startDate: state.startDate!,
        endDate: state.endDate!,
      );

      state = state.copyWith(
        payrollRecords: payrollList,
        isLoading: false,
        isGenerated: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isGenerated: false,
      );
      return false;
    }
  }

  Future<bool> savePayroll() async {
    if (state.payrollRecords.isEmpty) {
      return false;
    }

    try {
      await PayrollService.savePayroll(state.payrollRecords);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadSavedPayroll() async {
    state = state.copyWith(isLoading: true);

    try {
      final payrollList = await PayrollService.loadPayroll();
      state = state.copyWith(
        payrollRecords: payrollList,
        isLoading: false,
        isGenerated: payrollList.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        payrollRecords: [],
        isLoading: false,
        isGenerated: false,
      );
    }
  }

  Future<void> clearPayroll() async {
    await PayrollService.clearPayroll();
    state = state.copyWith(
      payrollRecords: [],
      isGenerated: false,
    );
  }

  void reset() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    state = PayrollState(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
}

// Provider
final payrollProvider = NotifierProvider<PayrollNotifier, PayrollState>(() {
  return PayrollNotifier();
});
