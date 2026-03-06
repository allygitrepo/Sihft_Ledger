import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_spacing.dart';
import '../widgets/toast.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final companyState = ref.watch(companyProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              authState.userData?['owner_name'] ?? 'User',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              authState.userData?['email'] ??
                  authState.userData?['phone'] ??
                  '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Information Cards - Responsive Layout
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPersonalInfoCard(context, authState),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildCompanyInfoCard(context, companyState),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildPersonalInfoCard(context, authState),
                      const SizedBox(height: 16),
                      _buildCompanyInfoCard(context, companyState),
                    ],
                  ),

            const SizedBox(height: 32),

            // Action Buttons in a Row
            SizedBox(
              width: isDesktop ? 600 : double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ToastHelper.show('Edit profile feature coming soon!');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
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
                          // Clear auth and company data
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
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, AuthState authState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Full Name',
              value: authState.userData?['owner_name'] ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.phone,
              label: 'Mobile Number',
              value: authState.userData?['phone'] ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: 'Email Address',
              value: authState.userData?['email'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard(
    BuildContext context,
    CompanyState companyState,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Company Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              icon: Icons.business_center,
              label: 'Company Name',
              value: companyState.company?.companyName ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.category,
              label: 'Industry Type',
              value: companyState.company?.industryType ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'Address',
              value: companyState.company?.address ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
