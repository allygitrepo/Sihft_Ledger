import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_assets.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late GlobalKey<FormState> formKey;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
  }

  Future<void> _handleLogin() async {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final authNotifier = ref.read(authProvider.notifier);

      await authNotifier.login();

      final authState = ref.read(authProvider);

      if (authState.isLoggedIn && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final isDesktop = screenWidth > 900;

    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: isDesktop
                ? _buildDesktopLayout(context, authState)
                : _buildMobileLayout(context, screenHeight, padding, authState),
          ),
          // Full screen loader
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: AppLoader(size: 80)),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double screenHeight,
    EdgeInsets padding,
    dynamic authState,
  ) {
    return SafeArea(
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Sign in to your account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  ..._buildFormFields(context, screenHeight, authState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, dynamic authState) {
    return Row(
      children: [
        // Left side - White background with logo and app name
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.appLogo, height: 200, width: 200),
                  const SizedBox(height: 24),
                  Text(
                    'ShiftLedger',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manage your workforce efficiently',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Primary color background with login form
        Expanded(
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        ..._buildFormFields(
                          context,
                          MediaQuery.of(context).size.height,
                          authState,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields(
    BuildContext context,
    double screenHeight,
    dynamic authState,
  ) {
    return [
      // Mobile Number Field
      TextFormField(
        onChanged: (value) => ref.read(authProvider.notifier).setPhone(value),
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(),
          counterText: '',
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
        onChanged: (value) =>
            ref.read(authProvider.notifier).setPassword(value),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
        onPressed: authState.isLoading ? null : _handleLogin,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text('Login'),
        ),
      ),
      SizedBox(height: screenHeight * 0.02),

      // Register Link
      Center(
        child: TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.register),
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
      ),
    ];
  }
}
