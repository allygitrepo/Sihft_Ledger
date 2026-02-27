import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/setup_service.dart';

// Setup state model
class SetupState {
  final bool isSetupCompleted;
  final bool isLoading;

  const SetupState({
    this.isSetupCompleted = false,
    this.isLoading = true,
  });

  SetupState copyWith({
    bool? isSetupCompleted,
    bool? isLoading,
  }) {
    return SetupState(
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState()) {
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final isCompleted = await SetupService.isSetupCompleted();
    state = state.copyWith(
      isSetupCompleted: isCompleted,
      isLoading: false,
    );
  }

  /// Refresh setup status
  Future<void> refreshSetupStatus() async {
    state = state.copyWith(isLoading: true);
    await _checkSetupStatus();
  }

  /// Complete setup
  Future<void> completeSetup() async {
    await SetupService.completeSetup();
    state = state.copyWith(isSetupCompleted: true);
  }

  /// Reset setup (for testing)
  Future<void> resetSetup() async {
    await SetupService.resetSetup();
    state = state.copyWith(isSetupCompleted: false);
  }
}

// Provider for setup management
final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier();
});
