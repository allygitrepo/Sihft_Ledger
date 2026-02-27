import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/employee_provider.dart';
import '../services/attendance_service.dart';
import '../services/overtime_service.dart';
import '../services/salary_calculator_service.dart';
import '../utills/app_colors.dart';

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
  final Map<String, bool> _selectedEmployees = {}; // Track selected employees for marking
  
  int _selectedTabIndex = 0; // Track current tab
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: _selectedTabIndex == 0 ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: _selectedTabIndex == 0 ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0 ? AppColors.primary : Colors.grey,
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
                      color: _selectedTabIndex == 1 ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart,
                      color: _selectedTabIndex == 1 ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Table',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1 ? AppColors.primary : Colors.grey,
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
    final selectedDate = DateTime.now();
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    // Filter employees based on search query
    final filteredEmployees = employeeState.employees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return employee.name.toLowerCase().contains(query) ||
             employee.employeeCode.toLowerCase().contains(query) ||
             employee.mobileNo.toLowerCase().contains(query) ||
             employee.department.toLowerCase().contains(query) ||
             employee.position.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Header Container with Search Bar, Date, and Save Button
        Container(
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile, department, or position...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
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
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Today's Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
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
              ),
              const SizedBox(width: 12),
              // Save Attendance Button
              ElevatedButton.icon(
                onPressed: filteredEmployees.isEmpty 
                    ? null 
                    : () => _markAllSelected(filteredEmployees, selectedDate),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search Results Count (if searching)
        if (_searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Found ${filteredEmployees.length} employee(s) matching "${_searchQuery}"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Scrollable Table
        Expanded(
          child: employeeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredEmployees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No employees found'
                                : 'No matching employees',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Add employees first to mark attendance'
                                : 'Try a different search term',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: _buildBulkAttendanceTable(filteredEmployees, selectedDate),
                    ),
        ),
      ],
    );
  }

  Widget _buildBulkAttendanceTable(List<EmployeeModel> employees, DateTime date) {
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
            onChanged: alreadyMarked ? null : (value) {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            onTap: alreadyMarked ? null : () => _selectBulkTime(employee, date, true, checkIn),
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
            onTap: alreadyMarked ? null : () => _selectBulkTime(employee, date, false, checkOut),
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
                  onChanged: alreadyMarked ? null : (value) {
                    if (value != null) {
                      setState(() {
                        _bulkStatuses[employee.id] = value;
                      });
                    }
                  },
                )
              : Text(
                  '-', 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 12,
                  ),
                ),
        ),
        // OT Hours
        DataCell(
          SizedBox(
            width: 70,
            child: TextFormField(
              key: ValueKey('ot_${employee.id}'),
              initialValue: otHours.toString(),
              enabled: !alreadyMarked,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                hintText: '0',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 11,
                color: alreadyMarked ? Colors.grey : null,
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

  Future<void> _selectBulkTime(EmployeeModel employee, DateTime date, bool isCheckIn, DateTime currentTime) async {
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

  Future<void> _markAllSelected(List<EmployeeModel> employees, DateTime date) async {
    // Get all selected employees
    final selectedEmployees = employees.where((emp) {
      return _selectedEmployees[emp.id] == true;
    }).toList();

    if (selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one employee to mark'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Attendance'),
        content: Text('Save attendance for ${selectedEmployees.length} selected employee(s)?'),
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
      final checkIn = _bulkCheckInTimes[employee.id] ?? DateTime(date.year, date.month, date.day, 9, 0);
      final checkOut = _bulkCheckOutTimes[employee.id] ?? DateTime(date.year, date.month, date.day, 18, 0);
      final status = _bulkStatuses[employee.id] ?? AttendanceStatus.fullDay;
      final otHours = _bulkOvertimeHours[employee.id] ?? 0.0;

      final success = await _saveSingleAttendance(employee, date, checkIn, checkOut, status, otHours, showMessage: false);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    // Show summary message
    if (!mounted) return;
    
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked $successCount employee(s)${failCount > 0 ? ', $failCount failed' : ''}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance already marked for ${employee.name} today'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // Validate times
    if (checkOut.isBefore(checkIn)) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out time must be after check-in time'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours must be greater than 0'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Calculate work salary based on employee type
    final workSalary = SalaryCalculatorService.calculateWorkSalary(
      employee: employee,
      workingHours: workingHours,
      status: status,
    );

    // Calculate overtime salary
    final overtimeSalary = otHours > 0
        ? OvertimeService.calculateOvertimeSalary(
            overtimeHours: otHours,
            employee: employee,
          )
        : 0.0;

    // Calculate total salary
    final totalSalary = SalaryCalculatorService.calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    // Determine final status
    AttendanceStatus finalStatus = status;
    if (employee.employeeType == EmployeeType.hourly) {
      // For hourly employees, auto-determine status from hours
      if (workingHours >= 8.0) {
        finalStatus = AttendanceStatus.fullDay;
      } else if (workingHours >= 4.0) {
        finalStatus = AttendanceStatus.halfDay;
      } else {
        finalStatus = AttendanceStatus.absent;
      }
    }

    // Create attendance record
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
      overtimeHours: otHours,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked for ${employee.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      return true;
    } catch (e) {
      if (!mounted) return false;
      
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance for ${employee.name}'),
            backgroundColor: Colors.red,
          ),
        );
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
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Column(
      children: [
        // Header Container with Export and Refresh buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Export Button
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              // Refresh Button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(attendanceListProvider.notifier).loadAttendance();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        // Summary Cards - Commented out as requested
        // _buildSummaryCards(listState, employeeState),
        // Scrollable Table
        Expanded(
          child: listState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : listState.attendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mark attendance to see data in table',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildDataTable(listState.attendanceRecords, employeeState),
                    ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(AttendanceListState listState, EmployeeState employeeState) {
    final totalRecords = listState.attendanceRecords.length;
    final fullDayCount = listState.attendanceRecords
        .where((r) => r.attendanceStatus == AttendanceStatus.fullDay)
        .length;
    final halfDayCount = listState.attendanceRecords
        .where((r) => r.attendanceStatus == AttendanceStatus.halfDay)
        .length;
    final totalSalary = listState.attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.totalSalary);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Records',
            totalRecords.toString(),
            Icons.assignment,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Full Days',
            fullDayCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Half Days',
            halfDayCount.toString(),
            Icons.timelapse,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Salary',
            '₹${totalSalary.toStringAsFixed(0)}',
            Icons.currency_rupee,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildDataTable(List<AttendanceModel> records, EmployeeState employeeState) {
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
        AppColors.primary.withValues(alpha: 0.1),
      ),
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      columnSpacing: 24,
      horizontalMargin: 16,
      columns: const [
        DataColumn(
          label: Text(
            'Date',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Employee',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Code',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          label: Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Work Salary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'OT Hrs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          label: Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd/MM/yy').format(record.date))),
            DataCell(Text(record.employeeName)),
            DataCell(Text('-')),
            DataCell(Text('-')),
            DataCell(Text(DateFormat('hh:mm a').format(record.checkIn))),
            DataCell(Text(DateFormat('hh:mm a').format(record.checkOut))),
            DataCell(Text(record.workingHours.toStringAsFixed(2))),
            DataCell(Text('-')),
            DataCell(Text('₹${record.workSalary.toStringAsFixed(0)}')),
            DataCell(Text(record.overtimeHours > 0 ? record.overtimeHours.toStringAsFixed(2) : '-')),
            DataCell(Text(record.overtimeSalary > 0 ? '₹${record.overtimeSalary.toStringAsFixed(0)}' : '-')),
            DataCell(Text('₹${record.totalSalary.toStringAsFixed(0)}')),
            DataCell(Text('-')),
          ]);
        }

        // Employee is guaranteed to be non-null here
        final employee = employeeOrNull;

        return DataRow(
          cells: [
            // Date
            DataCell(
              Text(DateFormat('dd/MM/yy').format(record.date)),
            ),
            // Employee Name
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  record.employeeName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Employee Code
            DataCell(
              Text(employee.employeeCode),
            ),
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
                      employee.employeeType == EmployeeType.hourly ? 'Hour' : 'Day',
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
              Text(DateFormat('hh:mm a').format(record.checkIn)),
            ),
            // Check-out
            DataCell(
              Text(DateFormat('hh:mm a').format(record.checkOut)),
            ),
            // Working Hours
            DataCell(
              Text(
                record.workingHours.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Status
            DataCell(
              InkWell(
                onTap: () => _toggleAttendanceStatus(record, employee),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(record.attendanceStatus).withValues(alpha: 0.1),
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
              Text(
                '₹${record.workSalary.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // OT Hours
            DataCell(
              Text(
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
              Text(
                record.overtimeSalary > 0
                    ? '₹${record.overtimeSalary.toStringAsFixed(0)}'
                    : '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: record.overtimeSalary > 0 ? Colors.orange : Colors.grey,
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

  Future<void> _toggleAttendanceStatus(AttendanceModel record, EmployeeModel employee) async {
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    employee.employeeCode,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  // Check-in Time
                  Text(
                    'Check-in Time',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
                          checkInController.text = DateFormat('hh:mm a').format(editCheckIn);
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
                          const Icon(Icons.access_time, color: AppColors.primary),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
                          checkOutController.text = DateFormat('hh:mm a').format(editCheckOut);
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
                          const Icon(Icons.access_time, color: AppColors.primary),
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AttendanceStatus>(
                      initialValue: editStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: otHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    // Calculate work salary
    final workSalary = SalaryCalculatorService.calculateWorkSalary(
      employee: employee,
      workingHours: workingHours,
      status: status,
    );

    // Calculate overtime salary
    final overtimeSalary = otHours > 0
        ? OvertimeService.calculateOvertimeSalary(
            overtimeHours: otHours,
            employee: employee,
          )
        : 0.0;

    // Calculate total salary
    final totalSalary = SalaryCalculatorService.calculateTotalSalary(
      workSalary: workSalary,
      overtimeSalary: overtimeSalary,
    );

    // Determine final status
    AttendanceStatus finalStatus = status;
    if (employee.employeeType == EmployeeType.hourly) {
      if (workingHours >= 8.0) {
        finalStatus = AttendanceStatus.fullDay;
      } else if (workingHours >= 4.0) {
        finalStatus = AttendanceStatus.halfDay;
      } else {
        finalStatus = AttendanceStatus.absent;
      }
    }

    // Create updated record
    final updatedRecord = record.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
      workingHours: workingHours,
      attendanceStatus: finalStatus,
      workSalary: workSalary,
      overtimeHours: otHours,
      overtimeSalary: overtimeSalary,
      totalSalary: totalSalary,
    );

    // Save updated record
    await AttendanceService.updateAttendance(updatedRecord);
    
    // Reload attendance list
    ref.read(attendanceListProvider.notifier).loadAttendance();
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
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
              ref.read(attendanceListProvider.notifier).deleteAttendance(record.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance record deleted'),
                  backgroundColor: Colors.red,
                ),
              );
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
}
