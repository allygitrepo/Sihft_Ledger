import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import '../providers/employee_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/department_provider.dart';
import '../providers/designation_provider.dart';
import '../models/employee_model.dart';
import '../services/csv_import_service.dart';
import '../services/employee_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/csv_preview_dialog.dart';
import '../widgets/toast.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _editingEmployeeId;
  final Map<String, TextEditingController> _editControllers = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _startEditing(EmployeeModel employee) {
    setState(() {
      _editingEmployeeId = employee.id;
      _editControllers['name'] = TextEditingController(text: employee.name);
      _editControllers['code'] = TextEditingController(
        text: employee.employeeCode,
      );
      _editControllers['mobile'] = TextEditingController(
        text: employee.mobileNo,
      );
      _editControllers['position'] = TextEditingController(
        text: employee.position,
      );
      _editControllers['department'] = TextEditingController(
        text: employee.department,
      );
      _editControllers['salary'] = TextEditingController(
        text: employee.salary.toString(),
      );
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingEmployeeId = null;
      for (var controller in _editControllers.values) {
        controller.dispose();
      }
      _editControllers.clear();
    });
  }

  void _saveEditing(EmployeeModel originalEmployee) {
    final newSalary =
        double.tryParse(_editControllers['salary']!.text) ??
        originalEmployee.salary;

    // Split name in case it was edited as a single string field (if applicable)
    // Actually, in the desktop table view, it might be a single 'name' field
    final name = _editControllers['name']!.text;
    final nameParts = name.trim().split(' ');
    final firstName = nameParts[0];
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Get settings and convert salary
    final settings = ref.read(settingsProvider);
    final conversion = EmployeeService.convertSalary(newSalary, settings);

    final updatedEmployee = EmployeeModel(
      id: originalEmployee.id,
      firstName: firstName,
      lastName: lastName,
      employeeCode: _editControllers['code']!.text,
      mobileNo: _editControllers['mobile']!.text,
      position: _editControllers['position']!.text,
      department: _editControllers['department']!.text,
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
    );

    ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);
    _cancelEditing();

    ToastHelper.success('Employee updated successfully');
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Theme-adaptive colors
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    // Filter employees based on search query
    final filteredEmployees = employeeState.employees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return employee.name.toLowerCase().contains(query) ||
          employee.employeeCode.toLowerCase().contains(query) ||
          employee.mobileNo.contains(query) ||
          employee.position.toLowerCase().contains(query) ||
          employee.department.toLowerCase().contains(query);
    }).toList();

    // Desktop: Table View
    if (isDesktop) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: employeeState.employees.isEmpty
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
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Action Buttons
                            Row(
                              children: [
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
                                  label: const Text('Import CSV'),
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
                                  onPressed: () =>
                                      _downloadCSVTemplate(context),
                                  icon: const Icon(Icons.download),
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
                                  ? '${employeeState.employees.length} total employees'
                                  : 'Found ${filteredEmployees.length} of ${employeeState.employees.length} employees',
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
                    Text('Import CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Download Template'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: employeeState.employees.isEmpty
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
                          'Found ${filteredEmployees.length} of ${employeeState.employees.length} employees',
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
              'Employee ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
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
              'Position',
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
              // Employee ID
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _editControllers['code'],
                          style: const TextStyle(fontSize: 13),
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
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          employee.employeeCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ),
              // Name with Avatar
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Text(
                        employee.name[0].toUpperCase(),
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
              // Position
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _editControllers['position'],
                          style: const TextStyle(fontSize: 13),
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
              // Department
              DataCell(
                isEditing
                    ? SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _editControllers['department'],
                          style: const TextStyle(fontSize: 13),
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
                                alpha: 0.1,
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
                                alpha: 0.1,
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
                        SelectableText(
                          employee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            employee.employeeCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
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
                      if (value == 'edit') {
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

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
            const Text(
              'No Employees Found',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAddButton(context),
                  const SizedBox(width: 16),
                  _buildImportButton(context),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAddButton(context),
                  const SizedBox(height: 12),
                  _buildImportButton(context),
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

  void _showAddEmployeeForm(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final mobileController = TextEditingController();
    final salaryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final departments = ref.read(departmentProvider).departments;
    final allDesignations = ref.read(designationProvider).designations;

    String? selectedDepartmentId;
    String? selectedDesignationId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter employee ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Employee Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter employee name';
                        }
                        return null;
                      },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.length != 10) {
                          return 'Mobile number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Department Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      items: departments.map((dept) {
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
                      },
                      validator: (value) =>
                          value == null ? 'Please select a department' : null,
                    ),
                    const SizedBox(height: 16),
                    // Designation Dropdown (filtered by selected department)
                    DropdownButtonFormField<String>(
                      value: selectedDesignationId,
                      decoration: const InputDecoration(
                        labelText: 'Designation / Position',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      items: allDesignations
                          .where(
                            (d) =>
                                selectedDepartmentId == null ||
                                d.departmentId == selectedDepartmentId,
                          )
                          .map((desig) {
                            return DropdownMenuItem(
                              value: desig.id,
                              child: Text(desig.designationName),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedDesignationId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a designation' : null,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter salary';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Salary must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final dept = departments.firstWhere(
                            (d) => d.id == selectedDepartmentId,
                          );
                          final desig = allDesignations.firstWhere(
                            (d) => d.id == selectedDesignationId,
                          );
                          _addEmployeeManually(
                            context,
                            nameController.text,
                            codeController.text,
                            mobileController.text,
                            desig.designationName,
                            dept.departmentName,
                            double.parse(salaryController.text),
                            selectedDepartmentId!,
                            selectedDesignationId!,
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndImportCSV(BuildContext context) async {
    developer.log('=== CSV IMPORT STARTED ===', name: 'EmployeesScreen');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      developer.log('User cancelled file selection', name: 'EmployeesScreen');
      return;
    }

    final platformFile = result.files.single;

    // Validate file type
    if (!platformFile.name.toLowerCase().endsWith('.csv')) {
      if (!mounted) return;
      ToastHelper.error('Please select a CSV file (.csv)');
      return;
    }

    if (!mounted) return;

    // Open preview dialog immediately
    final resultData = await showDialog<List<EmployeeModel>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CsvPreviewDialog(file: platformFile),
    );

    if (resultData != null && resultData.isNotEmpty) {
      // Import employees
      await ref.read(employeeProvider.notifier).importEmployees(resultData);
    }
  }

  void _addEmployeeManually(
    BuildContext context,
    String name,
    String code,
    String mobileNo,
    String position,
    String department,
    double salary,
    String departmentId,
    String designationId,
  ) {
    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Split name into first and last name
    final nameParts = name.trim().split(' ');
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
      departmentId: int.tryParse(departmentId),
      designationId: int.tryParse(designationId),
      salary: salary,
      salaryOriginal: salary,
      salaryType: conversion['salaryType'] as String,
      hourlyRate: conversion['hourlyRate'] as double?,
      dailyRate: conversion['dailyRate'] as double?,
      createdAt: DateTime.now(),
    );

    ref.read(employeeProvider.notifier).addEmployee(employee);
    Navigator.pop(context);

    ToastHelper.success('Employee $firstName $lastName added successfully');
  }

  void _showEditEmployeeDialog(BuildContext context, EmployeeModel employee) {
    final firstNameController = TextEditingController(text: employee.firstName);
    final lastNameController = TextEditingController(text: employee.lastName);
    final codeController = TextEditingController(text: employee.employeeCode);
    final mobileController = TextEditingController(text: employee.mobileNo);
    final salaryController = TextEditingController(
      text: employee.salaryOriginal.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final departments = ref.read(departmentProvider).departments;
    final allDesignations = ref.read(designationProvider).designations;

    // Try to match existing values to dropdown entries (by name)
    String? selectedDepartmentId = departments
        .cast<dynamic>()
        .firstWhere(
          (d) => d.departmentName == employee.department,
          orElse: () => null,
        )
        ?.id;
    String? selectedDesignationId = allDesignations
        .cast<dynamic>()
        .firstWhere(
          (d) => d.designationName == employee.position,
          orElse: () => null,
        )
        ?.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Department Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.id,
                        child: Text(dept.departmentName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDepartmentId = value;
                        selectedDesignationId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a department' : null,
                  ),
                  const SizedBox(height: 12),
                  // Designation Dropdown (filtered by selected department)
                  DropdownButtonFormField<String>(
                    value: selectedDesignationId,
                    decoration: const InputDecoration(
                      labelText: 'Designation / Position',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: allDesignations
                        .where(
                          (d) =>
                              selectedDepartmentId == null ||
                              d.departmentId == selectedDepartmentId,
                        )
                        .map((desig) {
                          return DropdownMenuItem(
                            value: desig.id,
                            child: Text(desig.designationName),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDesignationId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a designation' : null,
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
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      if (double.parse(value) <= 0)
                        return 'Must be greater than 0';
                      return null;
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
                  final dept = departments.firstWhere(
                    (d) => d.id == selectedDepartmentId,
                  );
                  final desig = allDesignations.firstWhere(
                    (d) => d.id == selectedDesignationId,
                  );

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
                    employeeCode: codeController.text,
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
