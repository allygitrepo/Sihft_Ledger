import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar_navigation.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;
  final String title;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.title = '',
  });

  String _getPageTitle(String route) {
    switch (route) {
      case '/employees':
        return 'Employees';
      case '/attendance':
        return 'Mark Attendance';
      case '/payroll':
        return 'Payroll';
      case '/salary-configuration':
        return 'Salary Configuration';
      case '/overtime-configuration':
        return 'Overtime Configuration';
      case '/payroll-configuration':
        return 'Payroll Configuration';
      case '/profile':
        return 'Profile';
      case '/settings':
        return 'Settings';
      case '/about-us':
        return 'About Us';
      case '/departments':
        return 'Departments';
      case '/designations':
        return 'Designations';
      default:
        return title;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final dividerColor = theme.dividerColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    if (!isDesktop) {
      // Mobile: Return child as-is (it has its own AppBar)
      return child;
    }

    // Desktop/Tablet: Show sidebar with AppBar
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Use existing SidebarNavigation widget
          const SidebarNavigation(),

          // Main Content with AppBar
          Expanded(
            child: Column(
              children: [
                // AppBar
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(
                      bottom: BorderSide(color: dividerColor, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(currentRoute),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      // Profile icon
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
