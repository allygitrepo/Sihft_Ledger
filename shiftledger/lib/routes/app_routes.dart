import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/company_register_screen.dart';
import '../screens/salary_configuration_screen.dart';
import '../screens/overtime_configuration_screen.dart';
import '../screens/overtime_slots_screen.dart';
import '../screens/payroll_configuration_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/payroll_screen.dart';
import '../layouts/main_layout.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String companyRegister = '/company-register';
  static const String salaryConfiguration = '/salary-configuration';
  static const String overtimeConfiguration = '/overtime-configuration';
  static const String overtimeSlots = '/overtime-slots';
  static const String payrollConfiguration = '/payroll-configuration';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String aboutUs = '/about-us';
  static const String employees = '/employees';
  static const String attendance = '/attendance';
  static const String payroll = '/payroll';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    companyRegister: (context) => const CompanyRegisterScreen(),
    payrollConfiguration: (context) => const PayrollConfigurationScreen(),
    dashboard: (context) => const DashboardScreen(),
    profile: (context) => _wrapWithLayout(const ProfileScreen(), profile),
    settings: (context) => _wrapWithLayout(const SettingsScreen(), settings),
    aboutUs: (context) => _wrapWithLayout(const AboutUsScreen(), aboutUs),
    employees: (context) => _wrapWithLayout(const EmployeesScreen(), employees),
    attendance: (context) => _wrapWithLayout(const AttendanceScreen(), attendance),
    payroll: (context) => _wrapWithLayout(const PayrollScreen(), payroll),
  };

  static Widget _wrapWithLayout(Widget child, String route) {
    return MainLayout(
      currentRoute: route,
      child: child,
    );
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle routes with arguments
    if (settings.name == salaryConfiguration) {
      final args = settings.arguments as Map<String, dynamic>?;
      final isFirstTimeSetup = args?['isFirstTimeSetup'] ?? false;
      return MaterialPageRoute(
        builder: (context) => SalaryConfigurationScreen(
          isFirstTimeSetup: isFirstTimeSetup,
        ),
        settings: settings,
      );
    }
    
    if (settings.name == overtimeConfiguration) {
      final args = settings.arguments as Map<String, dynamic>?;
      final isFirstTimeSetup = args?['isFirstTimeSetup'] ?? false;
      return MaterialPageRoute(
        builder: (context) => OvertimeConfigurationScreen(
          isFirstTimeSetup: isFirstTimeSetup,
        ),
        settings: settings,
      );
    }
    
    if (settings.name == overtimeSlots) {
      return MaterialPageRoute(
        builder: (context) => const OvertimeSlotsScreen(),
        settings: settings,
      );
    }

    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }
}