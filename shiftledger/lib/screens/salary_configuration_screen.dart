import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';

class SalaryConfigurationScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeSetup;
  
  const SalaryConfigurationScreen({
    super.key,
    this.isFirstTimeSetup = false,
  });

  @override
  ConsumerState<SalaryConfigurationScreen> createState() => _SalaryConfigurationScreenState();
}

class _SalaryConfigurationScreenState extends ConsumerState<SalaryConfigurationScreen> {
  late GlobalKey<FormState> formKey;
  late DefaultSalaryType selectedSalaryType;
  late SalaryInputType selectedInputType;
  late TextEditingController fixedHoursController;
  late TextEditingController workingDaysController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    
    final settings = ref.read(settingsProvider);
    selectedSalaryType = settings.defaultSalaryType;
    selectedInputType = settings.salaryInputType;
    fixedHoursController = TextEditingController(
      text: settings.fixedHoursPerDay.toString(),
    );
    workingDaysController = TextEditingController(
      text: settings.workingDaysPerMonth.toString(),
    );
  }

  @override
  void dispose() {
    fixedHoursController.dispose();
    workingDaysController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final settings = ref.read(settingsProvider);
      final updatedSettings = settings.copyWith(
        defaultSalaryType: selectedSalaryType,
        fixedHoursPerDay: double.parse(fixedHoursController.text),
        workingDaysPerMonth: int.parse(workingDaysController.text),
        salaryInputType: selectedInputType,
      );

      await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

      setState(() => isLoading = false);

      if (mounted) {
        ToastHelper.success('Salary configuration saved successfully');
        
        if (widget.isFirstTimeSetup) {
          // Navigate to overtime configuration
          Navigator.pushReplacementNamed(context, '/overtime-configuration',
              arguments: {'isFirstTimeSetup': true});
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Configuration'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isFirstTimeSetup) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Initial Setup',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure how salary will be calculated in your company',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],

                  // Salary Calculation Method
                  Text(
                    'Salary Calculation Method',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<DefaultSalaryType>(
                          title: const Text('Hour-wise Salary'),
                          subtitle: const Text('Salary calculated based on hours worked'),
                          value: DefaultSalaryType.hourwise,
                          groupValue: selectedSalaryType,
                          onChanged: (value) {
                            setState(() => selectedSalaryType = value!);
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<DefaultSalaryType>(
                          title: const Text('Day-wise Salary'),
                          subtitle: const Text('Salary calculated based on days worked'),
                          value: DefaultSalaryType.daywise,
                          groupValue: selectedSalaryType,
                          onChanged: (value) {
                            setState(() => selectedSalaryType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Fixed Working Hours Per Day
                  Text(
                    'Fixed Working Hours Per Day',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fixedHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours per day',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                      helperText: 'Used for salary and overtime calculation',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter fixed hours';
                      }
                      final hours = double.tryParse(value);
                      if (hours == null || hours <= 0 || hours > 24) {
                        return 'Please enter valid hours (1-24)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Working Days Per Month
                  Text(
                    'Working Days Per Month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: workingDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Days per month',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      helperText: 'Used for monthly salary conversion',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter working days';
                      }
                      final days = int.tryParse(value);
                      if (days == null || days <= 0 || days > 31) {
                        return 'Please enter valid days (1-31)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Salary Input Type
                  Text(
                    'Salary Input Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<SalaryInputType>(
                          title: const Text('Monthly Salary'),
                          subtitle: const Text('Enter salary as monthly amount'),
                          value: SalaryInputType.monthly,
                          groupValue: selectedInputType,
                          onChanged: (value) {
                            setState(() => selectedInputType = value!);
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<SalaryInputType>(
                          title: const Text('Daily Salary'),
                          subtitle: const Text('Enter salary as daily amount'),
                          value: SalaryInputType.daily,
                          groupValue: selectedInputType,
                          onChanged: (value) {
                            setState(() => selectedInputType = value!);
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<SalaryInputType>(
                          title: const Text('Hourly Salary'),
                          subtitle: const Text('Enter salary as hourly rate'),
                          value: SalaryInputType.hourly,
                          groupValue: selectedInputType,
                          onChanged: (value) {
                            setState(() => selectedInputType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // Save Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSave,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        widget.isFirstTimeSetup
                            ? 'Continue to Overtime Configuration'
                            : 'Save Salary Configuration',
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: AppLoader(size: 80),
              ),
            ),
        ],
      ),
    );
  }
}
