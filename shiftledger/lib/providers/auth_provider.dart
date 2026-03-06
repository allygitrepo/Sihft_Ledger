import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/toast.dart';
import '../services/api_service.dart';

// Auth state model
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isInitialized;
  final Map<String, dynamic>? userData;
  final String? token;
  final String ownerName;
  final String phone;
  final String? email;
  final String password;
  final String confirmPassword;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.isInitialized = false,
    this.userData,
    this.token,
    this.ownerName = '',
    this.phone = '',
    this.email,
    this.password = '',
    this.confirmPassword = '',
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isInitialized,
    Map<String, dynamic>? userData,
    String? token,
    String? ownerName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
      userData: userData ?? this.userData,
      token: token ?? this.token,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _tokenKey = 'auth_token';

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
      'owner_name': prefs.getString('user_name') ?? 'User',
      'phone': prefs.getString('user_phone') ?? '',
      'email': prefs.getString('user_email') ?? '',
    };
    final token = prefs.getString(_tokenKey);

    state = state.copyWith(
      isLoggedIn: true,
      isInitialized: true,
      userData: userData,
      token: token,
    );
  }

  // Setters for form fields
  void setOwnerName(String value) {
    state = state.copyWith(ownerName: value.trim());
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value.trim());
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
    if (state.phone.isEmpty || state.password.isEmpty) {
      ToastHelper.error('Please fill all fields');
      return;
    }

    state = state.copyWith(isLoading: true);

    final response = await ApiService.login(state.phone, state.password);

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      final token = response['token'];
      final user = response['user'];
      final ownerName = user['owner_name'] ?? 'User';

      // Save login state
      await prefs.setBool(_isLoggedInKey, true);

      if (token != null) {
        await prefs.setString(_tokenKey, token);
      }

      await prefs.setString('user_name', ownerName);
      await prefs.setString('user_phone', state.phone);
      if (state.email != null && state.email!.isNotEmpty) {
        await prefs.setString('user_email', state.email!);
      }

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        userData: user,
        token: token,
      );

      ToastHelper.success('Login successful');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Login failed');
    }
  }

  Future<void> register() async {
    if (state.ownerName.isEmpty ||
        state.phone.isEmpty ||
        state.password.isEmpty) {
      ToastHelper.error('Please fill all fields');
      return;
    }

    if (state.password != state.confirmPassword) {
      ToastHelper.error('Passwords do not match');
      return;
    }

    state = state.copyWith(isLoading: true);

    final response = await ApiService.register(
      ownerName: state.ownerName,
      phone: state.phone,
      email: state.email,
      password: state.password,
    );

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      final token = response['token'];
      final user = response['user'];

      // Save login state after registration
      await prefs.setBool(_isLoggedInKey, true);

      if (token != null) {
        await prefs.setString(_tokenKey, token);
      }

      await prefs.setString('user_name', state.ownerName);
      await prefs.setString('user_phone', state.phone);
      if (state.email != null && state.email!.isNotEmpty) {
        await prefs.setString('user_email', state.email!);
      }

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        userData: user,
        token: token,
      );

      ToastHelper.success('Registration successful');
    } else {
      state = state.copyWith(isLoading: false);
      ToastHelper.error(response['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_tokenKey);
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_email');

    state = const AuthState(
      isInitialized: true,
    ); // Reset to initial state but keep initialized
  }
}

// Provider for authentication management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
