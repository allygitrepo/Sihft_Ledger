import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';  // ADD THIS LINE
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/toast.dart';

// Auth state model
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isInitialized; // Add this to track initialization
  final Map<String, dynamic>? userData;
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.isInitialized = false, // Add this
    this.userData,
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isInitialized, // Add this
    Map<String, dynamic>? userData,
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized, // Add this
      userData: userData ?? this.userData,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _isLoggedInKey = 'is_logged_in';
  
  AuthNotifier() : super(const AuthState()) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (isLoggedIn) {
      await _loadUserData();
    } else {
      state = state.copyWith(isLoggedIn: false, isInitialized: true);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'name': prefs.getString('user_name') ?? 'User',
      'email': prefs.getString('user_email') ?? '',
    };
    state = state.copyWith(
      isLoggedIn: true,
      isInitialized: true,
      userData: userData,
    );
  }

  // Setters for form fields
  void setName(String value) {
    state = state.copyWith(name: value.trim());
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim());
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  Future<void> login() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      ToastHelper.error('Please fill all fields');
      return;
    }

    state = state.copyWith(isLoading: true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already has registered data
    String userName = 'User'; // Default name for login
    final existingName = prefs.getString('user_name');
    final existingEmail = prefs.getString('user_email');
    
    if (existingName != null && existingEmail == state.email) {
      userName = existingName;
    }

    // Save login state
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString('user_name', userName);
    await prefs.setString('user_email', state.email);

    final userData = {
      'name': userName,
      'email': state.email,
    };

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      userData: userData,
    );

    ToastHelper.success('Login successful');
  }

  Future<void> register() async {
    if (state.name.isEmpty || state.email.isEmpty || state.password.isEmpty) {
      ToastHelper.error('Please fill all fields');
      return;
    }

    if (state.password != state.confirmPassword) {
      ToastHelper.error('Passwords do not match');
      return;
    }

    state = state.copyWith(isLoading: true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    // Save login state after registration
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString('user_name', state.name);
    await prefs.setString('user_email', state.email);

    final userData = {
      'name': state.name,
      'email': state.email,
    };

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      userData: userData,
    );

    ToastHelper.success('Registration successful');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    
    state = const AuthState(isInitialized: true); // Reset to initial state but keep initialized
  }
}

// Provider for authentication management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});