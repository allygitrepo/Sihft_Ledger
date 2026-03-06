import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../routes/app_routes.dart';
import '../utills/image_converter.dart';
import '../utills/app_colors.dart';

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final companyState = ref.watch(companyProvider);
    final company = companyState.company;

    return Material(
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: company?.companyPhoto != null
                        ? Image.memory(
                            ImageConverter.fromBase64(company!.companyPhoto)!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/shiftledger.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if image fails to load
                              return const Icon(
                                Icons.account_balance_wallet,
                                size: 48,
                                color: AppColors.primary,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    company?.companyName ?? 'ShiftLedger',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authState.userData?['name'] ?? 'User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuTile(
                    context: context,
                    icon: Icons.home,
                    label: 'Home',
                    onTap: () {
                      // Reset navigation index and go to dashboard
                      ref.read(navigationProvider.notifier).setIndex(0);
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.dashboard,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'MANAGEMENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.people,
                    label: 'Employees',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.employees,
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.business,
                    label: 'Departments',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.departments,
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.badge,
                    label: 'Designations',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.designations,
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.access_time,
                    label: 'Attendance',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.attendance,
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.payment,
                    label: 'Payroll',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.payroll,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'CONFIGURATION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.account_balance_wallet,
                    label: 'Salary Configuration',
                    onTap: () {
                      Navigator.pushNamed(context, '/salary-configuration');
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.timer,
                    label: 'Overtime Configuration',
                    onTap: () {
                      Navigator.pushNamed(context, '/overtime-configuration');
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      // Reset navigation index and go to dashboard settings
                      ref.read(navigationProvider.notifier).setIndex(2);
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.dashboard,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'ACCOUNT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.profile,
                      );
                    },
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.info,
                    label: 'About Us',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.aboutUs,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildMenuTile(
              context: context,
              icon: Icons.logout,
              label: 'Logout',
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color ?? Colors.grey[600];

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      onTap: onTap,
    );
  }
}
