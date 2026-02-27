import 'dart:convert';
import 'dart:developer' as developer;
import '../models/csv_employee_preview.dart';
import '../models/employee_model.dart';

class CsvImportService {
  static Future<List<CsvEmployeePreview>> parseCSV(String csvContent) async {
    developer.log('CSV IMPORT START', name: 'CsvImportService');
    
    final List<CsvEmployeePreview> previews = [];
    final lines = const LineSplitter().convert(csvContent);

    if (lines.isEmpty) {
      throw Exception('CSV file is empty');
    }

    if (lines.length < 2) {
      throw Exception('CSV must contain header and data rows');
    }

    final header = lines[0].toLowerCase();
    final requiredColumns = ['id', 'name', 'position', 'department', 'salary'];
    
    for (final column in requiredColumns) {
      if (!header.contains(column)) {
        throw Exception('CSV header must contain "$column" column');
      }
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty || line.replaceAll(',', '').trim().isEmpty) {
        continue;
      }

      try {
        final preview = _parsePreviewLine(line, i + 1);
        previews.add(preview);
      } catch (e) {
        throw Exception('Error at line ${i + 1}: ${e.toString()}');
      }
    }

    if (previews.isEmpty) {
      throw Exception('No valid employee data found');
    }

    return previews;
  }

  static CsvEmployeePreview _parsePreviewLine(String line, int lineNumber) {
    final parts = line.split(',').map((e) => e.trim()).toList();

    // Support both 5 columns (no mobile) and 6 columns (with mobile)
    if (parts.length < 5) {
      throw Exception('Line must have at least 5 columns: Employee ID, Name, Position, Department, Salary');
    }

    final employeeCode = parts[0];
    final name = parts[1];
    
    // Check if we have 6 columns (with mobile) or 5 columns (without mobile)
    String mobileNo, position, department, salaryString;
    
    if (parts.length >= 6) {
      // 6 columns: ID, Name, Mobile, Position, Department, Salary
      mobileNo = parts[2];
      position = parts[3];
      department = parts[4];
      salaryString = parts[5];
    } else {
      // 5 columns: ID, Name, Position, Department, Salary
      mobileNo = ''; // No mobile number provided
      position = parts[2];
      department = parts[3];
      salaryString = parts[4];
    }

    if (employeeCode.isEmpty) throw Exception('Employee ID cannot be empty');
    if (name.isEmpty) throw Exception('Employee name cannot be empty');
    if (position.isEmpty) throw Exception('Position cannot be empty');
    if (department.isEmpty) throw Exception('Department cannot be empty');

    // Clean salary string - remove currency symbols, commas, spaces
    final cleanedSalary = salaryString
        .replaceAll(RegExp(r'[₹$,\s]'), '') // Remove currency symbols, commas, spaces
        .replaceAll(RegExp(r'[^\d.]'), ''); // Keep only digits and decimal point

    final salary = double.tryParse(cleanedSalary);
    if (salary == null) {
      throw Exception('Invalid salary value "$salaryString". Must be a number (e.g., 50000 or 50,000)');
    }

    if (salary <= 0) {
      throw Exception('Salary must be greater than 0');
    }

    return CsvEmployeePreview(
      employeeCode: employeeCode,
      name: name,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      // Initialize with default hourly type and calculate hourly rate from salary
      employeeType: EmployeeType.hourly,
      hourlyRate: salary / 208, // Assuming 26 days * 8 hours = 208 hours per month
      dailyRate: salary / 26, // Assuming 26 working days per month
    );
  }

  static bool validateCSVFormat(String csvContent) {
    try {
      final lines = const LineSplitter().convert(csvContent);
      
      if (lines.isEmpty) return false;

      final header = lines[0].toLowerCase();
      final requiredColumns = ['id', 'name', 'position', 'department', 'salary'];
      
      for (final column in requiredColumns) {
        if (!header.contains(column)) return false;
      }

      if (lines.length < 2) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  static String generateSampleCSV() {
    return 'Employee ID,Employee Name,Employee Mobile No.,Employee Position,Employee Department,Employee Salary\n'
        'EMP001,John Doe,9876543210,Software Engineer,IT,50000\n'
        'EMP002,Jane Smith,9876543211,HR Manager,Human Resources,45000\n'
        'EMP003,Mike Johnson,9876543212,Sales Executive,Sales,40000';
  }
}
