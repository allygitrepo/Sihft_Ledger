import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'dart:developer' as developer;
import '../models/csv_employee_preview.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import 'employee_service.dart';

class ExcelImportService {
  static Future<List<CsvEmployeePreview>> parseExcel(
    Uint8List bytes,
    SettingsModel settings,
  ) async {
    developer.log('EXCEL IMPORT START', name: 'ExcelImportService');

    final excel = Excel.decodeBytes(bytes);
    final List<CsvEmployeePreview> previews = [];

    if (excel.tables.isEmpty) {
      throw Exception('Excel file contains no sheets');
    }

    // Use the first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null || sheet.maxRows < 2) {
      throw Exception('Excel sheet is empty or missing data rows');
    }

    final rows = sheet.rows;
    final headerRow = rows[0];
    
    // Find column indexes
    int idIdx = -1;
    int nameIdx = -1;
    int mobileIdx = -1;
    int positionIdx = -1;
    int departmentIdx = -1;
    int salaryIdx = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final cellValue = headerRow[i]?.value?.toString().toLowerCase().trim() ?? '';
      if (cellValue.isEmpty) continue;

      if (cellValue.contains('id') || cellValue.contains('code')) {
        idIdx = i;
      } else if (cellValue.contains('name') || cellValue.contains('full name')) {
        nameIdx = i;
      } else if (cellValue.contains('mobile') || cellValue.contains('phone') || cellValue.contains('contact')) {
        mobileIdx = i;
      } else if (cellValue.contains('position') || cellValue.contains('designation') || cellValue.contains('role')) {
        positionIdx = i;
      } else if (cellValue.contains('department') || cellValue.contains('dept')) {
        departmentIdx = i;
      } else if (cellValue.contains('salary') || cellValue.contains('pay') || cellValue.contains('monthly')) {
        salaryIdx = i;
      }
    }

    // Fallback to defaults if headers not found but we have enough columns (positional fallback)
    if (idIdx == -1) idIdx = 0;
    if (nameIdx == -1) nameIdx = 1;
    if (mobileIdx == -1 && headerRow.length > 2) mobileIdx = 2;
    if (positionIdx == -1 && headerRow.length > 3) positionIdx = 3;
    if (departmentIdx == -1 && headerRow.length > 4) departmentIdx = 4;
    if (salaryIdx == -1 && headerRow.length > 5) salaryIdx = 5;

    developer.log('Mapped Excel columns: ID:$idIdx, Name:$nameIdx, Mobile:$mobileIdx, Pos:$positionIdx, Dept:$departmentIdx, Salary:$salaryIdx', name: 'ExcelImportService');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        // Safe access to cells
        String getVal(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          return row[idx]?.value?.toString().trim() ?? '';
        }

        final name = getVal(nameIdx);
        if (name.isEmpty) continue;

        final employeeCode = getVal(idIdx);
        final mobileNo = getVal(mobileIdx);
        final position = getVal(positionIdx);
        final department = getVal(departmentIdx);
        final salaryString = getVal(salaryIdx);

        // Split name into first and last name
        final nameParts = name.split(' ').where((s) => s.isNotEmpty).toList();
        final firstName = nameParts.isNotEmpty ? nameParts[0] : 'Employee';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // Clean salary string - remove currency symbols, commas, spaces
        final cleanedSalary = salaryString
            .replaceAll(RegExp(r'[₹$,\s]'), '')
            .replaceAll(RegExp(r'[^\d.]'), '');

        final salary = double.tryParse(cleanedSalary) ?? 0.0;
        
        // Skip if salary is 0 and it was expected to be a valid employee record
        if (salary <= 0 && name.length < 2) continue;

        // Convert salary based on company settings
        final conversion = EmployeeService.convertSalary(salary, settings);

        previews.add(CsvEmployeePreview(
          employeeCode: employeeCode.isEmpty ? 'EMP${100 + i}' : employeeCode,
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
        ));
      } catch (e) {
        developer.log('Error parsing row ${i + 1}: $e', name: 'ExcelImportService');
      }
    }

    if (previews.isEmpty) {
      throw Exception('No valid employee data found in Excel. Ensure Name and Salary columns are present.');
    }

    return previews;
  }
}
