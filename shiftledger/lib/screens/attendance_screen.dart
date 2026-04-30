import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shiftledger/providers/company_provider.dart';
import 'package:shiftledger/providers/department_provider.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/settings_provider.dart';
import '../services/attendance_service.dart';
import '../services/salary_calculator_service.dart';
import '../utills/app_colors.dart';
import '../services/attendance_export_service.dart';
import '../widgets/toast.dart';
import '../widgets/loader.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  // State for bulk attendance - stores modified values per employee
  final Map<String, DateTime> _bulkCheckInTimes = {};
  final Map<String, DateTime> _bulkCheckOutTimes = {};
  final Map<String, AttendanceStatus> _bulkStatuses = {};
  final Map<String, double> _bulkOvertimeHours = {};
  final Map<String, bool> _selectedEmployees =
      {}; // Track selected employees for marking

  int _selectedTabIndex = 0; // Track current tab

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Attendance Table Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDepartment;
  String _tableSearchQuery = '';
  bool _isExporting = false;
  
  Timer? _debounce;
  Timer? _tableDebounce;

  @override
  void initState() {
    super.initState();
    _searchQuery = '';
    _tableSearchQuery = '';
    _isExporting = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tableDebounce?.cancel();
    super.dispose();
  }

  void _reloadAttendance() {
    ref.read(attendanceListProvider.notifier).loadAttendance(
      page: 1,
      search: _tableSearchQuery,
      startDate: _startDate,
      endDate: _endDate,
      department: _selectedDepartment == 'All' ? null : _selectedDepartment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isDesktop ? null : AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          // Custom Tab Bar (50-50 ratio, no container)
          _buildCustomTabBar(),
          // Tab Content
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildMarkAttendanceTab()
                : _buildAttendanceTableTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
      color: cardColor,
      child: Row(
        children: [
          // Mark Attendance Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: _selectedTabIndex == 0
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Attendance Table Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart,
                      color: _selectedTabIndex == 1
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Table',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceTab() {
    final employeeState = ref.watch(employeeProvider);
    final listState = ref.watch(attendanceListProvider);
    final settings = ref.watch(settingsProvider);
    final departmentState = ref.watch(departmentProvider);
    final selectedDate = DateTime.now();
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // Check how many employees have attendance marked for today
    final markedEmployeeIds = listState.markedEmployeeIdsToday.toSet();

    // Check if ALL employees have attendance marked for today
    final allEmployeesMarked =
        (employeeState.employees.isNotEmpty) &&
        employeeState.employees.every(
          (emp) => markedEmployeeIds.contains(emp.id),
        );

    // If ALL employees have attendance marked for today, show message
    if (allEmployeesMarked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Attendance Already Marked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'All employees attendance has been marked for today',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy').format(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTabIndex = 1; // Switch to Attendance Table tab
                  });
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('View Attendance Records'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter out employees who already have attendance marked for today
    final unmarkedEmployees = employeeState.employees.where((employee) {
      return !markedEmployeeIds.contains(employee.id);
    }).toList();

    // Filter employees based on search query is handled by the backend!
    final filteredEmployees = unmarkedEmployees;

    return Column(
      children: [
        // Header Container - Responsive
        Container(
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: isDesktop
              ? Row(
                  children: [
                    // Search Bar
                    Expanded(child: _buildSearchField(theme)),
                    const SizedBox(width: 12),
                    // Today's Date
                    _buildDateBadge(selectedDate),
                    const SizedBox(width: 12),
                    // Save Attendance Button
                    _buildSaveButton(filteredEmployees, selectedDate),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date and Save Button Row
                    Row(
                      children: [
                        Expanded(child: _buildDateBadge(selectedDate)),
                        const SizedBox(width: 12),
                        _buildSaveButton(filteredEmployees, selectedDate),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    _buildSearchField(theme),
                  ],
                ),
        ),
        // Search Results Count (if searching)
        if (_searchQuery != '')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Found ${filteredEmployees.length} of ${unmarkedEmployees.length} unmarked employee(s) matching "${_searchQuery}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Content - Cards for mobile, Table for desktop
        Expanded(
          child: employeeState.isLoading && employeeState.employees.isEmpty
              ? const Center(child: AppLoader())
              : employeeState.employees.isEmpty
              ? _buildEmptyState(employeeState.isLoading)
              : filteredEmployees.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.people_outline
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? unmarkedEmployees.isEmpty
                                    ? 'All attendance marked for today'
                                    : 'No employees found'
                              : 'No matching employees',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? unmarkedEmployees.isEmpty
                                    ? 'All employees have been marked present or absent'
                                    : 'Add employees first to mark attendance'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : isDesktop
              ? SingleChildScrollView(
                  child: _buildBulkAttendanceTable(
                    filteredEmployees,
                    selectedDate,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    return _buildAttendanceCard(
                      filteredEmployees[index],
                      selectedDate,
                    );
                  },
                ),
        ),
        if (employeeState.totalPages > 1)
          _buildEmployeePaginationControls(employeeState),
      ],
    );
  }

  Widget _buildEmployeePaginationControls(EmployeeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.currentPage > 1
                ? () => ref.read(employeeProvider.notifier).loadEmployees(
                      page: state.currentPage - 1,
                      search: _searchQuery,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: state.currentPage < state.totalPages
                ? () => ref.read(employeeProvider.notifier).loadEmployees(
                      page: state.currentPage + 1,
                      search: _searchQuery,
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePaginationControls(AttendanceListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.currentPage > 1
                ? () => ref.read(attendanceListProvider.notifier).loadAttendance(
                      page: state.currentPage - 1,
                      search: _tableSearchQuery,
                      startDate: _startDate,
                      endDate: _endDate,
                      department: _selectedDepartment == 'All' ? null : _selectedDepartment,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: state.currentPage < state.totalPages
                ? () => ref.read(attendanceListProvider.notifier).loadAttendance(
                      page: state.currentPage + 1,
                      search: _tableSearchQuery,
                      startDate: _startDate,
                      endDate: _endDate,
                      department: _selectedDepartment == 'All' ? null : _selectedDepartment,
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          ref.read(employeeProvider.notifier).loadEmployees(
            search: _searchQuery,
            page: 1,
          );
        });
      },
      decoration: InputDecoration(
        hintText: 'Search employees...',
        hintStyle: TextStyle(fontSize: 14, color: theme.hintColor),
        prefixIcon: Icon(Icons.search, color: theme.primaryColor),
        suffixIcon: (_searchQuery != '')
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  ref.read(employeeProvider.notifier).loadEmployees(
                    search: '',
                    page: 1,
                  );
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
      ),
    );
  }

  Widget _buildDateBadge(DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMM yyyy').format(selectedDate),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    List<EmployeeModel> filteredEmployees,
    DateTime selectedDate,
  ) {
    return ElevatedButton.icon(
      onPressed: filteredEmployees.isEmpty
          ? null
          : () => _markAllSelected(filteredEmployees, selectedDate),
      icon: const Icon(Icons.save, size: 18),
      label: const Text('Save'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAttendanceCard(EmployeeModel employee, DateTime date) {
    // Get stored values or use defaults
    final defaultCheckIn = DateTime(date.year, date.month, date.day, 9, 0);
    final defaultCheckOut = DateTime(date.year, date.month, date.day, 18, 0);

    final checkIn = _bulkCheckInTimes[employee.id] ?? defaultCheckIn;
    final checkOut = _bulkCheckOutTimes[employee.id] ?? defaultCheckOut;
    final status = _bulkStatuses[employee.id] ?? AttendanceStatus.fullDay;
    final otHours = _bulkOvertimeHours[employee.id] ?? 0.0;

    // Check if attendance already marked for today
    final attendanceList = ref.watch(attendanceListProvider);
    final alreadyMarked = attendanceList.attendanceRecords.any((record) {
      return record.employeeId == employee.id &&
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    });

    // Check if employee is selected for marking
    final isSelected = _selectedEmployees[employee.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: Text(
                    employee.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.employeeCode,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Employee Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: employee.employeeType == EmployeeType.hourly
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: employee.employeeType == EmployeeType.hourly
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        employee.employeeType == EmployeeType.hourly
                            ? Icons.access_time
                            : Icons.calendar_today,
                        size: 12,
                        color: employee.employeeType == EmployeeType.hourly
                            ? Colors.blue[700]
                            : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.employeeType == EmployeeType.hourly
                            ? 'Hour'
                            : 'Day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: employee.employeeType == EmployeeType.hourly
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Status Checkbox
            if (alreadyMarked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Attendance Already Marked',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedEmployees[employee.id] = value ?? false;
                  });
                },
                title: Text(
                  isSelected ? 'Present' : 'Mark as Present',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
              ),
            if (!alreadyMarked && isSelected) ...[
              const SizedBox(height: 12),
              // Check-in Time
              _buildTimeSelector(
                label: 'Check-in',
                time: checkIn,
                icon: Icons.login,
                iconColor: Colors.green,
                onTap: () => _selectBulkTime(employee, date, true, checkIn),
              ),
              const SizedBox(height: 12),
              // Check-out Time
              _buildTimeSelector(
                label: 'Check-out',
                time: checkOut,
                icon: Icons.logout,
                iconColor: Colors.red,
                onTap: () => _selectBulkTime(employee, date, false, checkOut),
              ),
              const SizedBox(height: 12),
              // Status Dropdown (for daily employees)
              if (employee.employeeType == EmployeeType.daily)
                DropdownButtonFormField<AttendanceStatus>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AttendanceStatus.fullDay,
                      child: Text('Full Day'),
                    ),
                    DropdownMenuItem(
                      value: AttendanceStatus.halfDay,
                      child: Text('Half Day'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _bulkStatuses[employee.id] = value;
                      });
                    }
                  },
                ),
              const SizedBox(height: 12),
              // OT Hours
              TextFormField(
                key: ValueKey('ot_${employee.id}'),
                initialValue: otHours.toString(),
                decoration: InputDecoration(
                  labelText: 'Overtime Hours',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final hours = double.tryParse(value) ?? 0.0;
                  setState(() {
                    _bulkOvertimeHours[employee.id] = hours;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime time,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('hh:mm a').format(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkAttendanceTable(
    List<EmployeeModel> employees,
    DateTime date,
  ) {
    // Safety check
    if (employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No employees available'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.1),
        ),
        columnSpacing: 12,
        horizontalMargin: 12,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 80,
        columns: [
          DataColumn(
            label: Checkbox(
              value: _areAllSelected(employees),
              tristate: true,
              onChanged: (value) => _toggleSelectAll(employees, value),
              activeColor: AppColors.primary,
            ),
          ),
          const DataColumn(
            label: Expanded(
              child: Text(
                'Employee',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const DataColumn(
            label: Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const DataColumn(
            label: Text(
              'Today Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const DataColumn(
            label: Text(
              'Check-in',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const DataColumn(
            label: Text(
              'Check-out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const DataColumn(
            label: Text(
              'OT Hours',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
        rows: employees.map((employee) {
          return _buildBulkAttendanceRow(employee, date);
        }).toList(),
      ),
    );
  }

  DataRow _buildBulkAttendanceRow(EmployeeModel employee, DateTime date) {
    // Get stored values or use defaults
    final defaultCheckIn = DateTime(date.year, date.month, date.day, 9, 0);
    final defaultCheckOut = DateTime(date.year, date.month, date.day, 18, 0);

    final checkIn = _bulkCheckInTimes[employee.id] ?? defaultCheckIn;
    final checkOut = _bulkCheckOutTimes[employee.id] ?? defaultCheckOut;
    final status = _bulkStatuses[employee.id] ?? AttendanceStatus.fullDay;
    final otHours = _bulkOvertimeHours[employee.id] ?? 0.0;

    // Check if attendance already marked for today
    final attendanceList = ref.watch(attendanceListProvider);
    final alreadyMarked = attendanceList.attendanceRecords.any((record) {
      return record.employeeId == employee.id &&
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    });

    // Check if employee is selected for marking
    final isSelected = _selectedEmployees[employee.id] ?? false;

    return DataRow(
      cells: [
        // Checkbox for selection
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: alreadyMarked
                ? null
                : (value) {
                    setState(() {
                      _selectedEmployees[employee.id] = value ?? false;
                    });
                  },
            activeColor: AppColors.primary,
          ),
        ),
        // Employee Name & Code
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                employee.employeeCode,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Employee Type
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: employee.employeeType == EmployeeType.hourly
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: employee.employeeType == EmployeeType.hourly
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  employee.employeeType == EmployeeType.hourly
                      ? Icons.access_time
                      : Icons.calendar_today,
                  size: 11,
                  color: employee.employeeType == EmployeeType.hourly
                      ? Colors.blue[700]
                      : Colors.green[700],
                ),
                const SizedBox(width: 3),
                Text(
                  employee.employeeType == EmployeeType.hourly ? 'Hour' : 'Day',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: employee.employeeType == EmployeeType.hourly
                        ? Colors.blue[700]
                        : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Today Status (Editable - Present/Absent checkbox)
        DataCell(
          alreadyMarked
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Present',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployees[employee.id] = value ?? false;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Text(
                      isSelected ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
        ),
        // Check-in Time
        DataCell(
          InkWell(
            onTap: alreadyMarked
                ? null
                : () => _selectBulkTime(employee, date, true, checkIn),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: alreadyMarked
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.login,
                    size: 12,
                    color: alreadyMarked ? Colors.grey : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(checkIn),
                    style: TextStyle(
                      fontSize: 11,
                      color: alreadyMarked ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Check-out Time
        DataCell(
          InkWell(
            onTap: alreadyMarked
                ? null
                : () => _selectBulkTime(employee, date, false, checkOut),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: alreadyMarked
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout,
                    size: 12,
                    color: alreadyMarked ? Colors.grey : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(checkOut),
                    style: TextStyle(
                      fontSize: 11,
                      color: alreadyMarked ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Status (for daily employees)
        DataCell(
          employee.employeeType == EmployeeType.daily
              ? DropdownButton<AttendanceStatus>(
                  value: status,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: AttendanceStatus.fullDay,
                      child: Text('Full Day', style: TextStyle(fontSize: 11)),
                    ),
                    DropdownMenuItem(
                      value: AttendanceStatus.halfDay,
                      child: Text('Half Day', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  onChanged: alreadyMarked
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _bulkStatuses[employee.id] = value;
                            });
                          }
                        },
                )
              : Text('-', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        // OT Hours
        DataCell(
          SizedBox(
            width: 70,
            child: TextFormField(
              key: ValueKey('ot_${employee.id}'),
              initialValue: otHours.toString(),
              enabled:
                  !alreadyMarked &&
                  isSelected, // Only enable if selected (present)
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                hintText: '0',
                isDense: true,
                filled: true,
                fillColor: (!alreadyMarked && isSelected)
                    ? null
                    : Colors.grey.withOpacity(0.1),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 11,
                color: (!alreadyMarked && isSelected) ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
              onChanged: (value) {
                final hours = double.tryParse(value) ?? 0.0;
                setState(() {
                  _bulkOvertimeHours[employee.id] = hours;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBulkTime(
    EmployeeModel employee,
    DateTime date,
    bool isCheckIn,
    DateTime currentTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
    );

    if (picked != null) {
      final newTime = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        if (isCheckIn) {
          _bulkCheckInTimes[employee.id] = newTime;
        } else {
          _bulkCheckOutTimes[employee.id] = newTime;
        }
      });
    }
  }

  Future<void> _markAllSelected(
    List<EmployeeModel> employees,
    DateTime date,
  ) async {
    // Get all selected employees
    final selectedEmployees = employees.where((emp) {
      return _selectedEmployees[emp.id] == true;
    }).toList();

    if (selectedEmployees.isEmpty) {
      ToastHelper.success('Please select at least one employee to mark');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Attendance'),
        content: Text(
          'Save attendance for ${selectedEmployees.length} selected employee(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mark attendance for all selected employees
    int successCount = 0;
    int failCount = 0;

    for (final employee in selectedEmployees) {
      final checkIn =
          _bulkCheckInTimes[employee.id] ??
          DateTime(date.year, date.month, date.day, 9, 0);
      final checkOut =
          _bulkCheckOutTimes[employee.id] ??
          DateTime(date.year, date.month, date.day, 18, 0);
      final status = _bulkStatuses[employee.id] ?? AttendanceStatus.fullDay;
      final otHours = _bulkOvertimeHours[employee.id] ?? 0.0;

      final success = await _saveSingleAttendance(
        employee,
        date,
        checkIn,
        checkOut,
        status,
        otHours,
        showMessage: false,
      );
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    // Show summary message and switch to table tab
    if (!mounted) return;

    if (successCount > 0) {
      ToastHelper.success(
        'Successfully marked $successCount employee(s)${failCount > 0 ? ', $failCount failed' : ''}',
      );

      // Switch to Attendance Table tab after successful save
      setState(() {
        _selectedTabIndex = 1;
      });
    }
  }

  // Check if all employees are selected
  bool? _areAllSelected(List<EmployeeModel> employees) {
    final attendanceList = ref.watch(attendanceListProvider);
    final selectedDate = DateTime.now();

    // Filter out already marked employees
    final unmarkedEmployees = employees.where((emp) {
      return !attendanceList.attendanceRecords.any((record) {
        return record.employeeId == emp.id &&
            record.date.year == selectedDate.year &&
            record.date.month == selectedDate.month &&
            record.date.day == selectedDate.day;
      });
    }).toList();

    if (unmarkedEmployees.isEmpty) return false;

    final selectedCount = unmarkedEmployees.where((emp) {
      return _selectedEmployees[emp.id] == true;
    }).length;

    if (selectedCount == 0) return false;
    if (selectedCount == unmarkedEmployees.length) return true;
    return null; // Indeterminate state
  }

  // Toggle select all employees
  void _toggleSelectAll(List<EmployeeModel> employees, bool? value) {
    final attendanceList = ref.read(attendanceListProvider);
    final selectedDate = DateTime.now();

    setState(() {
      for (final employee in employees) {
        // Check if already marked
        final alreadyMarked = attendanceList.attendanceRecords.any((record) {
          return record.employeeId == employee.id &&
              record.date.year == selectedDate.year &&
              record.date.month == selectedDate.month &&
              record.date.day == selectedDate.day;
        });

        // Only toggle unmarked employees
        if (!alreadyMarked) {
          _selectedEmployees[employee.id] = value ?? true;
        }
      }
    });
  }

  Future<bool> _saveSingleAttendance(
    EmployeeModel employee,
    DateTime date,
    DateTime checkIn,
    DateTime checkOut,
    AttendanceStatus status,
    double otHours, {
    bool showMessage = true,
  }) async {
    // Check if attendance already marked for this employee today
    final attendanceList = ref.read(attendanceListProvider);
    final alreadyMarked = attendanceList.attendanceRecords.any((record) {
      return record.employeeId == employee.id &&
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    });

    if (alreadyMarked) {
      if (showMessage) {
        ToastHelper.success(
          'Attendance already marked for ${employee.name} today',
        );
      }
      return false;
    }

    // Validate times
    if (checkOut.isBefore(checkIn)) {
      if (showMessage) {
        ToastHelper.error('Check-out time must be after check-in time');
      }
      return false;
    }

    // Calculate working hours
    final workingHours = SalaryCalculatorService.calculateWorkingHours(
      checkIn: checkIn,
      checkOut: checkOut,
    );

    if (workingHours <= 0) {
      if (showMessage) {
        ToastHelper.error('Working hours must be greater than 0');
      }
      return false;
    }

    // Get settings for calculation
    final settings = ref.read(settingsProvider);

    // Calculate all salary components using the new service
    final calculation = SalaryCalculatorService.calculateAttendanceSalary(
      employee: employee,
      workingHours: workingHours,
      settings: settings,
      manualOvertimeHours: otHours, // Pass manual overtime hours
    );

    final workSalary = calculation['workSalary']!;
    final overtimeHours = calculation['overtimeHours']!;
    final overtimeSalary = calculation['overtimeSalary']!;
    final totalSalary = calculation['totalSalary']!;

    // Determine final status based on working hours
    AttendanceStatus finalStatus = status;
    if (employee.salaryType == 'hourwise') {
      // For hourly employees, auto-determine status from hours
      if (workingHours >= settings.fixedHoursPerDay) {
        finalStatus = AttendanceStatus.fullDay;
      } else if (workingHours >= settings.fixedHoursPerDay / 2) {
        finalStatus = AttendanceStatus.halfDay;
      } else {
        finalStatus = AttendanceStatus.absent;
      }
    }

    // Create attendance record with OT hours from input
    final attendance = AttendanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employee.id,
      employeeName: employee.name,
      date: date,
      checkIn: checkIn,
      checkOut: checkOut,
      workingHours: workingHours,
      attendanceStatus: finalStatus,
      workSalary: workSalary,
      overtimeHours: otHours, // Use the OT hours from input
      overtimeSalary: overtimeSalary,
      totalSalary: totalSalary,
    );

    try {
      await AttendanceService.addAttendance(attendance);

      // Clear stored values for this employee
      setState(() {
        _bulkCheckInTimes.remove(employee.id);
        _bulkCheckOutTimes.remove(employee.id);
        _bulkStatuses.remove(employee.id);
        _bulkOvertimeHours.remove(employee.id);
        _selectedEmployees.remove(employee.id);
      });

      // Reload attendance list
      ref.read(attendanceListProvider.notifier).loadAttendance();

      if (!mounted) return true;

      if (showMessage) {
        ToastHelper.success('Attendance marked for ${employee.name}');
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      if (showMessage) {
        ToastHelper.error('Failed to mark attendance for ${employee.name}');
      }

      return false;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return Colors.green;
      case AttendanceStatus.halfDay:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return Icons.check_circle;
      case AttendanceStatus.halfDay:
        return Icons.timelapse;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  Widget _buildAttendanceTableTab() {
    final listState = ref.watch(attendanceListProvider);
    final employeeState = ref.watch(employeeProvider);
    final departmentState = ref.watch(departmentProvider);
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // Only show records that have attendance marked
    var markedRecords = listState.attendanceRecords;

    // Filters are now handled server-side! 
    // We just display the records returned by the provider.

    return Column(
      children: [
        // Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Attendance Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Date Range Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: _startDate != null && _endDate != null
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                        _reloadAttendance();
                      }
                    },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _startDate == null
                          ? 'Select Dates'
                          : '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Clear Filters
                  if (_startDate != null ||
                      _selectedDepartment != null ||
                      _tableSearchQuery != '')
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedDepartment = null;
                          _tableSearchQuery = '';
                        });
                        _reloadAttendance();
                      },
                      icon: const Icon(
                        Icons.filter_list_off,
                        color: Colors.red,
                      ),
                      tooltip: 'Clear Filters',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isDesktop)
                Row(
                  children: [
                    // Department Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment ?? 'All',
                        decoration: InputDecoration(
                          labelText: 'Department',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['All', ...departmentState.departments.map((d) => d.departmentName)]
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                          _reloadAttendance();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _tableSearchQuery = value);
                          if (_tableDebounce?.isActive ?? false) _tableDebounce!.cancel();
                          _tableDebounce = Timer(const Duration(milliseconds: 500), () {
                            _reloadAttendance();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search Employee...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export Button
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting
                            ? null
                            : () => _handleExport(
                                markedRecords,
                                employeeState.employees,
                              ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(
                          _isExporting ? 'Exporting...' : 'Export CSV',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        // Department Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDepartment ?? 'All',
                            decoration: InputDecoration(
                              labelText: 'Department',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: ['All', ..._getDepartments(employeeState.employees)]
                                .map((dept) => DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartment = value;
                              });
                              _reloadAttendance();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Export Button
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _handleExport(
                                      markedRecords,
                                      employeeState.employees,
                                    ),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download, size: 18),
                              label: Text(
                                _isExporting ? 'Exporting...' : 'Export CSV',
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Field
                    TextField(
                      onChanged: (value) {
                        setState(() => _tableSearchQuery = value);
                        if (_tableDebounce?.isActive ?? false) _tableDebounce!.cancel();
                        _tableDebounce = Timer(const Duration(milliseconds: 500), () {
                          _reloadAttendance();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Employee...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Content - Cards for mobile, Table for desktop
        Expanded(
          child:
              (employeeState.isLoading || listState.isLoading) &&
                  employeeState.employees.isEmpty
              ? const Center(child: AppLoader())
              : employeeState.employees.isEmpty
              ? _buildEmptyState(employeeState.isLoading)
              : markedRecords.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mark attendance to see records here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : isDesktop
              ? SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDataTable(markedRecords, employeeState),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: markedRecords.length,
                  itemBuilder: (context, index) {
                    final record = markedRecords[index];
                    // Find employee
                    EmployeeModel? employee;
                    try {
                      employee = employeeState.employees.firstWhere(
                        (e) => e.id == record.employeeId,
                      );
                    } catch (e) {
                      // Employee not found, skip
                      return const SizedBox.shrink();
                    }
                    return _buildAttendanceRecordCard(record, employee);
                  },
                ),
        ),
        if (listState.totalPages > 1)
          _buildAttendancePaginationControls(listState),
      ],
    );
  }

  List<String> _getDepartments(List<EmployeeModel> employees) {
    return employees.map((e) => e.department).toSet().toList();
  }

  Widget _buildAttendanceRecordCard(
    AttendanceModel record,
    EmployeeModel employee,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Employee Info and Date
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: Text(
                    record.employeeName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        record.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        employee.employeeCode,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    DateFormat('dd MMM').format(record.date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Employee Type Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: employee.employeeType == EmployeeType.hourly
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: employee.employeeType == EmployeeType.hourly
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        employee.employeeType == EmployeeType.hourly
                            ? Icons.access_time
                            : Icons.calendar_today,
                        size: 12,
                        color: employee.employeeType == EmployeeType.hourly
                            ? Colors.blue[700]
                            : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.employeeType == EmployeeType.hourly
                            ? 'Hourly'
                            : 'Daily',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: employee.employeeType == EmployeeType.hourly
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                InkWell(
                  onTap: () => _toggleAttendanceStatus(record, employee),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        record.attendanceStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(record.attendanceStatus),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(record.attendanceStatus),
                          size: 12,
                          color: _getStatusColor(record.attendanceStatus),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(record.attendanceStatus),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(record.attendanceStatus),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 10,
                          color: _getStatusColor(record.attendanceStatus),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Time Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.login,
                    iconColor: Colors.green,
                    label: 'Check-in',
                    value: DateFormat('hh:mm a').format(record.checkIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    label: 'Check-out',
                    value: DateFormat('hh:mm a').format(record.checkOut),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Work Hours and Salary
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    iconColor: Colors.blue,
                    label: 'Work Hours',
                    value: '${record.workingHours.toStringAsFixed(1)} hrs',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.currency_rupee,
                    iconColor: Colors.green,
                    label: 'Work Salary',
                    value: '₹${record.workSalary.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            // Overtime Details (if any)
            if (record.overtimeHours > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.timer,
                        iconColor: Colors.orange,
                        label: 'OT Hours',
                        value: '${record.overtimeHours.toStringAsFixed(1)} hrs',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.currency_rupee,
                        iconColor: Colors.orange,
                        label: 'OT Salary',
                        value: '₹${record.overtimeSalary.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Total Salary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Salary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SelectableText(
                    '₹${record.totalSalary.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAttendance(record),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAttendance(record),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDataTable(
    List<AttendanceModel> records,
    EmployeeState employeeState,
  ) {
    // Safety check for empty employees
    if (employeeState.employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No employees found. Please add employees first.'),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        AppColors.primary.withOpacity(0.1),
      ),
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnSpacing: 24,
      horizontalMargin: 16,
      columns: const [
        DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Employee',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Check-in',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Check-out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Work Hrs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Work Salary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text('OT Hrs', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'OT Salary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Total Salary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: records.map((record) {
        // Find employee to get type - handle case where employee might not exist
        EmployeeModel? employeeOrNull;
        try {
          employeeOrNull = employeeState.employees.firstWhere(
            (e) => e.id == record.employeeId,
          );
        } catch (e) {
          // Employee not found, skip this record or use default
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('dd/MM/yy').format(record.date))),
              DataCell(Text(record.employeeName)),
              DataCell(Text('-')),
              DataCell(Text('-')),
              DataCell(Text(DateFormat('hh:mm a').format(record.checkIn))),
              DataCell(Text(DateFormat('hh:mm a').format(record.checkOut))),
              DataCell(Text(record.workingHours.toStringAsFixed(2))),
              DataCell(Text('-')),
              DataCell(Text('₹${record.workSalary.toStringAsFixed(0)}')),
              DataCell(
                Text(
                  record.overtimeHours > 0
                      ? record.overtimeHours.toStringAsFixed(2)
                      : '-',
                ),
              ),
              DataCell(
                Text(
                  record.overtimeSalary > 0
                      ? '₹${record.overtimeSalary.toStringAsFixed(0)}'
                      : '-',
                ),
              ),
              DataCell(Text('₹${record.totalSalary.toStringAsFixed(0)}')),
              DataCell(Text('-')),
            ],
          );
        }

        // Employee is guaranteed to be non-null here
        final employee = employeeOrNull;

        return DataRow(
          cells: [
            // Date
            DataCell(
              SelectableText(DateFormat('dd/MM/yy').format(record.date)),
            ),
            // Employee Name
            DataCell(
              SizedBox(
                width: 150,
                child: SelectableText(record.employeeName, maxLines: 1),
              ),
            ),
            // Employee Code
            DataCell(SelectableText(employee.employeeCode)),
            // Employee Type
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: employee.employeeType == EmployeeType.hourly
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: employee.employeeType == EmployeeType.hourly
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      employee.employeeType == EmployeeType.hourly
                          ? Icons.access_time
                          : Icons.calendar_today,
                      size: 12,
                      color: employee.employeeType == EmployeeType.hourly
                          ? Colors.blue[700]
                          : Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      employee.employeeType == EmployeeType.hourly
                          ? 'Hour'
                          : 'Day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: employee.employeeType == EmployeeType.hourly
                            ? Colors.blue[700]
                            : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Check-in
            DataCell(
              SelectableText(DateFormat('hh:mm a').format(record.checkIn)),
            ),
            // Check-out
            DataCell(
              SelectableText(DateFormat('hh:mm a').format(record.checkOut)),
            ),
            // Working Hours
            DataCell(
              SelectableText(
                record.workingHours.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Status
            DataCell(
              InkWell(
                onTap: () => _toggleAttendanceStatus(record, employee),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      record.attendanceStatus,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(record.attendanceStatus),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(record.attendanceStatus),
                        size: 12,
                        color: _getStatusColor(record.attendanceStatus),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(record.attendanceStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(record.attendanceStatus),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 10,
                        color: _getStatusColor(record.attendanceStatus),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Work Salary
            DataCell(
              SelectableText(
                '₹${record.workSalary.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // OT Hours
            DataCell(
              SelectableText(
                record.overtimeHours > 0
                    ? record.overtimeHours.toStringAsFixed(2)
                    : '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: record.overtimeHours > 0 ? Colors.orange : Colors.grey,
                ),
              ),
            ),
            // OT Salary
            DataCell(
              SelectableText(
                record.overtimeSalary > 0
                    ? '₹${record.overtimeSalary.toStringAsFixed(0)}'
                    : '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: record.overtimeSalary > 0
                      ? Colors.orange
                      : Colors.grey,
                ),
              ),
            ),
            // Total Salary
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₹${record.totalSalary.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            // Actions
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.blue,
                    onPressed: () {
                      _editAttendance(record);
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red,
                    onPressed: () {
                      _deleteAttendance(record);
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return 'Full';
      case AttendanceStatus.halfDay:
        return 'Half';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  Future<void> _toggleAttendanceStatus(
    AttendanceModel record,
    EmployeeModel employee,
  ) async {
    // Show dialog to change status
    final newStatus = await showDialog<AttendanceStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Change Attendance Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee: ${record.employeeName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Date: ${DateFormat('dd MMM yyyy').format(record.date)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select new status:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Status Options
            ...AttendanceStatus.values.map((status) {
              final isSelected = status == record.attendanceStatus;
              return InkWell(
                onTap: () => Navigator.pop(context, status),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getStatusColor(status).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _getStatusColor(status)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                            if (employee.employeeType == EmployeeType.daily)
                              Text(
                                status == AttendanceStatus.fullDay
                                    ? 'Full day rate: ₹${employee.dailyRate?.toStringAsFixed(0) ?? "0"}'
                                    : status == AttendanceStatus.halfDay
                                    ? 'Half day rate: ₹${((employee.dailyRate ?? 0) / 2).toStringAsFixed(0)}'
                                    : 'No salary',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newStatus == null || newStatus == record.attendanceStatus) return;

    // Update the attendance record with new status
    await _updateAttendance(
      record,
      employee,
      record.checkIn,
      record.checkOut,
      newStatus,
      record.overtimeHours,
    );
  }

  void _editAttendance(AttendanceModel record) {
    // Find the employee
    final employeeState = ref.read(employeeProvider);
    final employee = employeeState.employees.firstWhere(
      (e) => e.id == record.employeeId,
      orElse: () => employeeState.employees.first,
    );

    // Show bottom sheet with pre-filled data
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditBottomSheet(record, employee),
    );
  }

  Widget _buildEditBottomSheet(AttendanceModel record, EmployeeModel employee) {
    final checkInController = TextEditingController(
      text: DateFormat('hh:mm a').format(record.checkIn),
    );
    final checkOutController = TextEditingController(
      text: DateFormat('hh:mm a').format(record.checkOut),
    );
    final otHoursController = TextEditingController(
      text: record.overtimeHours.toString(),
    );

    DateTime editCheckIn = record.checkIn;
    DateTime editCheckOut = record.checkOut;
    AttendanceStatus editStatus = record.attendanceStatus;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Employee Info
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    employee.employeeCode,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  // Check-in Time
                  Text(
                    'Check-in Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(editCheckIn),
                      );
                      if (picked != null) {
                        setModalState(() {
                          editCheckIn = DateTime(
                            record.date.year,
                            record.date.month,
                            record.date.day,
                            picked.hour,
                            picked.minute,
                          );
                          checkInController.text = DateFormat(
                            'hh:mm a',
                          ).format(editCheckIn);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(checkInController.text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Check-out Time
                  Text(
                    'Check-out Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(editCheckOut),
                      );
                      if (picked != null) {
                        setModalState(() {
                          editCheckOut = DateTime(
                            record.date.year,
                            record.date.month,
                            record.date.day,
                            picked.hour,
                            picked.minute,
                          );
                          checkOutController.text = DateFormat(
                            'hh:mm a',
                          ).format(editCheckOut);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(checkOutController.text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status (for daily employees)
                  if (employee.employeeType == EmployeeType.daily) ...[
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AttendanceStatus>(
                      initialValue: editStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AttendanceStatus.fullDay,
                          child: Text('Full Day'),
                        ),
                        DropdownMenuItem(
                          value: AttendanceStatus.halfDay,
                          child: Text('Half Day'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => editStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // OT Hours
                  Text(
                    'Overtime Hours',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: otHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Capture navigator before async gap
                        final navigator = Navigator.of(context);
                        // Update attendance record
                        await _updateAttendance(
                          record,
                          employee,
                          editCheckIn,
                          editCheckOut,
                          editStatus,
                          double.tryParse(otHoursController.text) ?? 0.0,
                        );
                        // Use captured navigator
                        navigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateAttendance(
    AttendanceModel record,
    EmployeeModel employee,
    DateTime checkIn,
    DateTime checkOut,
    AttendanceStatus status,
    double otHours,
  ) async {
    // Calculate working hours
    final workingHours = SalaryCalculatorService.calculateWorkingHours(
      checkIn: checkIn,
      checkOut: checkOut,
    );

    // Get settings for calculation
    final settings = ref.read(settingsProvider);

    // Calculate work salary (without overtime)
    final workSalary = SalaryCalculatorService.calculateWorkSalary(
      employee: employee,
      workingHours: workingHours,
      settings: settings,
    );

    // Use user-provided overtime hours instead of auto-calculating
    final overtimeHours = otHours;

    // Calculate overtime salary based on user-provided hours
    final overtimeSalary = SalaryCalculatorService.calculateOvertimeSalary(
      employee: employee,
      overtimeHours: overtimeHours,
      settingsOvertimeRate: settings.defaultOvertimeRate,
    );

    // Calculate total salary
    final totalSalary = SalaryCalculatorService.calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    // Determine final status based on working hours
    AttendanceStatus finalStatus = status;
    if (employee.salaryType == 'hourwise') {
      if (workingHours >= settings.fixedHoursPerDay) {
        finalStatus = AttendanceStatus.fullDay;
      } else if (workingHours >= settings.fixedHoursPerDay / 2) {
        finalStatus = AttendanceStatus.halfDay;
      } else {
        finalStatus = AttendanceStatus.absent;
      }
    }

    // Create updated record with user-provided overtime hours
    final updatedRecord = record.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
      workingHours: workingHours,
      attendanceStatus: finalStatus,
      workSalary: workSalary,
      overtimeHours: overtimeHours,
      overtimeSalary: overtimeSalary,
      totalSalary: totalSalary,
    );

    // Save updated record
    await AttendanceService.updateAttendance(updatedRecord);

    // Reload attendance list
    ref.read(attendanceListProvider.notifier).loadAttendance();

    if (!mounted) return;

    ToastHelper.success('Attendance updated successfully');
  }

  void _deleteAttendance(AttendanceModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text(
          'Are you sure you want to delete attendance record for ${record.employeeName} on ${DateFormat('dd MMM yyyy').format(record.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.pop(context);
              ref
                  .read(attendanceListProvider.notifier)
                  .deleteAttendance(record.id);

              ToastHelper.error('Attendance record deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLoading) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration/Icon (Don't show extra loader inside if we are showing full screen one)

            // Illustration/Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Message
            Text(
              'No Employees Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Add employees manually or import using CSV to start managing attendance.',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildActionCard(
                  title: 'Add Employee',
                  subtitle: 'Register manually',
                  icon: Icons.person_add_outlined,
                  onTap: () {
                    // Navigate to employee screen or show add dialog
                    // For now, just show a message or use navigator
                    Navigator.pushNamed(context, '/employees');
                  },
                ),
                _buildActionCard(
                  title: 'Import CSV',
                  subtitle: 'Bulk upload employees',
                  icon: Icons.upload_file_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/employees');
                    // In a real app, we might open the CSV picker directly here
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.cardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown(List<EmployeeModel> employees) {
    final departments = [
      'All',
      ...employees.map((e) => e.department).toSet().toList(),
    ];

    return DropdownButtonFormField<String>(
      value: _selectedDepartment ?? 'All',
      decoration: InputDecoration(
        labelText: 'Department',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: departments
          .map(
            (dept) => DropdownMenuItem(
              value: dept,
              child: Text(dept, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value == 'All' ? null : value;
        });
      },
    );
  }

  Future<void> _handleExport(
    List<AttendanceModel> currentRecords,
    List<EmployeeModel> employees,
  ) async {
    setState(() => _isExporting = true);

    try {
      // Fetch ALL records matching current filters for export
      final companyId = ref.read(companyProvider).company?.id;
      final response = await AttendanceService.loadAttendance(
        companyId: companyId,
        page: 1,
        limit: 10000, // Large limit for export
        search: _tableSearchQuery,
        startDate: _startDate,
        endDate: _endDate,
        department: _selectedDepartment == 'All' ? null : _selectedDepartment,
      );
      
      final allRecords = response['attendance'] as List<AttendanceModel>;

      if (allRecords.isEmpty) {
        ToastHelper.show('No attendance records available to export.');
        setState(() => _isExporting = false);
        return;
      }

      // Small delay to show "Preparing..." state
      await Future.delayed(const Duration(milliseconds: 500));

      final success = await AttendanceExportService.exportAttendanceToCSV(
        records: allRecords,
        employees: employees,
      );

      if (mounted) {
        setState(() => _isExporting = false);

        if (success) {
          ToastHelper.success('Attendance CSV exported successfully');
        } else {
          ToastHelper.error('Failed to export attendance file.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ToastHelper.error('Error during export: $e');
      }
    }
  }
}
