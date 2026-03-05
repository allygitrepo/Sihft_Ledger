import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/designation_model.dart';

const String _designationsKey = 'designations_data';

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
    Future.microtask(() => loadDesignations());
    return DesignationState();
  }

  Future<void> loadDesignations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_designationsKey);

      if (dataString != null) {
        final List<dynamic> decodedList = json.decode(dataString);
        final designations = decodedList
            .map((item) => DesignationModel.fromMap(item))
            .toList();
        state = state.copyWith(designations: designations, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addDesignation(DesignationModel designation) async {
    try {
      final updatedList = [...state.designations, designation];
      await _saveToStorage(updatedList);
      state = state.copyWith(designations: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateDesignation(DesignationModel updatedDesignation) async {
    try {
      final updatedList = state.designations.map((desig) {
        if (desig.id == updatedDesignation.id) {
          return updatedDesignation;
        }
        return desig;
      }).toList();

      await _saveToStorage(updatedList);
      state = state.copyWith(designations: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDesignation(String id) async {
    try {
      final updatedList = state.designations
          .where((desig) => desig.id != id)
          .toList();
      await _saveToStorage(updatedList);
      state = state.copyWith(designations: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleStatus(String id) async {
    try {
      final updatedList = state.designations.map((desig) {
        if (desig.id == id) {
          return desig.copyWith(
            status: !desig.status,
            updatedAt: DateTime.now(),
          );
        }
        return desig;
      }).toList();

      await _saveToStorage(updatedList);
      state = state.copyWith(designations: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> _saveToStorage(List<DesignationModel> designations) async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = designations.map((desig) => desig.toMap()).toList();
    await prefs.setString(_designationsKey, json.encode(dataList));
  }
}

final designationProvider =
    NotifierProvider<DesignationNotifier, DesignationState>(
      DesignationNotifier.new,
    );
