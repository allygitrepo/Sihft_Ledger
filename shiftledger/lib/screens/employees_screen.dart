import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../providers/employee_provider.dart';
import '../models/employee_model.dart';
import '../services/csv_import_service.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Desktop: No AppBar, MainLayout provides it
    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${employee.employeeCode}'),
                              Text('${employee.position} • ${employee.department}'),
                              Text('Mobile: ${employee.mobileNo}', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${employee.salary.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue,
                                onPressed: () => _showEditEmployeeDialog(context, employee),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: Colors.red,
                                onPressed: () => _confirmDelete(context, employee),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEmployeeOptions(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    // Mobile: Keep existing Scaffold with AppBar
    return Scaffold(
      key: _scaffoldKey,
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${employee.employeeCode}'),
                            Text('${employee.position} • ${employee.department}'),
                            Text('Mobile: ${employee.mobileNo}', 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${employee.salary.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
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
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployeeOptions(context),
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
            'Add employees manually or import from CSV',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeOptions(BuildContext context) {
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
                _showAddEmployeeForm(context);
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
                _showImportDialog(context);
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
                _downloadCSVTemplate(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
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

  void _showImportDialog(BuildContext context) {
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
                      child: const Text(
                        'Employee ID, Employee Name, Employee Mobile No, Employee Position, Employee Department, Employee Salary',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
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
              _buildBulletPoint('Salary must be a number'),
              _buildBulletPoint('Mobile number should be 10 digits'),
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
              _downloadCSVTemplate(context);
            },
            child: const Text('Download Template'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickAndImportCSV(context);
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
      final employees = await CsvImportService.parseCSV(content);
      developer.log('Parsed ${employees.length} employees', name: 'EmployeesScreen');

      if (employees.isEmpty) {
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

      // Check for duplicates
      final existingEmployees = ref.read(employeeProvider).employees;
      final duplicateCheck = _checkForDuplicates(employees, existingEmployees);
      
      developer.log('Found ${duplicateCheck.newEmployees.length} new, ${duplicateCheck.duplicates.length} duplicates', name: 'EmployeesScreen');

      // Hide loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      // Check if there are new employees to import
      if (duplicateCheck.newEmployees.isEmpty) {
        developer.log('No new employees to import', name: 'EmployeesScreen');
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('All ${employees.length} employees already exist in the system.'),
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
        builder: (dialogContext) => _buildPreviewDialog(dialogContext, employees, duplicateCheck),
      );

      if (shouldImport != true) {
        developer.log('Import cancelled by user', name: 'EmployeesScreen');
        return;
      }

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
              Text('Importing ${duplicateCheck.newEmployees.length} employees...'),
            ],
          ),
          duration: const Duration(minutes: 1),
        ),
      );

      // Import employees
      developer.log('Importing ${duplicateCheck.newEmployees.length} employees...', name: 'EmployeesScreen');
      await ref.read(employeeProvider.notifier).importEmployees(duplicateCheck.newEmployees);
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
                '✅ ${duplicateCheck.newEmployees.length} employees imported successfully!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (duplicateCheck.duplicates.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '⏭️  ${duplicateCheck.duplicates.length} duplicates were skipped',
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

  void _downloadCSVTemplate(BuildContext context) {
    final template = CsvImportService.generateSampleCSV();
    
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

  DuplicateCheckResult _checkForDuplicates(
    List<EmployeeModel> newEmployees,
    List<EmployeeModel> existingEmployees,
  ) {
    developer.log('=== DUPLICATE CHECK START ===', name: 'EmployeesScreen');
    developer.log('New employees to check: ${newEmployees.length}', name: 'EmployeesScreen');
    developer.log('Existing employees: ${existingEmployees.length}', name: 'EmployeesScreen');
    
    final duplicates = <EmployeeModel>[];
    final newOnes = <EmployeeModel>[];
    
    // Create a map of existing employees by employee code (case-insensitive)
    final existingMap = <String, EmployeeModel>{};
    for (final emp in existingEmployees) {
      existingMap[emp.employeeCode.toLowerCase()] = emp;
      developer.log('Existing employee code: ${emp.employeeCode}', name: 'EmployeesScreen');
    }
    
    // Check each new employee
    for (final newEmp in newEmployees) {
      final code = newEmp.employeeCode.toLowerCase();
      developer.log('Checking new employee: ${newEmp.name} (${newEmp.employeeCode})', name: 'EmployeesScreen');
      
      if (existingMap.containsKey(code)) {
        developer.log('  → DUPLICATE found!', name: 'EmployeesScreen');
        duplicates.add(newEmp);
      } else {
        developer.log('  → NEW employee', name: 'EmployeesScreen');
        newOnes.add(newEmp);
      }
    }
    
    developer.log('=== DUPLICATE CHECK RESULT ===', name: 'EmployeesScreen');
    developer.log('New: ${newOnes.length}, Duplicates: ${duplicates.length}', name: 'EmployeesScreen');
    
    return DuplicateCheckResult(
      newEmployees: newOnes,
      duplicates: duplicates,
    );
  }

  Widget _buildPreviewDialog(
    BuildContext dialogContext,
    List<EmployeeModel> allEmployees,
    DuplicateCheckResult duplicateCheck,
  ) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.preview, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Preview Import Data'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
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
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Import Summary',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Total in CSV: ${allEmployees.length}'),
                  Text(
                    '✅ New employees: ${duplicateCheck.newEmployees.length}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  if (duplicateCheck.duplicates.isNotEmpty)
                    Text(
                      '⚠️  Duplicates (will be skipped): ${duplicateCheck.duplicates.length}',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Preview list
            const Text(
              'Preview of employees to be imported:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = allEmployees[index];
                    final isDuplicate = duplicateCheck.duplicates.any(
                      (d) => d.employeeCode.toLowerCase() == emp.employeeCode.toLowerCase(),
                    );
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isDuplicate 
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.05),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isDuplicate ? Icons.warning : Icons.check_circle,
                          color: isDuplicate ? Colors.orange : Colors.green,
                          size: 20,
                        ),
                        title: Text(
                          emp.name,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: isDuplicate ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          '${emp.employeeCode} • ${emp.position} • ${emp.department}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${emp.salary.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              emp.mobileNo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            if (duplicateCheck.duplicates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Duplicate employees (marked with ⚠️) will be skipped to prevent duplicates.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: duplicateCheck.newEmployees.isEmpty
              ? null
              : () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.upload),
          label: Text(
            duplicateCheck.newEmployees.isEmpty
                ? 'No New Employees'
                : 'Import ${duplicateCheck.newEmployees.length} Employee${duplicateCheck.newEmployees.length > 1 ? 's' : ''}',
          ),
        ),
      ],
    );
  }

}

class DuplicateCheckResult {
  final List<EmployeeModel> newEmployees;
  final List<EmployeeModel> duplicates;
  
  DuplicateCheckResult({
    required this.newEmployees,
    required this.duplicates,
  });
}