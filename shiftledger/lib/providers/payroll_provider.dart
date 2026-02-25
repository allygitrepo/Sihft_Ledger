import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/payroll_model.dart';
import '../services/payroll_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/toast.dart';

class PayrollState {
  final List<PayrollModel> payrollRecords;
  final bool isLoading;
  final bool isGenerating;

  const PayrollState({
    this.payrollRecords = const [],
    this.isLoading = false,
    this.isGenerating = false,
  });

  PayrollState copyWith({
    List<PayrollModel>? payrollRecords,
    bool? isLoading,
    bool? isGenerating,
  }) {
    return PayrollState(
      payrollRecords: payrollRecords ?? this.payrollRecords,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class PayrollNotifier extends Notifier<PayrollState> {
  @override
  PayrollState build() {
    loadPayroll();
    return const PayrollState();
  }

  Future<void> loadPayroll() async {
    state = state.copyWith(isLoading: true);
    final records = await PayrollService.loadPayroll();
    state = state.copyWith(payrollRecords: records, isLoading: false);
  }

  Future<void> generatePayroll(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(isGenerating: true);
    
    try {
      final settings = ref.read(settingsProvider);
      final payrollList = await PayrollService.generatePayroll(
        startDate: startDate,
        endDate: endDate,
        settings: settings,
      );
      
      state = state.copyWith(
        payrollRecords: payrollList,
        isGenerating: false,
      );
      
      ToastHelper.success('Payroll generated for ${payrollList.length} employees');
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      ToastHelper.error('Failed to generate payroll: $e');
    }
  }

  List<PayrollModel> getEmployeePayroll(String employeeId) {
    return state.payrollRecords
        .where((p) => p.employeeId == employeeId)
        .toList();
  }

  double getTotalPayroll() {
    return state.payrollRecords.fold(
      0.0,
      (sum, payroll) => sum + payroll.totalPay,
    );
  }
}

final payrollProvider = NotifierProvider<PayrollNotifier, PayrollState>(() {
  return PayrollNotifier();
});
