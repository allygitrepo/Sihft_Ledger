import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../utills/app_spacing.dart';
import '../widgets/toast.dart';

class PayrollConfigurationScreen extends ConsumerWidget {
  const PayrollConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollSettings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Payroll Configuration'),
              centerTitle: true,
            ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payroll Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure payroll calculation and salary cycle settings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Attendance Type
          Text(
            'Attendance Tracking',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Attendance Type'),
              subtitle: Text(_getAttendanceTypeLabel(payrollSettings.attendanceType)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAttendanceTypeDialog(context, settingsNotifier, payrollSettings),
            ),
          ),
          const SizedBox(height: 20),
          
          // Overtime Settings
          Text(
            'Overtime Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Overtime Multiplier'),
              subtitle: Text('${payrollSettings.overtimeMultiplier}x'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showOvertimeMultiplierDialog(context, settingsNotifier, payrollSettings),
            ),
          ),
          const SizedBox(height: 20),
          
          // Working Hours
          if (payrollSettings.attendanceType == PayrollAttendanceType.hourly) ...[
            Text(
              'Working Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Minimum Hours per Day'),
                subtitle: Text('${payrollSettings.minimumHours} hours'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showMinimumHoursDialog(context, settingsNotifier, payrollSettings),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Salary Cycle
          Text(
            'Salary Cycle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Salary Cycle'),
              subtitle: Text(_getSalaryCycleLabel(payrollSettings.salaryCycle)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSalaryCycleDialog(context, settingsNotifier, payrollSettings),
            ),
          ),
        ],
      ),
    );
  }

  String _getAttendanceTypeLabel(PayrollAttendanceType type) {
    switch (type) {
      case PayrollAttendanceType.daily:
        return 'Daily Based';
      case PayrollAttendanceType.hourly:
        return 'Hourly Based';
      case PayrollAttendanceType.unit:
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
            RadioListTile<PayrollAttendanceType>(
              title: const Text('Daily Based'),
              subtitle: const Text('Track by days present'),
              value: PayrollAttendanceType.daily,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Attendance type updated');
                }
              },
            ),
            RadioListTile<PayrollAttendanceType>(
              title: const Text('Hourly Based'),
              subtitle: const Text('Track by hours worked'),
              value: PayrollAttendanceType.hourly,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Attendance type updated');
                }
              },
            ),
            RadioListTile<PayrollAttendanceType>(
              title: const Text('Unit Based'),
              subtitle: const Text('Track by units produced'),
              value: PayrollAttendanceType.unit,
              groupValue: current.attendanceType,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateAttendanceType(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Attendance type updated');
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
            helperText: 'Overtime pay = Regular pay × Multiplier',
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
              'Standard working hours per day. Hours beyond this will be considered overtime.',
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
              subtitle: const Text('Pay once per month'),
              value: SalaryCycle.monthly,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Salary cycle updated');
                }
              },
            ),
            RadioListTile<SalaryCycle>(
              title: const Text('Weekly'),
              subtitle: const Text('Pay once per week'),
              value: SalaryCycle.weekly,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Salary cycle updated');
                }
              },
            ),
            RadioListTile<SalaryCycle>(
              title: const Text('Custom Range'),
              subtitle: const Text('Custom date range'),
              value: SalaryCycle.custom,
              groupValue: current.salaryCycle,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSalaryCycle(value);
                  Navigator.of(context).pop();
                  ToastHelper.success('Salary cycle updated');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
