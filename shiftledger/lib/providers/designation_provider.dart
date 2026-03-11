import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/designation_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/department_provider.dart';

class DesignationState {
  final List<DesignationModel> designations;
  final bool isLoading;
  final String? error;

  DesignationState({
    this.designations = const [],
    this.isLoading = false,
    this.error,
  });

  DesignationState copyWith({
    List<DesignationModel>? designations,
    bool? isLoading,
    String? error,
  }) {
    return DesignationState(
      designations: designations ?? this.designations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DesignationNotifier extends Notifier<DesignationState> {
  @override
  DesignationState build() {
    // Re-load when departments change or sync
    ref.watch(departmentProvider);

    // Initial load if departments already present
    Future.microtask(() => loadAllDesignations());

    return DesignationState();
  }

  Future<void> loadAllDesignations() async {
    final depts = ref.read(departmentProvider).departments;
    final token = ref.read(authProvider).token;

    if (token == null || depts.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      List<DesignationModel> allDesignations = [];

      // Fetch designations for each department
      // Note: Backend getAll supports department_id filtering.
      // If backend doesn't support company_id filter for designations yet,
      // we aggregate here.
      for (var dept in depts) {
        final response = await ApiService.getDesignations(dept.id, token);
        if (response['success'] == true) {
          final List<dynamic> data = response['designations'] ?? [];
          final designations = data
              .map((item) => DesignationModel.fromMap(item))
              .toList();
          allDesignations.addAll(designations);
        }
      }

      // Remove duplicates if any (by ID)
      final seenIds = <String>{};
      allDesignations = allDesignations
          .where((d) => seenIds.add(d.id))
          .toList();

      state = state.copyWith(designations: allDesignations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDesignations(String departmentId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    // Check if we already have designations for this department to avoid redundant calls
    final hasDesignations = state.designations.any((d) => d.departmentId == departmentId);
    if (hasDesignations) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService.getDesignations(departmentId, token);
      if (response['success'] == true) {
        final List<dynamic> data = response['designations'] ?? [];
        final newDesignations = data
            .map((item) => DesignationModel.fromMap(item))
            .toList();
        
        // Merge with existing avoiding duplicates
        final updatedList = List<DesignationModel>.from(state.designations);
        for (var desig in newDesignations) {
          if (!updatedList.any((d) => d.id == desig.id)) {
            updatedList.add(desig);
          }
        }
        
        state = state.copyWith(designations: updatedList, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: response['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addDesignation({
    required String departmentId,
    required String designationName,
  }) async {
    final token = ref.read(authProvider).token;

    print('Adding Designation: $designationName');
    print('Department ID: $departmentId');

    if (token == null) {
      print('Error: Auth token missing');
      state = state.copyWith(error: 'Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.createDesignation(
        departmentId: departmentId,
        designationName: designationName,
        token: token,
      );

      print('Create Designation response: ${response['success']}');
      if (response['success'] == true) {
        await loadDesignations(departmentId);
        return true;
      } else {
        print('Create Designation failed: ${response['message']}');
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to add designation',
        );
        return false;
      }
    } catch (e) {
      print('Create Designation exception: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateDesignation(DesignationModel designation) async {
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.updateDesignation(
        id: designation.id,
        designationName: designation.designationName,
        status: designation.status,
        token: token,
      );

      if (response['success'] == true) {
        await loadDesignations(designation.departmentId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update designation',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDesignation(String id, String departmentId) async {
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.deleteDesignation(id, token);

      if (response['success'] == true) {
        await loadDesignations(departmentId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete designation',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleStatus(String id) async {
    final designation = state.designations.firstWhere((d) => d.id == id);
    return updateDesignation(designation.copyWith(status: !designation.status));
  }
}

final designationProvider =
    NotifierProvider<DesignationNotifier, DesignationState>(
      DesignationNotifier.new,
    );
