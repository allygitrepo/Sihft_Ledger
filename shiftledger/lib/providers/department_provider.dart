import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../widgets/toast.dart';

class DepartmentState {
  final List<DepartmentModel> departments;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;

  const DepartmentState({
    this.departments = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
  });

  DepartmentState copyWith({
    List<DepartmentModel>? departments,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
  }) {
    return DepartmentState(
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}

class DepartmentNotifier extends Notifier<DepartmentState> {
  @override
  DepartmentState build() {
    // Watch for auth changes to reload departments
    ref.watch(authProvider);
    ref.watch(companyProvider);
    
    // Initial load
    Future.microtask(() => loadDepartments());
    
    return const DepartmentState();
  }

  Future<void> loadDepartments({int page = 1, int limit = 10, String search = ''}) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.getDepartments(
        companyId.toString(), 
        token,
        page: page,
        limit: limit,
        search: search,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['departments'] ?? [];
        final departments = data.map((json) => DepartmentModel.fromMap(json)).toList();
        
        state = state.copyWith(
          departments: departments,
          isLoading: false,
          currentPage: response['currentPage'] ?? 1,
          totalPages: response['totalPages'] ?? 1,
          totalRecords: response['totalRecords'] ?? departments.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load departments',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading departments: $e',
      );
    }
  }

  Future<bool> addDepartment(String name) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return false;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.createDepartment(
      companyId: companyId.toString(),
      departmentName: name,
      token: token,
    );

    if (response['success'] == true) {
      await loadDepartments();
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDepartment(int id) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.deleteDepartment(id.toString(), token);

    if (response['success'] == true) {
      await loadDepartments();
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final departmentProvider = NotifierProvider<DepartmentNotifier, DepartmentState>(() {
  return DepartmentNotifier();
});
