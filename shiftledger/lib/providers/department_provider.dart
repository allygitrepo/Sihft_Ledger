import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';

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
    // Watch for session readiness
    ref.watch(authProvider);
    ref.watch(companyProvider);

    // Initial check in case they are already ready
    Future.microtask(() => _checkAndLoad());

    return DepartmentState();
  }

  void _checkAndLoad() {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token != null &&
        companyId != null &&
        state.departments.isEmpty &&
        !state.isLoading) {
      loadDepartments();
    }
  }

  Future<void> loadDepartments() async {
    final companyState = ref.read(companyProvider);
    final company = companyState.company;
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return;
    }

    if (company == null || company.id == null) {
      if (companyState.isLoading) {
        state = state.copyWith(isLoading: true, error: null);
        return; // Wait for company to load
      }
      state = state.copyWith(
        error: 'Company ID missing. Please ensure your company is registered.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.getDepartments(company.id!, token);

      if (response['success'] == true) {
        final List<dynamic> data = response['departments'] ?? [];
        final departments = data
            .map((item) => DepartmentModel.fromMap(item))
            .toList();
        state = state.copyWith(departments: departments, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load departments',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addDepartment(String name) async {
    final company = ref.read(companyProvider).company;
    final token = ref.read(authProvider).token;

    print('Adding Department: $name');
    print('Company ID: ${company?.id}');

    if (company == null || token == null || company.id == null) {
      print('Error: Company or Token or Company ID is null');
      state = state.copyWith(error: 'Company ID or Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.createDepartment(
        companyId: company.id!,
        departmentName: name,
        token: token,
      );

      print('Create Department response: ${response['success']}');
      if (response['success'] == true) {
        await loadDepartments(); // Refresh list
        return true;
      } else {
        print('Create Department failed: ${response['message']}');
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to add department',
        );
        return false;
      }
    } catch (e) {
      print('Create Department exception: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateDepartment(DepartmentModel department) async {
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.updateDepartment(
        id: department.id,
        departmentName: department.departmentName,
        status: department.status,
        token: token,
      );

      if (response['success'] == true) {
        await loadDepartments();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update department',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDepartment(String id) async {
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.deleteDepartment(id, token);

      if (response['success'] == true) {
        await loadDepartments();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete department',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleStatus(String id) async {
    final department = state.departments.firstWhere((d) => d.id == id);
    return updateDepartment(department.copyWith(status: !department.status));
  }
}

final departmentProvider =
    NotifierProvider<DepartmentNotifier, DepartmentState>(
      DepartmentNotifier.new,
    );
