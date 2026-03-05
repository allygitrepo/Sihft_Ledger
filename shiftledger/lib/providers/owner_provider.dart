import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/owner_model.dart';
import '../services/owner_service.dart';
import '../widgets/toast.dart';

// Owner state model
class OwnerState {
  final bool isLoading;
  final OwnerModel? owner;
  final String ownerName;
  final String mobileNumber;
  final String password;
  final String? email;

  const OwnerState({
    this.isLoading = false,
    this.owner,
    this.ownerName = '',
    this.mobileNumber = '',
    this.password = '',
    this.email,
  });

  OwnerState copyWith({
    bool? isLoading,
    OwnerModel? owner,
    String? ownerName,
    String? mobileNumber,
    String? password,
    String? email,
  }) {
    return OwnerState(
      isLoading: isLoading ?? this.isLoading,
      owner: owner ?? this.owner,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      email: email ?? this.email,
    );
  }
}

class OwnerNotifier extends StateNotifier<OwnerState> {
  OwnerNotifier() : super(const OwnerState()) {
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final owner = await OwnerService.loadOwner();
    if (owner != null) {
      state = state.copyWith(owner: owner);
    }
  }

  // Setters for form fields
  void setOwnerName(String value) {
    state = state.copyWith(ownerName: value.trim());
  }

  void setMobileNumber(String value) {
    state = state.copyWith(mobileNumber: value.trim());
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim());
  }

  /// Register owner (Step 1 of registration)
  Future<bool> registerOwner() async {
    if (state.ownerName.isEmpty || 
        state.mobileNumber.isEmpty || 
        state.password.isEmpty) {
      ToastHelper.error('Please fill all required fields');
      return false;
    }

    // Validate mobile number (10 digits)
    if (state.mobileNumber.length != 10 || 
        !RegExp(r'^[0-9]+$').hasMatch(state.mobileNumber)) {
      ToastHelper.error('Please enter a valid 10-digit mobile number');
      return false;
    }

    // Validate password length
    if (state.password.length < 6) {
      ToastHelper.error('Password must be at least 6 characters');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final owner = OwnerModel(
        ownerName: state.ownerName,
        mobileNumber: state.mobileNumber,
        password: state.password,
        email: state.email?.isEmpty == true ? null : state.email,
        createdAt: DateTime.now(),
      );

      await OwnerService.saveOwner(owner);
      
      state = state.copyWith(
        isLoading: false,
        owner: owner,
      );

      ToastHelper.success('Owner details saved successfully');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastHelper.error('Failed to save owner details: $e');
      return false;
    }
  }

  /// Clear owner data
  Future<void> clearOwner() async {
    await OwnerService.clearOwner();
    state = const OwnerState();
  }
}

// Provider for owner management
final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerState>((ref) {
  return OwnerNotifier();
});
