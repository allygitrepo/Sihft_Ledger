import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftledger/routes/app_routes.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../utills/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final payrollSettings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        const Text(
          'Payroll Configuration',
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
                leading: const Icon(Icons.calendar_today),
                title: const Text('Attendance Type'),
                subtitle: Text(_getAttendanceTypeLabel(payrollSettings.attendanceType)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAttendanceTypeDialog(context, settingsNotifier, payrollSettings),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Overtime Multiplier'),
                subtitle: Text('${payrollSettings.overtimeMultiplier}x'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showOvertimeMultiplierDialog(context, settingsNotifier, payrollSettings),
              ),
              if (payrollSettings.attendanceType == AttendanceType.hourly)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Minimum Hours per Day'),
                  subtitle: Text('${payrollSettings.minimumHours} hours'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showMinimumHoursDialog(context, settingsNotifier, payrollSettings),
                ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Salary Cycle'),
                subtitle: Text(_getSalaryCycleLabel(payrollSettings.salaryCycle)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSalaryCycleDialog(context, settingsNotifier, payrollSettings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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

  String _getAttendanceTypeLabel(AttendanceType type) {
    switch (type) {
      case AttendanceType.daily:
        return 'Daily Based';
      case AttendanceType.hourly:
        return 'Hourly Based';
      case AttendanceType.unit:
        return 'Unit Based';
    }
  }

  String _getSalaryCycleLabel(SalaryCycle cycle) {
    switch (cycle) {
      case SalaryCycle.monthly:
        return 'Monthly';
      case SalaryCycle.weekly:
        return 'Weekly';
      case SalaryCycle.custom:
        return 'Custom Range';
    }
  }

  void _showAttendanceTypeDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsModel current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Attendance Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AttendanceType>(
              title: const Text('Daily Based'),
              subtitle: const Text('Track by days present'),
              value: AttendanceType.daily,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<AttendanceType>(
              title: const Text('Hourly Based'),
              subtitle: const Text('Track by hours worked'),
              value: AttendanceType.hourly,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<AttendanceType>(
              title: const Text('Unit Based'),
              subtitle: const Text('Track by units produced'),
              value: AttendanceType.unit,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOvertimeMultiplierDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsModel current,
  ) {
    final controller = TextEditingController(
      text: current.overtimeMultiplier.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overtime Multiplier'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Multiplier (1.0 - 5.0)',
            hintText: '1.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                notifier.updateOvertimeMultiplier(value);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMinimumHoursDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsModel current,
  ) {
    final controller = TextEditingController(
      text: current.minimumHours.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minimum Hours per Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Hours (1.0 - 24.0)',
                hintText: '8',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is the standard working hours per day. Any hours beyond this will be considered overtime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                notifier.updateMinimumHours(value);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSalaryCycleDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsModel current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Salary Cycle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SalaryCycle>(
              title: const Text('Monthly'),
              value: SalaryCycle.monthly,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<SalaryCycle>(
              title: const Text('Weekly'),
              value: SalaryCycle.weekly,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<SalaryCycle>(
              title: const Text('Custom Range'),
              value: SalaryCycle.custom,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}