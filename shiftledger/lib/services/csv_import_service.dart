import 'dart:convert';
import '../models/employee_model.dart';
import '../models/settings_model.dart';

class CsvImportService {
  // Parse CSV content and return list of employees
  static Future<List<EmployeeModel>> parseCSV(
    String csvContent,
    AttendanceType attendanceType,
  ) async {
    final List<EmployeeModel> employees = [];
    final lines = const LineSplitter().convert(csvContent);

    if (lines.isEmpty) {
      throw Exception('CSV file is empty. Please add employee data.');
    }

    if (lines.length < 2) {
      throw Exception('CSV file must contain at least a header row and one data row.');
    }

    // Validate header
    final header = lines[0].toLowerCase();
    if (!header.contains('name')) {
      throw Exception('CSV header must contain "Name" column.');
    }
    if (!header.contains('code')) {
      throw Exception('CSV header must contain "Employee Code" or "Code" column.');
    }

    // Skip header row
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final employee = _parseEmployeeLine(line, attendanceType, i + 1);
        employees.add(employee);
      } catch (e) {
        throw Exception('Error at line ${i + 1}: ${e.toString()}');
      }
    }

    if (employees.isEmpty) {
      throw Exception('No valid employee data found in CSV file.');
    }

    return employees;
  }

  static EmployeeModel _parseEmployeeLine(
    String line,
    AttendanceType attendanceType,
    int lineNumber,
  ) {
    final parts = line.split(',').map((e) => e.trim()).toList();

    if (parts.length < 3) {
      throw Exception('Line must have at least 3 columns: Name, Code, Rate');
    }

    final name = parts[0];
    final employeeCode = parts[1];
    final rateString = parts[2];

    if (name.isEmpty) {
      throw Exception('Employee name cannot be empty');
    }

    if (employeeCode.isEmpty) {
      throw Exception('Employee code cannot be empty');
    }

    final rateValue = double.tryParse(rateString);
    if (rateValue == null) {
      throw Exception('Invalid rate value "$rateString". Must be a number.');
    }

    if (rateValue <= 0) {
      throw Exception('Rate must be greater than 0');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        employeeCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') +
        lineNumber.toString();

    switch (attendanceType) {
      case AttendanceType.daily:
        return EmployeeModel(
          id: id,
          name: name,
          employeeCode: employeeCode,
          baseSalary: rateValue,
          createdAt: DateTime.now(),
        );
      case AttendanceType.hourly:
        return EmployeeModel(
          id: id,
          name: name,
          employeeCode: employeeCode,
          hourlyRate: rateValue,
          createdAt: DateTime.now(),
        );
      case AttendanceType.unit:
        return EmployeeModel(
          id: id,
          name: name,
          employeeCode: employeeCode,
          perUnitRate: rateValue,
          createdAt: DateTime.now(),
        );
    }
  }

  // Validate CSV format
  static bool validateCSVFormat(String csvContent) {
    try {
      final lines = const LineSplitter().convert(csvContent);
      if (lines.isEmpty) return false;

      // Check header
      final header = lines[0].toLowerCase();
      
      // Must contain 'name' and 'code' (or 'employee code')
      final hasName = header.contains('name');
      final hasCode = header.contains('code');
      
      if (!hasName || !hasCode) {
        return false;
      }

      // Must have at least one data row
      if (lines.length < 2) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Generate sample CSV template
  static String generateSampleCSV(AttendanceType attendanceType) {
    String rateColumn;
    String sampleRate;

    switch (attendanceType) {
      case AttendanceType.daily:
        rateColumn = 'Base Salary';
        sampleRate = '5000';
        break;
      case AttendanceType.hourly:
        rateColumn = 'Hourly Rate';
        sampleRate = '150';
        break;
      case AttendanceType.unit:
        rateColumn = 'Per Unit Rate';
        sampleRate = '50';
        break;
    }

    return '''Name,Employee Code,$rateColumn
John Doe,EMP001,$sampleRate
Jane Smith,EMP002,$sampleRate
Mike Johnson,EMP003,$sampleRate''';
  }
}
