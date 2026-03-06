import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/designation_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

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
    return DesignationState();
  }

  Future<void> loadDesignations(String departmentId) async {
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = state.copyWith(error: 'Auth token missing');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.getDesignations(departmentId, token);

      if (response['success'] == true) {
        final List<dynamic> data = response['designations'] ?? [];
        final designations = data
            .map((item) => DesignationModel.fromMap(item))
            .toList();
        state = state.copyWith(designations: designations, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load designations',
        );
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
