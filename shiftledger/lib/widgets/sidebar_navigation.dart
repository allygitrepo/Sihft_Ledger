import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_colors.dart';

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'ShiftLedger',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.userData?['name'] ?? 'User',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
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
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 2,
                  isSelected: currentIndex == 2,
                ),
                const Divider(height: 24),
                _buildMenuTile(
                  context: context,
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),
                _buildMenuTile(
                  context: context,
                  icon: Icons.info,
                  label: 'About Us',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.aboutUs);
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
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label),
      onTap: onTap,
    );
  }
}
