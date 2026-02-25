import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payroll_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    final settings = ref.read(settingsProvider);

    switch (settings.salaryCycle) {
      case SalaryCycle.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case SalaryCycle.weekly:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        endDate = startDate!.add(const Duration(days: 6));
        break;
      case SalaryCycle.custom:
        startDate = settings.customStartDate ?? now;
        endDate = settings.customEndDate ?? now;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final payrollState = ref.watch(payrollProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Payroll'),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(context),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ElevatedButton(
              onPressed: payrollState.isGenerating
                  ? null
                  : () => _generatePayroll(context, ref),
              child: payrollState.isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Payroll'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: payrollState.isLoading
                ? const Center(child: AppLoader(size: 50))
                : payrollState.payrollRecords.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPayrollList(payrollState.payrollRecords, horizontalPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payroll Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context,
                  'Start Date',
                  startDate,
                  (date) => setState(() => startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  context,
                  'End Date',
                  endDate,
                  (date) => setState(() => endDate = date),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Text(
            date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Select',
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollList(List payrollRecords, double horizontalPadding) {
    return ListView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: payrollRecords.length,
      itemBuilder: (context, index) {
        final payroll = payrollRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                payroll.employeeName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              payroll.employeeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Total: ₹${payroll.totalPay.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPayrollRow('Base Pay', payroll.basePay),
                    if (payroll.overtimePay > 0)
                      _buildPayrollRow('Overtime Pay', payroll.overtimePay),
                    if (payroll.daysPresent != null)
                      _buildPayrollRow(
                        'Days Present',
                        payroll.daysPresent.toDouble(),
                        isAmount: false,
                      ),
                    if (payroll.totalHoursWorked != null)
                      _buildPayrollRow(
                        'Hours Worked',
                        payroll.totalHoursWorked,
                        isAmount: false,
                      ),
                    if (payroll.totalUnitsProduced != null)
                      _buildPayrollRow(
                        'Units Produced',
                        payroll.totalUnitsProduced.toDouble(),
                        isAmount: false,
                      ),
                    const Divider(),
                    _buildPayrollRow(
                      'Total Pay',
                      payroll.totalPay,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayrollRow(String label, double value,
      {bool isAmount = true, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isAmount ? '₹${value.toStringAsFixed(2)}' : value.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No payroll generated yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select date range and generate payroll',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePayroll(BuildContext context, WidgetRef ref) async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(payrollProvider.notifier).generatePayroll(
          startDate!,
          endDate!,
        );
  }
}
