import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../providers/employee_provider.dart';
import '../models/employee_model.dart';
import '../models/csv_employee_preview.dart';
import '../services/csv_import_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/csv_preview_dialog.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _editingEmployeeId;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startEditing(EmployeeModel employee) {
    setState(() {
      _editingEmployeeId = employee.id;
      _editControllers['name'] = TextEditingController(text: employee.name);
      _editControllers['code'] = TextEditingController(text: employee.employeeCode);
      _editControllers['mobile'] = TextEditingController(text: employee.mobileNo);
      _editControllers['position'] = TextEditingController(text: employee.position);
      _editControllers['department'] = TextEditingController(text: employee.department);
      _editControllers['salary'] = TextEditingController(text: employee.salary.toString());
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
    final updatedEmployee = EmployeeModel(
      id: originalEmployee.id,
      name: _editControllers['name']!.text,
      employeeCode: _editControllers['code']!.text,
      mobileNo: _editControllers['mobile']!.text,
      position: _editControllers['position']!.text,
      department: _editControllers['department']!.text,
      salary: double.tryParse(_editControllers['salary']!.text) ?? originalEmployee.salary,
      createdAt: originalEmployee.createdAt,
    );
    
    ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);
    _cancelEditing();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
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
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    // Desktop: Table View
    if (isDesktop) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: employeeState.isLoading
            ? const Center(child: AppLoader(size: 50))
            : employeeState.employees.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      // Header with title and add button
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: cardColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: AppColors.primary, size: 28),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Employees',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '${employeeState.employees.length} total employees',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEmployeeForm(context),
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
                                  onPressed: () => _downloadCSVTemplate(context),
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Download CSV Template',
                                  style: IconButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
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
                      ),
                      // Table
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildDesktopTable(employeeState.employees),
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEmployeeForm(context),
          ),
        ],
      ),
      body: employeeState.isLoading
          ? const Center(child: AppLoader(size: 50))
          : employeeState.employees.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: EdgeInsets.all(horizontalPadding),
                  itemCount: employeeState.employees.length,
                  itemBuilder: (context, index) {
                    final employee = employeeState.employees[index];
                    return _buildMobileCard(employee);
                  },
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Mobile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Position',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Department',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Salary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                            )
                          : Text(
                              employee.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            prefixText: '₹',
                          ),
                        ),
                      )
                    : Text(
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
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
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
                              backgroundColor: Colors.grey.withValues(alpha: 0.1),
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
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
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
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                        Text(
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
                    Text(
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
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No employees yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add employees manually or import from CSV',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddEmployeeForm(context),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Add Employee'),
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
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickAndImportCSV(context),
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text('Import CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
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
          const SizedBox(height: 16),
          // Download Template Link
          TextButton.icon(
            onPressed: () => _downloadCSVTemplate(context),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download CSV Template'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeForm(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final mobileController = TextEditingController();
    final positionController = TextEditingController();
    final departmentController = TextEditingController();
    final salaryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
                  TextFormField(
                    controller: positionController,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter position';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter department';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salary',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter salary';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _addEmployeeManually(
                          context,
                          nameController.text,
                          codeController.text,
                          mobileController.text,
                          positionController.text,
                          departmentController.text,
                          double.parse(salaryController.text),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
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
    );
  }

  Future<void> _pickAndImportCSV(BuildContext context) async {
    developer.log('=== CSV IMPORT STARTED ===', name: 'EmployeesScreen');
    
    // Store navigator and scaffold messenger before any async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      developer.log('Opening file picker...', name: 'EmployeesScreen');
      
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
      developer.log('File selected: ${platformFile.name}', name: 'EmployeesScreen');
      developer.log('File size: ${platformFile.size} bytes', name: 'EmployeesScreen');
      developer.log('Has bytes: ${platformFile.bytes != null}', name: 'EmployeesScreen');

      // Validate file type
      if (!platformFile.name.toLowerCase().endsWith('.csv')) {
        developer.log('ERROR: File is not a CSV file: ${platformFile.name}', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Please select a CSV file (.csv), not ${platformFile.name.split('.').last}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Validate file data
      if (platformFile.bytes == null && platformFile.path == null) {
        developer.log('ERROR: No bytes or path available', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to read the selected file. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading snackbar instead of dialog
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Processing ${platformFile.name}...'),
              ),
            ],
          ),
          duration: const Duration(minutes: 1),
        ),
      );

      // Read file content
      String content;
      if (platformFile.bytes != null) {
        developer.log('Reading file from bytes...', name: 'EmployeesScreen');
        content = String.fromCharCodes(platformFile.bytes!);
      } else if (platformFile.path != null) {
        developer.log('Reading file from path...', name: 'EmployeesScreen');
        final file = File(platformFile.path!);
        content = await file.readAsString();
      } else {
        throw Exception('Unable to read file content');
      }

      developer.log('Content length: ${content.length} characters', name: 'EmployeesScreen');

      // Validate CSV format
      if (!CsvImportService.validateCSVFormat(content)) {
        developer.log('CSV validation failed', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Invalid CSV format. Please download the template and use the correct format.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Parse CSV
      developer.log('Parsing CSV...', name: 'EmployeesScreen');
      final previews = await CsvImportService.parseCSV(content);
      developer.log('Parsed ${previews.length} employees', name: 'EmployeesScreen');

      if (previews.isEmpty) {
        developer.log('No employees found in CSV', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No employee data found in CSV file.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Convert previews to employees with default values
      final previewList = previews;

      // Check for duplicates
      final existingEmployees = ref.read(employeeProvider).employees;
      
      // Separate new and duplicate previews
      final newPreviews = <CsvEmployeePreview>[];
      final duplicatePreviews = <CsvEmployeePreview>[];
      
      for (final preview in previewList) {
        final isDuplicate = existingEmployees.any(
          (e) => e.employeeCode.toLowerCase() == preview.employeeCode.toLowerCase(),
        );
        if (isDuplicate) {
          duplicatePreviews.add(preview);
        } else {
          newPreviews.add(preview);
        }
      }
      
      developer.log('Found ${newPreviews.length} new, ${duplicatePreviews.length} duplicates', name: 'EmployeesScreen');

      // Hide loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      // Check if there are new employees to import
      if (newPreviews.isEmpty) {
        developer.log('No new employees to import', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('All ${previewList.length} employees already exist in the system.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show preview dialog - use a new context from navigator
      if (!mounted) return;
      final shouldImport = await showDialog<bool>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (dialogContext) => CsvPreviewDialog(
          previews: newPreviews,
          duplicates: duplicatePreviews,
        ),
      );

      if (shouldImport != true) {
        developer.log('Import cancelled by user', name: 'EmployeesScreen');
        return;
      }

      // Convert previews to employees
      final employees = newPreviews.map((preview) => preview.toEmployeeModel()).toList();

      // Show importing snackbar
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text('Importing ${employees.length} employees...'),
            ],
          ),
          duration: const Duration(minutes: 1),
        ),
      );

      // Import employees
      developer.log('Importing ${employees.length} employees...', name: 'EmployeesScreen');
      await ref.read(employeeProvider.notifier).importEmployees(employees);
      developer.log('Import completed successfully', name: 'EmployeesScreen');

      // Hide importing snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      // Show success dialog
      if (!mounted) return;
      await showDialog(
        context: navigator.context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Import Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ ${employees.length} employees imported successfully!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (duplicatePreviews.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '⏭️  ${duplicatePreviews.length} duplicates were skipped',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e, stackTrace) {
      developer.log('Import failed: $e', name: 'EmployeesScreen');
      developer.log('Stack trace: $stackTrace', name: 'EmployeesScreen');
      
      if (!mounted) return;
      
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
  ) {
    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    final employee = EmployeeModel(
      id: id,
      name: name,
      employeeCode: code,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      createdAt: DateTime.now(),
    );

    ref.read(employeeProvider.notifier).addEmployee(employee);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Employee $name added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, EmployeeModel employee) {
    final nameController = TextEditingController(text: employee.name);
    final codeController = TextEditingController(text: employee.employeeCode);
    final mobileController = TextEditingController(text: employee.mobileNo);
    final positionController = TextEditingController(text: employee.position);
    final departmentController = TextEditingController(text: employee.department);
    final salaryController = TextEditingController(text: employee.salary.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Employee'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) return 'Invalid number';
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
                final updatedEmployee = EmployeeModel(
                  id: employee.id,
                  name: nameController.text,
                  employeeCode: codeController.text,
                  mobileNo: mobileController.text,
                  position: positionController.text,
                  department: departmentController.text,
                  salary: double.parse(salaryController.text),
                  createdAt: employee.createdAt,
                );
                
                ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Employee updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
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
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${employee.name} deleted successfully'),
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

  Future<void> _downloadCSVTemplate(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final template = CsvImportService.generateSampleCSV();
      
      // Use FilePicker to let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'employee_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // Write the file
        final file = File(result);
        await file.writeAsString(template);
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('CSV template saved successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // User cancelled the save dialog
        developer.log('User cancelled template download', name: 'EmployeesScreen');
      }
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
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
