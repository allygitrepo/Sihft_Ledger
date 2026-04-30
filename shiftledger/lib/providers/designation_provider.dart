import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/designation_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../widgets/toast.dart';

class DesignationState {
  final List<DesignationModel> designations;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;

  const DesignationState({
    this.designations = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
  });

  DesignationState copyWith({
    List<DesignationModel>? designations,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
  }) {
    return DesignationState(
      designations: designations ?? this.designations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}

class DesignationNotifier extends Notifier<DesignationState> {
  @override
  DesignationState build() {
    ref.watch(authProvider);
    ref.watch(companyProvider);
    
    // Initial load
    Future.microtask(() => loadDesignations());
    
    return const DesignationState();
  }

  Future<void> loadDesignations({
    int? departmentId, 
    int page = 1, 
    int limit = 10,
    String search = '',
  }) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.getDesignations(
        token,
        companyId: companyId.toString(),
        departmentId: departmentId?.toString(),
        page: page,
        limit: limit,
        search: search,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['designations'] ?? [];
        final designations = data.map((json) => DesignationModel.fromMap(json)).toList();
        
        state = state.copyWith(
          designations: designations,
          isLoading: false,
          currentPage: response['currentPage'] ?? 1,
          totalPages: response['totalPages'] ?? 1,
          totalRecords: response['totalRecords'] ?? designations.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load designations',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading designations: $e',
      );
    }
  }

  Future<bool> addDesignation({
    required String designationName,
    required int departmentId,
  }) async {
    final token = ref.read(authProvider).token;
    final companyId = ref.read(companyProvider).company?.id;

    if (token == null || companyId == null) return false;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.createDesignation(
      companyId: companyId.toString(),
      departmentId: departmentId.toString(),
      designationName: designationName,
      token: token,
    );

    if (response['success'] == true) {
      await loadDesignations(departmentId: departmentId);
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> updateDesignation(DesignationModel designation) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.updateDesignation(
      id: designation.id.toString(),
      designationName: designation.designationName,
      status: designation.status,
      token: token,
    );

    if (response['success'] == true) {
      await loadDesignations(departmentId: designation.departmentId);
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDesignation(int id, int departmentId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    state = state.copyWith(isLoading: true);
    final response = await ApiService.deleteDesignation(
      id.toString(),
      token,
    );

    if (response['success'] == true) {
      await loadDesignations(departmentId: departmentId);
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> toggleStatus(int id) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;

    final designation = state.designations.firstWhere((d) => d.id == id);
    final updated = designation.copyWith(status: !designation.status);
    
    return await updateDesignation(updated);
  }
}

final designationProvider = NotifierProvider<DesignationNotifier, DesignationState>(() {
  return DesignationNotifier();
});
