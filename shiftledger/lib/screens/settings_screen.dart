import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftledger/routes/app_routes.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              RadioListTile<AppThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme'),
                value: AppThemeMode.system,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.changeThemeMode(value);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Light theme'),
                value: AppThemeMode.light,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.changeThemeMode(value);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Dark theme'),
                value: AppThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.changeThemeMode(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About ShiftLedger'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Version: 1.0.0'),
                          SizedBox(height: 8),
                          Text('© 2024 AllySOFT'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service coming soon!')),
                  );
                },
              ),
               ListTile(
            leading: const Icon(Icons.add_business_outlined),
            title: const Text("About Us"),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.aboutUs);
            },
          ),
            ],
          ),
        ),
      ],
    );
  }
}