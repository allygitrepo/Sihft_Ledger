import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';

class AttendanceExportService {
  static Future<bool> exportAttendanceToCSV({
    required List<AttendanceModel> records,
    required List<EmployeeModel> employees,
  }) async {
    if (records.isEmpty) {
      print('Export aborted: Nothing to export.');
      return false;
    }

    try {
      print('Starting CSV generation for ${records.length} records...');
      // Create a map for quick employee lookup
      final employeeMap = {for (var emp in employees) emp.id: emp};

      // Define CSV headers
      List<List<dynamic>> csvData = [
        [
          'Employee ID',
          'Employee Name',
          'Department',
          'Date',
          'Check In Time',
          'Check Out Time',
          'Working Hours',
          'Overtime Hours',
          'Status',
        ],
      ];

      // Add data rows
      for (var record in records) {
        final employee = employeeMap[record.employeeId];
        final department = employee?.department ?? 'N/A';
        final employeeCode = employee?.employeeCode ?? 'N/A';

        csvData.add([
          employeeCode,
          record.employeeName,
          department,
          DateFormat('yyyy-MM-dd').format(record.date),
          DateFormat('HH:mm').format(record.checkIn),
          DateFormat('HH:mm').format(record.checkOut),
          record.workingHours.toStringAsFixed(2),
          record.overtimeHours.toStringAsFixed(2),
          _getStatusText(record.attendanceStatus),
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Use utf8 for better character support on all platforms
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvString));

      // Generate filename
      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final fileName = 'attendance_export_$dateStr';

      print('Saving file as $fileName.csv - Web: $kIsWeb');

      // Manual Windows saving if running as a Desktop app (NOT on Web)
      if (!kIsWeb && Platform.isWindows) {
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final filePath = '${downloadsDir.path}/$fileName.csv';
            final file = File(filePath);
            await file.writeAsBytes(bytes);
            print('File saved directly to Windows Downloads: $filePath');
            return true;
          }
        } catch (e) {
          print(
            'Optional Windows direct save failed, falling back to file_saver: $e',
          );
        }
      }

      // Default saving using file_saver (Works on Web, Mobile, and Desktop)
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      print('File saved via file_saver plugin.');

      return true;
    } catch (e) {
      print('CRITICAL: Export error: $e');
      return false;
    }
  }

  static String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return 'Present';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
}
