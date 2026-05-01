import 'dart:convert';
import 'dart:developer' as developer;
import '../models/csv_employee_preview.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import '../services/employee_service.dart';

class CsvImportService {
  static Future<List<CsvEmployeePreview>> parseCSV(
    String csvContent,
    SettingsModel settings,
  ) async {
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
    
    // Check if we have at least some recognizable columns
    final possibleColumns = ['id', 'name', 'code', 'position', 'designation', 'department', 'salary'];
    bool hasAny = false;
    for (final column in possibleColumns) {
      if (header.contains(column)) {
        hasAny = true;
        break;
      }
    }
    
    if (!hasAny) {
      throw Exception('CSV header does not contain recognizable columns (ID, Name, Salary, etc.)');
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty || line.replaceAll(',', '').trim().isEmpty) {
        continue;
      }

      try {
        final preview = _parsePreviewLine(line, i + 1, settings);
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

  static CsvEmployeePreview _parsePreviewLine(
    String line,
    int lineNumber,
    SettingsModel settings,
  ) {
    final parts = line.split(',').map((e) => e.trim()).toList();

    // Support both 5 columns (no mobile) and 6 columns (with mobile)
    if (parts.length < 5) {
      throw Exception(
        'Line must have at least 5 columns: Employee ID, Name, Position, Department, Salary',
      );
    }

    // Use indexes based on header or try common patterns
    // For now, keep it simple but handle more variations
    final employeeCode = parts[0];
    final name = parts[1];

    String mobileNo = '';
    String position = '';
    String department = '';
    String salaryString = '';

    if (parts.length >= 6 && parts.length < 8) {
      // Common 6 column: ID, Name, Mobile, Position, Dept, Salary
      mobileNo = parts[2];
      position = parts[3];
      department = parts[4];
      salaryString = parts[5];
    } else if (parts.length == 5) {
      // 5 column: ID, Name, Position, Dept, Salary
      position = parts[2];
      department = parts[3];
      salaryString = parts[4];
    } else if (parts.length >= 8) {
      // Exported format: id, employee_code, full_name, phone, department, designation, monthly_salary, join_date
      mobileNo = parts[3];
      department = parts[4];
      position = parts[5];
      salaryString = parts[6];
    }

    if (name.isEmpty) throw Exception('Name cannot be empty at line $lineNumber');

    // Split name into first and last name
    final nameParts = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    final firstName = nameParts.isNotEmpty ? nameParts[0] : 'Employee';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Clean salary string - remove currency symbols, commas, spaces
    final cleanedSalary = salaryString
        .replaceAll(
          RegExp(r'[₹$,\s]'),
          '',
        ) // Remove currency symbols, commas, spaces
        .replaceAll(
          RegExp(r'[^\d.]'),
          '',
        ); // Keep only digits and decimal point

    final salary = double.tryParse(cleanedSalary);
    if (salary == null) {
      throw Exception(
        'Invalid salary value "$salaryString". Must be a number (e.g., 50000 or 50,000)',
      );
    }

    if (salary <= 0) {
      throw Exception('Salary must be greater than 0');
    }

    // Convert salary based on company settings
    final conversion = EmployeeService.convertSalary(salary, settings);

    return CsvEmployeePreview(
      employeeCode: employeeCode,
      firstName: firstName,
      lastName: lastName,
      mobileNo: mobileNo,
      position: position,
      department: department,
      salary: salary,
      employeeType: settings.defaultSalaryType == DefaultSalaryType.hourwise
          ? EmployeeType.hourly
          : EmployeeType.daily,
      hourlyRate: conversion['hourlyRate'] as double?,
      dailyRate: conversion['dailyRate'] as double?,
    );
  }

  static bool validateCSVFormat(String csvContent) {
    try {
      final lines = const LineSplitter().convert(csvContent);

      if (lines.isEmpty) return false;

      final header = lines[0].toLowerCase();
      final requiredColumns = [
        'id',
        'name',
        'position',
        'department',
        'salary',
      ];

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
