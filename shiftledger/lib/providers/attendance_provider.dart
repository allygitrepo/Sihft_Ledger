import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../widgets/toast.dart';

class AttendanceState {
  final List<AttendanceModel> attendanceRecords;
  final bool isLoading;

  const AttendanceState({
    this.attendanceRecords = const [],
    this.isLoading = false,
  });

  AttendanceState copyWith({
    List<AttendanceModel>? attendanceRecords,
    bool? isLoading,
  }) {
    return AttendanceState(
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AttendanceNotifier extends Notifier<AttendanceState> {
  @override
  AttendanceState build() {
    loadAttendance();
    return const AttendanceState();
  }

  Future<void> loadAttendance() async {
    state = state.copyWith(isLoading: true);
    final records = await AttendanceService.loadAttendance();
    state = state.copyWith(attendanceRecords: records, isLoading: false);
  }

  Future<void> addAttendance(AttendanceModel record) async {
    state = state.copyWith(isLoading: true);
    await AttendanceService.addAttendance(record);
    await loadAttendance();
    ToastHelper.success('Attendance recorded successfully');
  }

  Future<void> updateAttendance(AttendanceModel record) async {
    state = state.copyWith(isLoading: true);
    await AttendanceService.updateAttendance(record);
    await loadAttendance();
    ToastHelper.success('Attendance updated successfully');
  }

  Future<List<AttendanceModel>> getTodayAttendance() async {
    return await AttendanceService.getTodayAttendance();
  }

  Future<List<AttendanceModel>> getAttendanceByDate(DateTime date) async {
    return await AttendanceService.getAttendanceByDate(date);
  }

  List<AttendanceModel> getEmployeeAttendance(String employeeId) {
    return state.attendanceRecords
        .where((r) => r.employeeId == employeeId)
        .toList();
  }
}

final attendanceProvider = NotifierProvider<AttendanceNotifier, AttendanceState>(() {
  return AttendanceNotifier();
});
