// No dart:convert needed — API calls handled by ApiService
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import 'api_constant.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Mark or update an attendance record
  static Future<bool> saveAttendance(AttendanceModel record) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'employee_id': record.employeeId,
        'date': DateFormat('yyyy-MM-dd').format(record.date),
        'clock_in': DateFormat('HH:mm:ss').format(record.checkIn),
        'clock_out': DateFormat('HH:mm:ss').format(record.checkOut),
        'attendance_status': record.attendanceStatus == AttendanceStatus.fullDay
            ? 'Present'
            : record.attendanceStatus == AttendanceStatus.halfDay
            ? 'Half-day'
            : 'Absent',
        'total_hours': record.workingHours,
        'work_salary': record.workSalary,
        'overtime_hours': record.overtimeHours,
        'overtime_salary': record.overtimeSalary,
        'total_salary': record.totalSalary,
      };

      final response = await ApiService.post(
        '${ApiConstant.baseUrl}/attendance/mark',
        body,
        headers: headers,
      );

      return response['success'] == true;
    } catch (e) {
      print('Error saving attendance: $e');
      return false;
    }
  }

  /// Add new attendance record (Wrapper for API consistency)
  static Future<void> addAttendance(AttendanceModel record) async {
    await saveAttendance(record);
  }

  /// Update existing attendance record (Wrapper for API consistency)
  static Future<void> updateAttendance(AttendanceModel record) async {
    await saveAttendance(record);
  }

  /// Delete attendance record (Not fully implemented on backend, placeholder)
  static Future<void> deleteAttendance(String id) async {
    // Note: Backend /api/attendance/delete route doesn't exist yet,
    // usually we don't delete attendance, but we could mark it absent.
    print('Delete attendance not implemented on backend yet');
  }

  /// Proxy for backward compatibility
  static Future<bool> attendanceExists(String employeeId, DateTime date) async {
    return checkAttendanceExists(employeeId, date);
  }

  /// Load all attendance records (Warning: This might be heavy if not paginated)
  static Future<List<AttendanceModel>> loadAttendance({String? companyId}) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Build URL with company_id query parameter if provided
      String url = '${ApiConstant.baseUrl}/attendance/all';
      if (companyId != null && companyId.isNotEmpty) {
        url += '?company_id=$companyId';
      }

      final response = await ApiService.get(url, headers: headers);

      if (response['success'] == true && response['attendance'] != null) {
        final List<dynamic> data = response['attendance'];
        return data.map((json) {
          final employeeData = json['Employee'];
          final employeeStr = employeeData != null 
              ? (employeeData['full_name'] ?? employeeData['name'] ?? 'Unknown')
              : 'Unknown';
          
          return AttendanceModel(
            id: json['id'].toString(),
            employeeId: json['employee_id'].toString(),
            employeeName: employeeStr,
            date: DateTime.parse(json['date']),
            checkIn: DateTime.parse(
              '${json['date']}T${json['clock_in'] ?? "00:00:00"}',
            ),
            checkOut: DateTime.parse(
              '${json['date']}T${json['clock_out'] ?? "00:00:00"}',
            ),
            workingHours:
                double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0.0,
            attendanceStatus: _parseStatusFromBackend(
              json['attendance_status'],
            ),
            workSalary:
                double.tryParse(json['work_salary']?.toString() ?? '0') ?? 0.0,
            overtimeHours:
                double.tryParse(json['overtime_hours']?.toString() ?? '0') ??
                0.0,
            overtimeSalary:
                double.tryParse(json['overtime_salary']?.toString() ?? '0') ??
                0.0,
            totalSalary:
                double.tryParse(json['total_salary']?.toString() ?? '0') ?? 0.0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading all attendance: $e');
      return [];
    }
  }

  /// Get attendance by employee and date range
  static Future<List<AttendanceModel>> getAttendanceByEmployeeAndDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Currently fetching all by employee and filtering locally to match previous interface
    final records = await getAttendanceByEmployee(employeeId);
    return records.where((r) {
      return r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          r.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get today's attendance
  static Future<List<AttendanceModel>> getTodayAttendance() async {
    return getAttendanceByDate(DateTime.now());
  }

  /// Get attendance by date for the company
  static Future<List<AttendanceModel>> getAttendanceByDate(
    DateTime date, {
    String? companyId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      // Build URL with company_id query parameter if provided
      String url = '${ApiConstant.baseUrl}/attendance/date/$formattedDate';
      if (companyId != null && companyId.isNotEmpty) {
        url += '?company_id=$companyId';
      }

      final response = await ApiService.get(url, headers: headers);

      if (response['success'] == true && response['attendance'] != null) {
        final List<dynamic> data = response['attendance'];
        return data.map((json) {
          final employeeData = json['Employee'];
          final employeeStr = employeeData != null 
              ? (employeeData['full_name'] ?? employeeData['name'] ?? 'Unknown')
              : 'Unknown';

          return AttendanceModel(
            id: json['id'].toString(),
            employeeId: json['employee_id'].toString(),
            employeeName: employeeStr,
            date: DateTime.parse(json['date']),
            checkIn: DateTime.parse(
              '${json['date']}T${json['clock_in'] ?? "00:00:00"}',
            ),
            checkOut: DateTime.parse(
              '${json['date']}T${json['clock_out'] ?? "00:00:00"}',
            ),
            workingHours:
                double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0.0,
            attendanceStatus: _parseStatusFromBackend(
              json['attendance_status'],
            ),
            workSalary:
                double.tryParse(json['work_salary']?.toString() ?? '0') ?? 0.0,
            overtimeHours:
                double.tryParse(json['overtime_hours']?.toString() ?? '0') ??
                0.0,
            overtimeSalary:
                double.tryParse(json['overtime_salary']?.toString() ?? '0') ??
                0.0,
            totalSalary:
                double.tryParse(json['total_salary']?.toString() ?? '0') ?? 0.0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading attendance by date: $e');
      return [];
    }
  }

  /// Parse backend status to frontend enum
  static AttendanceStatus _parseStatusFromBackend(String? status) {
    if (status == 'Present') return AttendanceStatus.fullDay;
    if (status == 'Half-day') return AttendanceStatus.halfDay;
    return AttendanceStatus.absent;
  }

  /// Get attendance by employee ID
  static Future<List<AttendanceModel>> getAttendanceByEmployee(
    String employeeId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await ApiService.get(
        '${ApiConstant.baseUrl}/attendance/employee/$employeeId',
        headers: headers,
      );

      if (response['success'] == true && response['attendance'] != null) {
        final List<dynamic> data = response['attendance'];
        return data.map((json) {
          return AttendanceModel(
            id: json['id'].toString(),
            employeeId: json['employee_id'].toString(),
            employeeName:
                'Unknown', // Need join to fetch name or passed from UI
            date: DateTime.parse(json['date']),
            checkIn: DateTime.parse(
              '${json['date']}T${json['clock_in'] ?? "00:00:00"}',
            ),
            checkOut: DateTime.parse(
              '${json['date']}T${json['clock_out'] ?? "00:00:00"}',
            ),
            workingHours:
                double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0.0,
            attendanceStatus: _parseStatusFromBackend(
              json['attendance_status'],
            ),
            workSalary:
                double.tryParse(json['work_salary']?.toString() ?? '0') ?? 0.0,
            overtimeHours:
                double.tryParse(json['overtime_hours']?.toString() ?? '0') ??
                0.0,
            overtimeSalary:
                double.tryParse(json['overtime_salary']?.toString() ?? '0') ??
                0.0,
            totalSalary:
                double.tryParse(json['total_salary']?.toString() ?? '0') ?? 0.0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading attendance by employee: $e');
      return [];
    }
  }

  /// Check if attendance exists for employee on date
  static Future<bool> checkAttendanceExists(
    String employeeId,
    DateTime date,
  ) async {
    final records = await getAttendanceByDate(date);
    return records.any((r) => r.employeeId == employeeId);
  }

  /// Clear all attendance (local cleanup usually, but we don't have local anymore)
  static Future<void> clearAttendance() async {
    // No-op for now since it's backend-driven
  }
}
