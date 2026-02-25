import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance_data';

  // Save attendance records
  static Future<void> saveAttendance(List<AttendanceModel> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_attendanceKey, jsonString);
  }

  // Load all attendance records
  static Future<List<AttendanceModel>> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_attendanceKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add attendance record
  static Future<void> addAttendance(AttendanceModel record) async {
    final records = await loadAttendance();
    records.add(record);
    await saveAttendance(records);
  }

  // Update attendance record
  static Future<void> updateAttendance(AttendanceModel record) async {
    final records = await loadAttendance();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await saveAttendance(records);
    }
  }

  // Get attendance by employee and date range
  static Future<List<AttendanceModel>> getAttendanceByEmployeeAndDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final records = await loadAttendance();
    return records.where((r) {
      return r.employeeId == employeeId &&
          r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          r.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get today's attendance
  static Future<List<AttendanceModel>> getTodayAttendance() async {
    final records = await loadAttendance();
    final today = DateTime.now();
    return records.where((r) {
      return r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day;
    }).toList();
  }

  // Get attendance by date
  static Future<List<AttendanceModel>> getAttendanceByDate(DateTime date) async {
    final records = await loadAttendance();
    return records.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  // Clear all attendance
  static Future<void> clearAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attendanceKey);
  }
}
