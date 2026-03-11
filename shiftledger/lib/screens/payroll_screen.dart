import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../providers/payroll_provider.dart';
import '../utills/app_colors.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';

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
          : AppBar(title: const Text('Payroll'), centerTitle: true),
      body: Container(
        color: theme.brightness == Brightness.light ? Colors.grey[50] : null,
        child: Column(
          children: [
            // Fixed top part (Filters & Search)
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDateRangeSelector(context, ref, payrollState, theme),
                  _buildGenerateButton(context, ref, payrollState),
                  if (payrollState.isGenerated &&
                      payrollState.payrollRecords.isNotEmpty)
                    _buildSearchBar(),
                ],
              ),
            ),

            // Scrollable bottom part
            Expanded(
              child: payrollState.isLoading
                  ? const Center(child: AppLoader(size: 60))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          if (payrollState.isGenerated &&
                              payrollState.payrollRecords.isNotEmpty)
                            _buildPayrollSummary(payrollState),

                          const SizedBox(height: 8),

                          if (payrollState.payrollRecords.isEmpty)
                            _buildEmptyState(context, payrollState.isGenerated)
                          else if (filteredRecords.isEmpty)
                            _buildNoSearchResults()
                          else if (isDesktop)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildPayrollTable(
                                context,
                                filteredRecords,
                                theme,
                              ),
                            )
                          else
                            _buildPayrollList(context, filteredRecords),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by employee name or ID...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
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
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTable(
    BuildContext context,
    List<PayrollModel> payrollRecords,
    ThemeData theme,
  ) {
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              DataColumn(
                label: Text(
                  'Employee Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              DataColumn(
                label: Text(
                  'Working Days',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Working Hours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Base Salary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'OT Hours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'OT Salary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Total Salary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                        color: payroll.overtimeHours > 0
                            ? Colors.purple
                            : Colors.grey,
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
                        color: payroll.overtimeSalary > 0
                            ? Colors.purple
                            : Colors.grey,
                      ),
                    ),
                  ),
                  // Total Salary
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payroll Period',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Start Date
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(context, ref, state),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.startDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(state.startDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.endDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(state.endDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    WidgetRef ref,
    PayrollState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _generatePayroll(context, ref),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calculate_rounded),
              label: Text(
                state.isLoading ? 'Processing...' : 'Generate Payroll',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (state.isGenerated && state.payrollRecords.isNotEmpty) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _savePayroll(context, ref),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payroll Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Employees',
                          state.totalEmployees.toString(),
                          Icons.people_alt_rounded,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total Net Salary',
                          '₹${state.totalSalary.toStringAsFixed(0)}',
                          Icons.payments_rounded,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Base Salary Pool',
                          '₹${state.totalWorkSalary.toStringAsFixed(0)}',
                          Icons.business_center_rounded,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Overtime Pool',
                          '₹${state.totalOvertimeSalary.toStringAsFixed(0)}',
                          Icons.more_time_rounded,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            wasGenerated
                ? 'No employees have attendance in this period'
                : 'Click "Generate Payroll" to calculate salaries',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollList(
    BuildContext context,
    List<PayrollModel> payrollRecords,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: payrollRecords.map((payroll) {
          return _buildPayrollCard(context, payroll);
        }).toList(),
      ),
    );
  }

  Widget _buildPayrollCard(BuildContext context, PayrollModel payroll) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
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
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
      ToastHelper.success('Payroll generated successfully');
    } else {
      ToastHelper.error('Failed to generate payroll. Please check date range.');
    }
  }

  Future<void> _savePayroll(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(payrollProvider.notifier).savePayroll();

    if (!context.mounted) return;

    if (success) {
      ToastHelper.success('Payroll saved successfully');
    } else {
      ToastHelper.error('Failed to save payroll');
    }
  }
}
