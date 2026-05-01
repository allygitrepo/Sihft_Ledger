import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shiftledger/providers/auth_provider.dart';
import 'package:shiftledger/providers/company_provider.dart';
import 'package:shiftledger/services/api_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import '../providers/employee_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/department_provider.dart';
import '../providers/designation_provider.dart';
import '../providers/overtime_provider.dart';
import '../models/employee_model.dart';
import '../services/csv_import_service.dart';
import '../services/employee_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/csv_preview_dialog.dart';
import '../widgets/toast.dart';
import '../widgets/loader.dart';
import '../utills/validator.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;
  String? _editingEmployeeId;
  final Map<String, TextEditingController> _editControllers = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedEditDepartmentId;
  int? _selectedEditDesignationId;

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _startEditing(EmployeeModel employee) {
    setState(() {
      _editingEmployeeId = employee.id;
      _editControllers['name'] = TextEditingController(text: employee.name);
      _editControllers['mobile'] = TextEditingController(
        text: employee.mobileNo,
      );
      _selectedEditDepartmentId = employee.departmentId;
      _selectedEditDesignationId = employee.designationId;

      // If IDs are null, try to find them from names (fallback)
      if (_selectedEditDepartmentId == null) {
        final departments = ref.read(departmentProvider).departments;
        _selectedEditDepartmentId = departments
            .where((d) => d.departmentName.trim() == employee.department.trim())
            .firstOrNull
            ?.id;
      }

      if (_selectedEditDesignationId == null) {
        final allDesignations = ref.read(designationProvider).designations;
        _selectedEditDesignationId = allDesignations
            .where((d) => d.designationName.trim() == employee.position.trim())
            .firstOrNull
            ?.id;
      }

      // Pre-load designations for the selected department
      if (_selectedEditDepartmentId != null) {
        ref
            .read(designationProvider.notifier)
            .loadDesignations(departmentId: _selectedEditDepartmentId!);
      }

      _editControllers['salary'] = TextEditingController(
        text: employee.salaryOriginal.toString(),
      );
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingEmployeeId = null;
      _selectedEditDepartmentId = null;
      _selectedEditDesignationId = null;
      for (var controller in _editControllers.values) {
        controller.dispose();
      }
      _editControllers.clear();
    });
  }

  void _saveEditing(EmployeeModel originalEmployee) {
    // Department and Position are no longer strictly required

    final newSalary =
        double.tryParse(_editControllers['salary']!.text) ??
        originalEmployee.salaryOriginal;

    final name = _editControllers['name']!.text;
    final nameParts = name.contains(' ')
        ? name.trim().split(' ')
        : [name.trim()];
    final firstName = nameParts[0];
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final settings = ref.read(settingsProvider);
    final conversion = EmployeeService.convertSalary(newSalary, settings);

    final departments = ref.read(departmentProvider).departments;
    final designations = ref.read(designationProvider).designations;

    final deptName =
        departments
            .where((d) => d.id == _selectedEditDepartmentId)
            .firstOrNull
            ?.departmentName ??
        originalEmployee.department;

    final posName =
        designations
            .where((d) => d.id == _selectedEditDesignationId)
            .firstOrNull
            ?.designationName ??
        originalEmployee.position;

    final updatedEmployee = EmployeeModel(
      id: originalEmployee.id,
      firstName: firstName,
      lastName: lastName,
      employeeCode: originalEmployee.employeeCode,
      mobileNo: _editControllers['mobile']!.text,
      position: posName,
      department: deptName,
      departmentId: _selectedEditDepartmentId,
      designationId: _selectedEditDesignationId,
      salary: newSalary,
      salaryOriginal: newSalary,
      salaryType: conversion['salaryType'] as String,
      hourlyRate: conversion['hourlyRate'] as double?,
      dailyRate: conversion['dailyRate'] as double?,
      createdAt: originalEmployee.createdAt,
      employeeType: originalEmployee.employeeType,
      overtimeType: originalEmployee.overtimeType,
      overtimeRate: originalEmployee.overtimeRate,
      overtimeSlots: originalEmployee.overtimeSlots,
      status: originalEmployee.status,
      joinDate: originalEmployee.joinDate,
    );

    ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);
    _cancelEditing();
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    // Eagerly watch department and designation providers so they load data
    // before the user opens the Add/Edit employee dialogs.
    ref.watch(departmentProvider);
    ref.watch(designationProvider);

    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Theme-adaptive colors
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    // Use employees directly from state (already paginated and searched)
    final filteredEmployees = employeeState.employees;

    // Desktop: Table View
    if (isDesktop) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: employeeState.isLoading && employeeState.employees.isEmpty
            ? const Center(child: AppLoader())
            : employeeState.employees.isEmpty
            ? _buildEmptyState(context, isLoading: employeeState.isLoading)
            : Column(
                children: [
                  // Header with search and buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: cardColor,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Search Bar
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search employees by name, code, mobile, position, or department...',
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
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                    const Duration(milliseconds: 500),
                                    () {
                                      ref
                                          .read(employeeProvider.notifier)
                                          .loadEmployees(
                                            search: _searchQuery,
                                            page: 1,
                                          );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Action Buttons
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => ref
                                      .read(employeeProvider.notifier)
                                      .loadEmployees(),
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Refresh List',
                                  style: IconButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddEmployeeForm(context),
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Add Employee'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _pickAndImportCSV(context),
                                    icon: const Icon(Icons.upload_file, size: 20),
                                    label: const Text('Import Employees'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => _exportData(context),
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Export Employees CSV',
                                  style: IconButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () =>
                                      _downloadCSVTemplate(context),
                                  icon: const Icon(Icons.description_outlined),
                                  tooltip: 'Download CSV Template',
                                  style: IconButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(
                                      color: Colors.orange,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Results count
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? '${employeeState.totalRecords} total employees'
                                  : 'Found ${employeeState.totalRecords} employees',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Table
                  Expanded(
                    child: filteredEmployees.isEmpty
                        ? Center(
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
                          )
                        : SingleChildScrollView(
                            child: _buildDesktopTable(filteredEmployees),
                          ),
                  ),
                  if (employeeState.totalPages > 1)
                    _buildPaginationControls(employeeState),
                ],
              ),
      );
    }

    // Mobile: Card View
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(employeeProvider.notifier).loadEmployees(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _showAddEmployeeForm(context);
                  break;
                case 'import':
                  _pickAndImportCSV(context);
                  break;
                case 'export':
                  _exportData(context);
                  break;
                case 'template':
                  _downloadCSVTemplate(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 20, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Add Employee'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Import Employees'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Text('Download Template'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: employeeState.isLoading && employeeState.employees.isEmpty
          ? const Center(child: AppLoader())
          : employeeState.employees.isEmpty
          ? _buildEmptyState(context, isLoading: employeeState.isLoading)
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
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
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        ref
                            .read(employeeProvider.notifier)
                            .loadEmployees(search: _searchQuery, page: 1);
                      });
                    },
                  ),
                ),
                // Results count
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Found ${employeeState.totalRecords} employees',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Cards for mobile view
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(
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
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(horizontalPadding),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            return _buildMobileCard(filteredEmployees[index]);
                          },
                        ),
                ),
                if (employeeState.totalPages > 1)
                  _buildPaginationControls(employeeState),
              ],
            ),
    );
  }

  Widget _buildPaginationControls(EmployeeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.currentPage > 1
                ? () => ref
                      .read(employeeProvider.notifier)
                      .loadEmployees(
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
                ? () => ref
                      .read(employeeProvider.notifier)
                      .loadEmployees(
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

  Widget _buildDesktopTable(List<EmployeeModel> employees) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;

    return Container(
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
              'Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          DataColumn(
            label: Text(
              'Mobile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          DataColumn(
            label: Text(
              'Department',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          DataColumn(
            label: Text(
              'Position',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          DataColumn(
            label: Text(
              'Salary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
        rows: employees.map((employee) {
          final isEditing = _editingEmployeeId == employee.id;

          return DataRow(
            cells: [
              // Name with Avatar
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Text(
                        employee.name.isEmpty
                            ? '?'
                            : employee.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isEditing
                          ? TextFormField(
                              controller: _editControllers['name'],
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            )
                          : SelectableText(
                              employee.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // Mobile
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _editControllers['mobile'],
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          SelectableText(
                            employee.mobileNo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
              ),
              // Department
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<int>(
                          value: _selectedEditDepartmentId,
                          isExpanded: true,
                          isDense: true,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text(
                            'Select Dept',
                            style: TextStyle(fontSize: 12),
                          ),
                          items: ref
                              .watch(departmentProvider)
                              .departments
                              .where(
                                (d) =>
                                    d.status ||
                                    d.id == _selectedEditDepartmentId,
                              )
                              .map((dept) {
                                return DropdownMenuItem(
                                  value: dept.id,
                                  child: Text(
                                    dept.departmentName,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEditDepartmentId = value;
                              _selectedEditDesignationId = null;
                            });
                            if (value != null) {
                              ref
                                  .read(designationProvider.notifier)
                                  .loadDesignations(departmentId: value);
                            }
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          employee.department,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
              ),
              // Position
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<int>(
                          value: _selectedEditDesignationId,
                          isExpanded: true,
                          isDense: true,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text(
                            'Select Position',
                            style: TextStyle(fontSize: 12),
                          ),
                          items: ref
                              .watch(designationProvider)
                              .designations
                              .where(
                                (d) =>
                                    ((_selectedEditDepartmentId == null ||
                                            d.departmentId ==
                                                _selectedEditDepartmentId) &&
                                        d.status) ||
                                    d.id == _selectedEditDesignationId,
                              )
                              .map((desig) {
                                return DropdownMenuItem(
                                  value: desig.id,
                                  child: Text(
                                    desig.designationName,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEditDesignationId = value;
                            });
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          employee.position,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
              ),
              // Salary
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _editControllers['salary'],
                          style: const TextStyle(fontSize: 14),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                            prefixText: '₹',
                          ),
                        ),
                      )
                    : SelectableText(
                        '₹${employee.salary.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              // Actions
              DataCell(
                isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            color: Colors.green,
                            onPressed: () => _saveEditing(employee),
                            tooltip: 'Save',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.grey,
                            onPressed: _cancelEditing,
                            tooltip: 'Cancel',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.timer_outlined, size: 20),
                            color: AppColors.primary,
                            onPressed: () =>
                                _showOvertimeDialog(context, employee),
                            tooltip: 'Overtime',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                            onPressed: () => _startEditing(employee),
                            tooltip: 'Edit',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            onPressed: () => _confirmDelete(context, employee),
                            tooltip: 'Delete',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(EmployeeModel employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditEmployeeDialog(context, employee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: Text(
                      employee.name.isEmpty
                          ? '?'
                          : employee.name[0].toUpperCase(),
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
                          employee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'overtime',
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Overtime'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'overtime') {
                        _showOvertimeDialog(context, employee);
                      } else if (value == 'edit') {
                        _showEditEmployeeDialog(context, employee);
                      } else if (value == 'delete') {
                        _confirmDelete(context, employee);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              // Details
              _buildInfoRow(Icons.phone, 'Mobile', employee.mobileNo),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.work, 'Position', employee.position),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.business, 'Department', employee.department),
              const SizedBox(height: 12),
              // Salary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Salary',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SelectableText(
                      '₹${employee.salary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isLoading = false}) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final employeeState = ref.watch(
      employeeProvider,
    ); // Assuming employeeState is available here

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration/Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              employeeState.error ??
                  'No Employees Found', // Display error if available
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              'Add employees manually or import using CSV to start managing attendance.',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Actions
            if (isDesktop)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildAddButton(context),
                  _buildImportButton(context),
                  _buildDownloadTemplateButton(context),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAddButton(context),
                  const SizedBox(height: 12),
                  _buildImportButton(context),
                  const SizedBox(height: 12),
                  _buildDownloadTemplateButton(context),
                ],
              ),
            if (isLoading) ...[
              const SizedBox(height: 32),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAddEmployeeForm(context),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add Employee'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pickAndImportCSV(context),
      icon: const Icon(Icons.upload_file_outlined, size: 20),
      label: const Text('Import CSV'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDownloadTemplateButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _downloadCSVTemplate(context),
      icon: const Icon(Icons.download, size: 20),
      label: const Text('Template CSV'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddEmployeeForm(BuildContext context) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final salaryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    int? selectedDepartmentId;
    int? selectedDesignationId;
    DateTime selectedJoinDate = DateTime.now();
    bool isStatusActive = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Consumer(
          builder: (context, ref, child) {
            final departments = ref.watch(departmentProvider).departments;
            final allDesignations = ref.watch(designationProvider).designations;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Add New Employee',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Employee Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              AppValidator.validateName(value, 'Employee Name'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: mobileController,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              AppValidator.validatePhoneNumber(
                                value,
                                'Mobile Number',
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Department Dropdown
                        DropdownButtonFormField<int>(
                          value: selectedDepartmentId,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                            helperText: 'Select department first',
                          ),
                          items: departments.where((d) => d.status).map((dept) {
                            return DropdownMenuItem(
                              value: dept.id,
                              child: Text(dept.departmentName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedDepartmentId = value;
                              selectedDesignationId = null; // reset designation
                            });
                            if (value != null) {
                              ref
                                  .read(designationProvider.notifier)
                                  .loadDesignations(departmentId: value);
                            }
                          },
                          // validator removed
                        ),
                        const SizedBox(height: 16),
                        // Designation Dropdown (filtered by selected department)
                        DropdownButtonFormField<int>(
                          value: selectedDesignationId,
                          decoration: InputDecoration(
                            labelText: 'Designation / Position',
                            prefixIcon: Icon(Icons.work),
                            border: const OutlineInputBorder(),
                            helperText: selectedDepartmentId == null
                                ? 'Select department first to enable'
                                : 'Select designation for the department',
                            helperStyle: TextStyle(
                              color: selectedDepartmentId == null
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            enabled: selectedDepartmentId != null,
                          ),
                          items: selectedDepartmentId == null
                              ? []
                              : allDesignations
                                    .where(
                                      (d) =>
                                          d.departmentId ==
                                              selectedDepartmentId &&
                                          d.status,
                                    )
                                    .map((desig) {
                                      return DropdownMenuItem(
                                        value: desig.id,
                                        child: Text(desig.designationName),
                                      );
                                    })
                                    .toList(),
                          onChanged: selectedDepartmentId == null
                              ? null
                              : (value) {
                                  setModalState(() {
                                    selectedDesignationId = value;
                                  });
                                },
                          // validator removed
                          disabledHint: Text(
                            'Select department first',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: salaryController,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Salary',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                            helperText: 'Enter monthly salary amount',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: AppValidator.validateSalary,
                        ),
                        const SizedBox(height: 16),
                        // Join Date Selection
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Join Date: ${DateFormat('dd MMM yyyy').format(selectedJoinDate)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedJoinDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedJoinDate = picked;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Is Active'),
                          activeColor: AppColors.primary,
                          value: isStatusActive,
                          onChanged: (value) {
                            setModalState(() {
                              isStatusActive = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final dept = departments.firstWhereOrNull(
                                (d) => d.id == selectedDepartmentId,
                              );
                              final desig = allDesignations.firstWhereOrNull(
                                (d) => d.id == selectedDesignationId,
                              );

                              _addEmployeeManually(
                                context,
                                nameController.text,
                                mobileController.text,
                                desig?.designationName ?? '',
                                dept?.departmentName ?? '',
                                double.tryParse(salaryController.text) ?? 0,
                                selectedDepartmentId,
                                selectedDesignationId,
                                isStatusActive,
                                selectedJoinDate,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Add Employee'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    try {
      final response = await ApiService.exportEmployeesCSV(
        companyId.toString(),
        token,
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName =
            'employees_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

        if (kIsWeb) {
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: bytes,
            ext: 'csv',
            mimeType: MimeType.csv,
          );
        } else {
          await FileSaver.instance.saveAs(
            name: fileName,
            bytes: bytes,
            ext: 'csv',
            mimeType: MimeType.csv,
          );
        }
        ToastHelper.success('Data exported successfully');
      } else {
        ToastHelper.error('Export failed: ${response.statusCode}');
      }
    } catch (e) {
      ToastHelper.error('Export error: $e');
    }
  }

  Future<void> _pickAndImportCSV(BuildContext context) async {
    developer.log('=== DATA IMPORT STARTED ===', name: 'EmployeesScreen');
 
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final platformFile = result.files.single;

    if (platformFile.bytes == null) {
      ToastHelper.error('Could not read file data');
      return;
    }

    // Restore preview dialog
    if (!context.mounted) return;
    
    final List<EmployeeModel>? resultData = await showDialog<List<EmployeeModel>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CsvPreviewDialog(file: platformFile),
    );

    if (resultData == null || resultData.isEmpty) return;

    // Send the edited list to backend for robust processing (creating depts/desigs etc.)
    await ref.read(employeeProvider.notifier).importData(resultData);
  }

  void _addEmployeeManually(
    BuildContext context,
    String name,
    String mobileNo,
    String position,
    String department,
    double salary,
    int? departmentId,
    int? designationId,
    bool status,
    DateTime joinDate,
  ) {
    final code = 'EMP${DateTime.now().millisecondsSinceEpoch % 10000}';
    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Split name into first and last name
    final nameParts = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    if (nameParts.isEmpty) {
      ToastHelper.error('Please enter a valid name');
      return;
    }
    final firstName = nameParts[0];
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Get settings and convert salary
    final settings = ref.read(settingsProvider);
    final conversion = EmployeeService.convertSalary(salary, settings);

    final employee = EmployeeModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      employeeCode: code,
      mobileNo: mobileNo,
      position: position,
      department: department,
      departmentId: departmentId,
      designationId: designationId,
      salary: salary,
      salaryOriginal: salary,
      salaryType: conversion['salaryType'] as String,
      hourlyRate: conversion['hourlyRate'] as double?,
      dailyRate: conversion['dailyRate'] as double?,
      createdAt: DateTime.now(),
      status: status,
      joinDate: joinDate,
    );

    ref.read(employeeProvider.notifier).addEmployee(employee);
    Navigator.pop(context);

    ToastHelper.success('Employee $firstName $lastName added successfully');
  }

  void _showEditEmployeeDialog(BuildContext context, EmployeeModel employee) {
    if (employee.departmentId != null) {
      ref
          .read(designationProvider.notifier)
          .loadDesignations(departmentId: employee.departmentId);
    }

    final firstNameController = TextEditingController(text: employee.firstName);
    final lastNameController = TextEditingController(text: employee.lastName);
    final mobileController = TextEditingController(text: employee.mobileNo);
    final salaryController = TextEditingController(
      text: employee.salaryOriginal.toString(),
    );
    final formKey = GlobalKey<FormState>();

    bool isStatusActive = employee.status;
    DateTime? selectedJoinDate = employee.joinDate;

    final departments = ref.read(departmentProvider).departments;

    // Direct ID matching
    int? selectedDepartmentId = employee.departmentId;
    int? selectedDesignationId = employee.designationId;

    // Fallback if IDs are null but names exist
    if (selectedDepartmentId == null) {
      selectedDepartmentId = departments
          .firstWhereOrNull(
            (d) => d.departmentName.trim() == employee.department.trim(),
          )
          ?.id;
    }

    if (selectedDesignationId == null) {
      final allDesignations = ref.read(designationProvider).designations;
      selectedDesignationId = allDesignations
          .firstWhereOrNull(
            (d) => d.designationName.trim() == employee.position.trim(),
          )
          ?.id;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer(
          builder: (context, ref, child) {
            final departments = ref.watch(departmentProvider).departments;
            final allDesignations = ref.watch(designationProvider).designations;

            return AlertDialog(
              title: const Text('Edit Employee'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            AppValidator.validateName(value, 'First Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            AppValidator.validateName(value, 'Last Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) => AppValidator.validatePhoneNumber(
                          value,
                          'Mobile Number',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Department Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                          helperText: 'Select department first',
                        ),
                        items: departments
                            .where(
                              (d) => d.status || d.id == selectedDepartmentId,
                            )
                            .map((dept) {
                              return DropdownMenuItem(
                                value: dept.id,
                                child: Text(dept.departmentName),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDepartmentId = value;
                            selectedDesignationId = null;
                          });
                          if (value != null) {
                            ref
                                .read(designationProvider.notifier)
                                .loadDesignations(departmentId: value);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                      ),
                      const SizedBox(height: 12),
                      // Designation Dropdown (filtered by selected department)
                      DropdownButtonFormField<int>(
                        value: selectedDesignationId,
                        decoration: InputDecoration(
                          labelText: 'Designation / Position',
                          prefixIcon: const Icon(Icons.work),
                          border: const OutlineInputBorder(),
                          helperText: selectedDepartmentId == null
                              ? 'Select department first to enable'
                              : 'Select designation for the department',
                          helperStyle: TextStyle(
                            color: selectedDepartmentId == null
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          enabled: selectedDepartmentId != null,
                        ),
                        items: selectedDepartmentId == null
                            ? []
                            : allDesignations
                                  .where(
                                    (d) =>
                                        d.departmentId ==
                                            selectedDepartmentId &&
                                        (d.status ||
                                            d.id == selectedDesignationId),
                                  )
                                  .map((desig) {
                                    return DropdownMenuItem(
                                      value: desig.id,
                                      child: Text(desig.designationName),
                                    );
                                  })
                                  .toList(),
                        onChanged: selectedDepartmentId == null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedDesignationId = value;
                                });
                              },
                        validator: (value) => value == null
                            ? 'Please select a designation'
                            : null,
                        disabledHint: Text(
                          'Select department first',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: salaryController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Salary',
                          border: OutlineInputBorder(),
                          helperText: 'Enter monthly salary amount',
                        ),
                        keyboardType: TextInputType.number,
                        validator: AppValidator.validateSalary,
                      ),
                      const SizedBox(height: 12),
                      // Join Date Selection
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          selectedJoinDate == null
                              ? 'Select Join Date'
                              : 'Join Date: ${DateFormat('dd MMM yyyy').format(selectedJoinDate!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedJoinDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedJoinDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Is Active'),
                        activeColor: AppColors.primary,
                        value: isStatusActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isStatusActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newSalary = double.parse(salaryController.text);
                      final dept = departments.firstWhereOrNull(
                        (d) => d.id == selectedDepartmentId,
                      );
                      final desig = allDesignations.firstWhereOrNull(
                        (d) => d.id == selectedDesignationId,
                      );

                      if (dept == null || desig == null) {
                        ToastHelper.error('Department or Position not found');
                        return;
                      }

                      // Get settings and convert salary
                      final settings = ref.read(settingsProvider);
                      final conversion = EmployeeService.convertSalary(
                        newSalary,
                        settings,
                      );

                      final updatedEmployee = EmployeeModel(
                        id: employee.id,
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        employeeCode: employee.employeeCode,
                        mobileNo: mobileController.text,
                        position: desig.designationName,
                        department: dept.departmentName,
                        salary: newSalary,
                        salaryOriginal: newSalary,
                        salaryType: conversion['salaryType'] as String,
                        hourlyRate: conversion['hourlyRate'] as double?,
                        dailyRate: conversion['dailyRate'] as double?,
                        createdAt: employee.createdAt,
                        employeeType: employee.employeeType,
                        overtimeType: employee.overtimeType,
                        overtimeRate: employee.overtimeRate,
                        overtimeSlots: employee.overtimeSlots,
                        status: isStatusActive,
                        joinDate: selectedJoinDate,
                      );

                      ref
                          .read(employeeProvider.notifier)
                          .updateEmployee(updatedEmployee);
                      Navigator.pop(context);

                      ToastHelper.success('Employee updated successfully');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(employeeProvider.notifier).deleteEmployee(employee.id);
              Navigator.pop(context);

              ToastHelper.error('${employee.name} deleted successfully');
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

  void _showOvertimeDialog(
    // Changed from Future<void> ... async
    BuildContext context,
    EmployeeModel employee,
  ) {
    // Changed from async {
    // Initial values from employee model
    bool overtimeEnabled = employee.overtimeType != OvertimeType.none;

    // Fetch settings to get org-level default overtime rate
    final settings = ref.read(settingsProvider);
    final settingsLoaded = ref.read(settingsLoadedProvider);

    // Use employee's own stored rate if > 0, otherwise fall back to org setting
    final initialRate = employee.overtimeRate > 0
        ? employee.overtimeRate
        : settings.defaultOvertimeRate;
    final rateController = TextEditingController(text: initialRate.toString());

    // Check if we have a server-loaded config for this specific employee
    final overtimeState = ref.read(overtimeProvider);
    final serverConfig = overtimeState.employeeConfigs[employee.id];

    if (serverConfig != null) {
      overtimeEnabled = serverConfig.overtimeEnabled;
      // Use server config rate if set, otherwise fall back to org setting
      final serverRate = serverConfig.hourlyRate > 0
          ? serverConfig.hourlyRate
          : settings.defaultOvertimeRate;
      rateController.text = serverRate.toString();
    } else {
      // Proactively load it in background so next open is faster
      Future.microtask(() {
        ref.read(overtimeProvider.notifier).loadEmployeeConfig(employee.id);
      });
    }

    // if (!context.mounted) return; // This line was removed as it was part of the async flow

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Overtime: ${employee.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure specific overtime settings for this employee. This will override global defaults.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      if (!settingsLoaded)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loading organization settings...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (settingsLoaded && settings.defaultOvertimeRate == 0.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No default overtime rate configured for this organization.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Enable Overtime'),
                      subtitle: Text(overtimeEnabled ? 'Enabled' : 'Disabled'),
                      value: overtimeEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setDialogState(() => overtimeEnabled = value);
                      },
                    ),
                  ),
                  if (overtimeEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Hourly Overtime Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rateController,
                      decoration: const InputDecoration(
                        hintText: 'Enter rate per hour',
                        prefixIcon: Icon(Icons.currency_rupee, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final rate = double.tryParse(rateController.text) ?? 0.0;
                  final success = await ref
                      .read(overtimeProvider.notifier)
                      .saveEmployeeConfig(
                        employeeId: employee.id,
                        overtimeEnabled: overtimeEnabled,
                        hourlyRate: rate,
                      );

                  if (success) {
                    ToastHelper.success('Configuration saved');
                    if (context.mounted) Navigator.pop(context);

                    // Also update the employee in the main list to reflect change immediately
                    final updatedEmployee = employee.copyWith(
                      overtimeType: overtimeEnabled
                          ? OvertimeType.hourwise
                          : OvertimeType.none,
                      overtimeRate: rate,
                    );
                    ref
                        .read(employeeProvider.notifier)
                        .updateEmployeeInList(updatedEmployee);
                  } else {
                    ToastHelper.error('Failed to save configuration');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadCSVTemplate(BuildContext context) async {
    final navigator = Navigator.of(context);

    try {
      final template = CsvImportService.generateSampleCSV();
      final Uint8List bytes = Uint8List.fromList(utf8.encode(template));
      const fileName = 'employee_template';

      developer.log(
        'Downloading CSV Template - Web: $kIsWeb',
        name: 'EmployeesScreen',
      );

      // Use FileSaver for robust cross-platform saving
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      ToastHelper.success('CSV template download started!');
    } catch (e) {
      developer.log('Error downloading template: $e', name: 'EmployeesScreen');

      // Fallback: Show the template in a dialog for manual copy
      if (!mounted) return;
      _showTemplateDialog(navigator.context);
    }
  }

  void _showTemplateDialog(BuildContext context) {
    final template = CsvImportService.generateSampleCSV();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.description, color: AppColors.primary),
            SizedBox(width: 12),
            Text('CSV Template'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '📋 Copy this template and save as .csv file',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  template,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Copy the above text\n'
                      '2. Open Excel or Google Sheets\n'
                      '3. Paste the content\n'
                      '4. Add your employee data\n'
                      '5. Save as CSV file (.csv)\n'
                      '6. Import using "Import CSV" button',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadCSVTemplate(context);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Try Download Again'),
          ),
        ],
      ),
    );
  }
}
