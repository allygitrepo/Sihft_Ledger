import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/employee_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../models/employee_model.dart';
import '../services/csv_import_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeState = ref.watch(employeeProvider);
    final settings = ref.watch(settingsProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            employee.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(employee.name),
                        subtitle: Text('Code: ${employee.employeeCode}'),
                        trailing: Text(
                          _getRateText(employee, settings.attendanceType),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployeeOptions(context, ref, settings),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            'Import employees using CSV file',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  String _getRateText(EmployeeModel employee, AttendanceType attendanceType) {
    switch (attendanceType) {
      case AttendanceType.daily:
        return '₹${employee.baseSalary?.toStringAsFixed(0) ?? '0'}/day';
      case AttendanceType.hourly:
        return '₹${employee.hourlyRate?.toStringAsFixed(0) ?? '0'}/hr';
      case AttendanceType.unit:
        return '₹${employee.perUnitRate?.toStringAsFixed(0) ?? '0'}/unit';
    }
  }

  void _showAddEmployeeOptions(BuildContext context, WidgetRef ref, SettingsModel settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Employee',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add, color: AppColors.primary),
              ),
              title: const Text('Add Manually'),
              subtitle: const Text('Fill form to add single employee'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showAddEmployeeForm(context, ref, settings);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file, color: Colors.green),
              ),
              title: const Text('Import from CSV'),
              subtitle: const Text('Upload CSV file with multiple employees'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog(context, ref, settings);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download, color: Colors.orange),
              ),
              title: const Text('Download CSV Template'),
              subtitle: const Text('Get sample CSV format'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _downloadCSVTemplate(context, settings);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddEmployeeForm(BuildContext context, WidgetRef ref, SettingsModel settings) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final rateController = TextEditingController();
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
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Code',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter employee code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: rateController,
                  decoration: InputDecoration(
                    labelText: _getRateColumnName(settings.attendanceType),
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter rate';
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
                        ref,
                        settings,
                        nameController.text,
                        codeController.text,
                        double.parse(rateController.text),
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
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref, SettingsModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.upload_file, color: Colors.blue),
            SizedBox(width: 12),
            Text('Import Employees from CSV'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import multiple employees at once using a CSV file.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Required CSV Format:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Name, Employee Code, ${_getRateColumnName(settings.attendanceType)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Important Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('File must be in CSV format (.csv)'),
              _buildBulletPoint('First row must be headers'),
              _buildBulletPoint('Each row = one employee'),
              _buildBulletPoint('All fields are required'),
              _buildBulletPoint('Rate must be a number'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lightbulb, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Download the template first to see the correct format!',
                        style: TextStyle(fontSize: 12),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadCSVTemplate(context, settings);
            },
            child: const Text('Download Template'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickAndImportCSV(context, ref, settings);
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('Select CSV File'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getRateColumnName(AttendanceType attendanceType) {
    switch (attendanceType) {
      case AttendanceType.daily:
        return 'Base Salary';
      case AttendanceType.hourly:
        return 'Hourly Rate';
      case AttendanceType.unit:
        return 'Per Unit Rate';
    }
  }

  Future<void> _pickAndImportCSV(
    BuildContext context,
    WidgetRef ref,
    SettingsModel settings,
  ) async {
    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled - no message needed
        return;
      }

      final platformFile = result.files.single;

      // Check if we have a valid path or bytes
      if (platformFile.path == null && platformFile.bytes == null) {
        if (context.mounted) {
          _showErrorDialog(
            context,
            'File Error',
            'Unable to read the selected file. Please try again.',
          );
        }
        return;
      }

      // Show processing snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Processing CSV file...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Read file content - handle both path and bytes
      String content;
      if (platformFile.path != null) {
        final file = File(platformFile.path!);
        content = await file.readAsString();
      } else if (platformFile.bytes != null) {
        content = String.fromCharCodes(platformFile.bytes!);
      } else {
        throw Exception('Unable to read file content');
      }

      // Validate CSV format
      if (!CsvImportService.validateCSVFormat(content)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showErrorDialog(
            context,
            'Invalid CSV Format',
            'The CSV file must have headers: Name, Employee Code, and Rate column.\n\nPlease download the template and use the correct format.',
          );
        }
        return;
      }

      // Parse CSV with timeout protection
      List<EmployeeModel> employees;
      try {
        employees = await CsvImportService.parseCSV(
          content,
          settings.attendanceType,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('CSV parsing timed out. The file might be too large or corrupted.');
          },
        );
      } catch (parseError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showErrorDialog(
            context,
            'Parsing Error',
            parseError.toString(),
          );
        }
        return;
      }

      if (employees.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showErrorDialog(
            context,
            'No Data Found',
            'The CSV file contains no employee data.\n\nPlease add employee records and try again.',
          );
        }
        return;
      }

      // Import employees
      await ref.read(employeeProvider.notifier).importEmployees(employees);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
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
                  '${employees.length} employees imported successfully!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Imported employees:'),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: employees.map((emp) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${emp.name} (${emp.employeeCode})',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showErrorDialog(
          context,
          'Import Failed',
          'Error: ${e.toString()}\n\nPlease check your CSV file format and try again.',
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addEmployeeManually(
    BuildContext context,
    WidgetRef ref,
    SettingsModel settings,
    String name,
    String code,
    double rate,
  ) {
    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    EmployeeModel employee;

    switch (settings.attendanceType) {
      case AttendanceType.daily:
        employee = EmployeeModel(
          id: id,
          name: name,
          employeeCode: code,
          baseSalary: rate,
          createdAt: DateTime.now(),
        );
        break;
      case AttendanceType.hourly:
        employee = EmployeeModel(
          id: id,
          name: name,
          employeeCode: code,
          hourlyRate: rate,
          createdAt: DateTime.now(),
        );
        break;
      case AttendanceType.unit:
        employee = EmployeeModel(
          id: id,
          name: name,
          employeeCode: code,
          perUnitRate: rate,
          createdAt: DateTime.now(),
        );
        break;
    }

    ref.read(employeeProvider.notifier).addEmployee(employee);
    Navigator.pop(context);
  }

  void _downloadCSVTemplate(BuildContext context, SettingsModel settings) {
    final template = CsvImportService.generateSampleCSV(settings.attendanceType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this template and save as .csv file:',
                style: TextStyle(fontWeight: FontWeight.bold),
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
              Text(
                'Instructions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Copy the above text\n'
                '2. Open Excel or Google Sheets\n'
                '3. Paste the content\n'
                '4. Add your employee data\n'
                '5. Save as CSV file\n'
                '6. Import using "Import from CSV" option',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
        ],
      ),
    );
  }
}
