import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/owner_service.dart';
import '../routes/app_routes.dart';
import '../utills/app_assets.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late GlobalKey<FormState> formKey;
  bool isPasswordVisible = false;
  bool isLoading = false;
  
  String mobileNumber = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
  }

  Future<void> _handleLogin() async {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      setState(() => isLoading = true);
      
      // Check if owner exists
      final hasOwner = await OwnerService.hasOwner();
      
      if (!hasOwner) {
        setState(() => isLoading = false);
        ToastHelper.error('No account found. Please register first.');
        return;
      }
      
      // Validate credentials
      final isValid = await OwnerService.validateLogin(mobileNumber, password);
      
      if (isValid) {
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        
        setState(() => isLoading = false);
        
        if (mounted) {
          ToastHelper.success('Login successful');
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        setState(() => isLoading = false);
        ToastHelper.error('Invalid mobile number or password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.getMaxFormWidth(context),
                      minHeight: screenHeight - padding.top - 48,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo/Title
                          Image.asset(
                            AppAssets.appLogo,
                            height: AppAssets.logoSizeAuth,
                            width: AppAssets.logoSizeAuth,
                          ),
                          Text(
                            'Welcome Back',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Sign in to your account',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.06),

                          // Mobile Number Field
                          TextFormField(
                            onChanged: (value) => mobileNumber = value.trim(),
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter mobile number';
                              }
                              if (value.length != 10) {
                                return 'Mobile number must be 10 digits';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Please enter valid mobile number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Password Field
                          TextFormField(
                            onChanged: (value) => password = value,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                }),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: !isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.04),

                          // Login Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('Login'),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Register Link
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Full screen loader
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: AppLoader(size: 80),
              ),
            ),
        ],
      ),
    );
  }
}