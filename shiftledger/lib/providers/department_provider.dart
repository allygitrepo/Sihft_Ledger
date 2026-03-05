import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/department_model.dart';

const String _departmentsKey = 'departments_data';

class DepartmentState {
  final List<DepartmentModel> departments;
  final bool isLoading;
  final String? error;

  DepartmentState({
    this.departments = const [],
    this.isLoading = false,
    this.error,
  });

  DepartmentState copyWith({
    List<DepartmentModel>? departments,
    bool? isLoading,
    String? error,
  }) {
    return DepartmentState(
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DepartmentNotifier extends Notifier<DepartmentState> {
  @override
  DepartmentState build() {
    Future.microtask(() => loadDepartments());
    return DepartmentState();
  }

  Future<void> loadDepartments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_departmentsKey);

      if (dataString != null) {
        final List<dynamic> decodedList = json.decode(dataString);
        final departments = decodedList
            .map((item) => DepartmentModel.fromMap(item))
            .toList();
        state = state.copyWith(departments: departments, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addDepartment(DepartmentModel department) async {
    try {
      final updatedList = [...state.departments, department];
      await _saveToStorage(updatedList);
      state = state.copyWith(departments: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateDepartment(DepartmentModel updatedDepartment) async {
    try {
      final updatedList = state.departments.map((dept) {
        if (dept.id == updatedDepartment.id) {
          return updatedDepartment;
        }
        return dept;
      }).toList();

      await _saveToStorage(updatedList);
      state = state.copyWith(departments: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDepartment(String id) async {
    try {
      final updatedList = state.departments
          .where((dept) => dept.id != id)
          .toList();
      await _saveToStorage(updatedList);
      state = state.copyWith(departments: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleStatus(String id) async {
    try {
      final updatedList = state.departments.map((dept) {
        if (dept.id == id) {
          return dept.copyWith(status: !dept.status, updatedAt: DateTime.now());
        }
        return dept;
      }).toList();

      await _saveToStorage(updatedList);
      state = state.copyWith(departments: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> _saveToStorage(List<DepartmentModel> departments) async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = departments.map((dept) => dept.toMap()).toList();
    await prefs.setString(_departmentsKey, json.encode(dataList));
  }
}

final departmentProvider =
    NotifierProvider<DepartmentNotifier, DepartmentState>(
      DepartmentNotifier.new,
    );
