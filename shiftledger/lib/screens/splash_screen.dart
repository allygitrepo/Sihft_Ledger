import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_assets.dart';
import '../utills/app_theme.dart';
import '../widgets/loader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  void _checkSetupStatus() async {
    // Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Wait for setup provider to initialize
    while (ref.read(setupProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    
    // Always navigate to login screen
    // Users can navigate to register from login if they're new
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.appGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppAssets.appLogo,
                      height: AppAssets.logoSizeSplash,
                      width: AppAssets.logoSizeSplash,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ShiftLedger',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const AppLoader(size: 50),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Image.asset(
                    isDarkMode
                        ? AppAssets.allyLogoDark
                        : AppAssets.allyLogoLight,
                    height: AppAssets.allyLogoHeight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Developed by AllySOFT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}