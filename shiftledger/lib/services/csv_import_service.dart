import 'dart:convert';
import 'dart:developer' as developer;
import '../models/employee_model.dart';

class CsvImportService {
  // Parse CSV content and return list of employees
  static Future<List<EmployeeModel>> parseCSV(String csvContent) async {
    developer.log('=== CSV IMPORT DEBUG START ===', name: 'CsvImportService');
    developer.log('CSV Content Length: ${csvContent.length} characters', name: 'CsvImportService');
    
    final List<EmployeeModel> employees = [];
    final lines = const LineSplitter().convert(csvContent);

    developer.log('Total lines in CSV: ${lines.length}', name: 'CsvImportService');

    if (lines.isEmpty) {
      developer.log('ERROR: CSV file is empty', name: 'CsvImportService');
      throw Exception('CSV file is empty. Please add employee data.');
    }

    if (lines.length < 2) {
      developer.log('ERROR: CSV has only ${lines.length} line(s)', name: 'CsvImportService');
      throw Exception('CSV file must contain at least a header row and one data row.');
    }

    // Validate header
    final header = lines[0].toLowerCase();
    developer.log('Header row: "$header"', name: 'CsvImportService');
    
    final requiredColumns = ['id', 'name', 'mobile', 'position', 'department', 'salary'];
    developer.log('Required columns: $requiredColumns', name: 'CsvImportService');
    
    for (final column in requiredColumns) {
      if (!header.contains(column)) {
        developer.log('ERROR: Missing column "$column" in header', name: 'CsvImportService');
        developer.log('Available header: $header', name: 'CsvImportService');
        throw Exception('CSV header must contain "$column" column. Found header: $header');
      }
    }
    
    developer.log('Header validation passed', name: 'CsvImportService');
    developer.log('Header validation passed', name: 'CsvImportService');

    // Skip header row
    developer.log('Processing ${lines.length - 1} data rows', name: 'CsvImportService');
    
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      developer.log('--- Processing line $i ---', name: 'CsvImportService');
      developer.log('Line content: "$line"', name: 'CsvImportService');
      
      // Skip empty lines or lines with only commas
      if (line.isEmpty || line.replaceAll(',', '').trim().isEmpty) {
        developer.log('Skipping empty line $i', name: 'CsvImportService');
        continue;
      }

      try {
        final employee = _parseEmployeeLine(line, i + 1);
        employees.add(employee);
        developer.log('✓ Successfully parsed employee: ${employee.name} (${employee.employeeCode})', name: 'CsvImportService');
      } catch (e) {
        developer.log('✗ ERROR at line ${i + 1}: $e', name: 'CsvImportService');
        throw Exception('Error at line ${i + 1}: ${e.toString()}');
      }
    }

    if (employees.isEmpty) {
      developer.log('ERROR: No valid employee data found', name: 'CsvImportService');
      throw Exception('No valid employee data found in CSV file.');
    }

    developer.log('=== CSV IMPORT SUCCESS ===', name: 'CsvImportService');
    developer.log('Total employees parsed: ${employees.length}', name: 'CsvImportService');
    return employees;
  }

  static EmployeeModel _parseEmployeeLine(String line, int lineNumber) {
    developer.log('Parsing line $lineNumber', name: 'CsvImportService');
    
    final parts = line.split(',').map((e) => e.trim()).toList();
    developer.log('Split into ${parts.length} parts: $parts', name: 'CsvImportService');

    if (parts.length < 6) {
      developer.log('ERROR: Only ${parts.length} columns found, need 6', name: 'CsvImportService');
      throw Exception('Line must have 6 columns: Employee ID, Name, Mobile No, Position, Department, Salary. Found ${parts.length} columns.');
    }

    final employeeCode = parts[0];
    final name = parts[1];
    final mobileNo = parts[2];
    final position = parts[3];
    final department = parts[4];
    final salaryString = parts[5];

    developer.log('Extracted values:', name: 'CsvImportService');
    developer.log('  Employee ID: "$employeeCode"', name: 'CsvImportService');
    developer.log('  Name: "$name"', name: 'CsvImportService');
    developer.log('  Mobile: "$mobileNo"', name: 'CsvImportService');
    developer.log('  Position: "$position"', name: 'CsvImportService');
    developer.log('  Department: "$department"', name: 'CsvImportService');
    developer.log('  Salary: "$salaryString"', name: 'CsvImportService');

    if (employeeCode.isEmpty) {
      developer.log('ERROR: Employee ID is empty', name: 'CsvImportService');
      throw Exception('Employee ID cannot be empty');
    }

    if (name.isEmpty) {
      developer.log('ERROR: Employee name is empty', name: 'CsvImportService');
      throw Exception('Employee name cannot be empty');
    }

    if (mobileNo.isEmpty) {
      developer.log('ERROR: Mobile number is empty', name: 'CsvImportService');
      throw Exception('Mobile number cannot be empty');
    }

    if (position.isEmpty) {
      developer.log('ERROR: Position is empty', name: 'CsvImportService');
      throw Exception('Position cannot be empty');
    }

    if (department.isEmpty) {
      developer.log('ERROR: Department is empty', name: 'CsvImportService');
      throw Exception('Department cannot be empty');
    }

    final salary = double.tryParse(salaryString);
    if (salary == null) {
      developer.log('ERROR: Invalid salary value "$salaryString"', name: 'CsvImportService');
      throw Exception('Invalid salary value "$salaryString". Must be a number.');
    }

    if (salary <= 0) {
      developer.log('ERROR: Salary must be positive, got $salary', name: 'CsvImportService');
      throw Exception('Salary must be greater than 0');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        employeeCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') +
        lineNumber.toString();

    developer.log('Generated internal ID: $id', name: 'CsvImportService');

    return EmployeeModel(
      id: id,
      name: name,
      employeeCode: employeeCode,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      createdAt: DateTime.now(),
    );
  }

  // Validate CSV format
  static bool validateCSVFormat(String csvContent) {
    developer.log('=== CSV FORMAT VALIDATION ===', name: 'CsvImportService');
    
    try {
      final lines = const LineSplitter().convert(csvContent);
      developer.log('Lines count: ${lines.length}', name: 'CsvImportService');
      
      if (lines.isEmpty) {
        developer.log('Validation failed: Empty file', name: 'CsvImportService');
        return false;
      }

      // Check header
      final header = lines[0].toLowerCase();
      developer.log('Header: "$header"', name: 'CsvImportService');
      
      final requiredColumns = ['id', 'name', 'mobile', 'position', 'department', 'salary'];
      for (final column in requiredColumns) {
        if (!header.contains(column)) {
          developer.log('Validation failed: Missing column "$column"', name: 'CsvImportService');
          return false;
        }
      }

      // Must have at least one data row
      if (lines.length < 2) {
        developer.log('Validation failed: No data rows', name: 'CsvImportService');
        return false;
      }

      developer.log('Validation passed', name: 'CsvImportService');
      return true;
    } catch (e) {
      developer.log('Validation error: $e', name: 'CsvImportService');
      return false;
    }
  }

  // Generate sample CSV template
  static String generateSampleCSV() {
    return '''Employee ID,Employee Name,Employee Mobile No,Employee Position,Employee Department,Employee Salary
EMP001,John Doe,9876543210,Software Engineer,IT,50000
EMP002,Jane Smith,9876543211,HR Manager,Human Resources,45000
EMP003,Mike Johnson,9876543212,Sales Executive,Sales,40000''';
  }
}
