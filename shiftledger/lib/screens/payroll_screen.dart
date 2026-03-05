import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../providers/payroll_provider.dart';
import '../utills/app_colors.dart';
import '../widgets/loader.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payrollState = ref.watch(payrollProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final theme = Theme.of(context);

    // Filter payroll records based on search query
    final filteredRecords = payrollState.payrollRecords.where((payroll) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return payroll.employeeName.toLowerCase().contains(query) ||
          payroll.employeeId.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Payroll'),
              centerTitle: true,
            ),
      body: Column(
        children: [
          // Date Range Selector
          _buildDateRangeSelector(context, ref, payrollState, theme),
          
          // Generate Button
          _buildGenerateButton(context, ref, payrollState),
          
          // Payroll Summary (if generated) - Now scrollable
          if (payrollState.isGenerated && payrollState.payrollRecords.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPayrollSummary(payrollState),
            ),
          
          // Search Bar (if generated)
          if (payrollState.isGenerated && payrollState.payrollRecords.isNotEmpty)
            _buildSearchBar(),
          
          // Payroll List
          Expanded(
            child: payrollState.isLoading
                ? const Center(child: AppLoader(size: 60))
                : payrollState.payrollRecords.isEmpty
                    ? _buildEmptyState(context, payrollState.isGenerated)
                    : filteredRecords.isEmpty
                        ? _buildNoSearchResults()
                        : isDesktop
                            ? _buildPayrollTable(context, filteredRecords, theme)
                            : _buildPayrollList(context, filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by employee name or ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTable(BuildContext context, List<PayrollModel> payrollRecords, ThemeData theme) {
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        color: cardColor,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            theme.brightness == Brightness.dark
                ? Colors.grey.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.08),
          ),
          headingRowHeight: 56,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          columnSpacing: 32,
          horizontalMargin: 32,
          dividerThickness: 1,
          border: TableBorder(
            horizontalInside: BorderSide(
              color: dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Employee ID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Employee Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Working Days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Working Hours',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Base Salary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'OT Hours',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'OT Salary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Total Salary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              numeric: true,
            ),
          ],
          rows: payrollRecords.map((payroll) {
            return DataRow(
              cells: [
                // Employee ID
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      payroll.employeeId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Employee Name
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 18,
                        child: Text(
                          payroll.employeeName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          payroll.employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Working Days
                DataCell(
                  SelectableText(
                    '${payroll.workingDays}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Working Hours
                DataCell(
                  SelectableText(
                    payroll.workingHours.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Base Salary
                DataCell(
                  SelectableText(
                    '₹${payroll.workSalary.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                // OT Hours
                DataCell(
                  SelectableText(
                    payroll.overtimeHours.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: payroll.overtimeHours > 0 ? Colors.purple : Colors.grey,
                    ),
                  ),
                ),
                // OT Salary
                DataCell(
                  SelectableText(
                    '₹${payroll.overtimeSalary.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: payroll.overtimeSalary > 0 ? Colors.purple : Colors.grey,
                    ),
                  ),
                ),
                // Total Salary
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: SelectableText(
                      '₹${payroll.totalSalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    WidgetRef ref,
    PayrollState state,
    ThemeData theme,
  ) {
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payroll Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Start Date
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(context, ref, state),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.startDate != null
                                  ? DateFormat('dd MMM yyyy').format(state.startDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // End Date
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndDate(context, ref, state),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.endDate != null
                                  ? DateFormat('dd MMM yyyy').format(state.endDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick Select Buttons
          Row(
            children: [
              _buildQuickSelectButton(
                context,
                ref,
                'This Month',
                () => _selectThisMonth(ref),
              ),
              const SizedBox(width: 8),
              _buildQuickSelectButton(
                context,
                ref,
                'Last Month',
                () => _selectLastMonth(ref),
              ),
              const SizedBox(width: 8),
              _buildQuickSelectButton(
                context,
                ref,
                'This Week',
                () => _selectThisWeek(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    WidgetRef ref,
    PayrollState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _generatePayroll(context, ref),
              icon: const Icon(Icons.calculate),
              label: const Text('Generate Payroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (state.isGenerated && state.payrollRecords.isNotEmpty) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _savePayroll(context, ref),
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayrollSummary(PayrollState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Payroll Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Employees',
                  state.totalEmployees.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Total Salary',
                  '₹${state.totalSalary.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Base Salary',
                  '₹${state.totalWorkSalary.toStringAsFixed(0)}',
                  Icons.work,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Overtime',
                  '₹${state.totalOvertimeSalary.toStringAsFixed(0)}',
                  Icons.access_time,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool wasGenerated) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            wasGenerated ? Icons.inbox : Icons.calculate_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            wasGenerated
                ? 'No attendance records found'
                : 'Select date range and generate payroll',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wasGenerated
                ? 'No employees have attendance in this period'
                : 'Click "Generate Payroll" to calculate salaries',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollList(BuildContext context, List<PayrollModel> payrollRecords) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payrollRecords.length,
      itemBuilder: (context, index) {
        final payroll = payrollRecords[index];
        return _buildPayrollCard(context, payroll);
      },
    );
  }

  Widget _buildPayrollCard(BuildContext context, PayrollModel payroll) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        payroll.employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SelectableText(
                        'ID: ${payroll.employeeId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: SelectableText(
                    '₹${payroll.totalSalary.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Attendance Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Working Days',
                    '${payroll.workingDays} days',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Working Hours',
                    '${payroll.workingHours.toStringAsFixed(1)} hrs',
                    Icons.access_time,
                    Colors.orange,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Base Salary',
                    '₹${payroll.workSalary.toStringAsFixed(0)}',
                    Icons.work,
                    Colors.green,
                  ),
                  if (payroll.overtimeHours > 0) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Overtime (${payroll.overtimeHours.toStringAsFixed(1)} hrs)',
                      '₹${payroll.overtimeSalary.toStringAsFixed(0)}',
                      Icons.timer,
                      Colors.purple,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(
    BuildContext context,
    WidgetRef ref,
    PayrollState state,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(payrollProvider.notifier).setStartDate(picked);
    }
  }

  Future<void> _selectEndDate(
    BuildContext context,
    WidgetRef ref,
    PayrollState state,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.endDate ?? DateTime.now(),
      firstDate: state.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(payrollProvider.notifier).setEndDate(picked);
    }
  }

  void _selectThisMonth(WidgetRef ref) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    ref.read(payrollProvider.notifier).setDateRange(startOfMonth, endOfMonth);
  }

  void _selectLastMonth(WidgetRef ref) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    ref.read(payrollProvider.notifier).setDateRange(lastMonth, endOfLastMonth);
  }

  void _selectThisWeek(WidgetRef ref) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    ref.read(payrollProvider.notifier).setDateRange(startOfWeek, endOfWeek);
  }

  Future<void> _generatePayroll(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(payrollProvider.notifier).generatePayroll();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payroll generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate payroll. Please check date range.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePayroll(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(payrollProvider.notifier).savePayroll();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payroll saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save payroll'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
