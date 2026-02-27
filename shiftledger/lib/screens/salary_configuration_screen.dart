import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';

class SalaryConfigurationScreen extends ConsumerStatefulWidget {
  const SalaryConfigurationScreen({
    super.key,
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
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Salary Configuration'),
            ),
      body: Stack(
        children: [
          isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context, screenHeight),
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

  Widget _buildMobileLayout(BuildContext context, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFormContent(context, screenHeight),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    // Show simple centered form
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildFormContent(context, MediaQuery.of(context).size.height),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(BuildContext context, double screenHeight) {
    return [
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
      const SizedBox(height: 24),

      // Fixed Working Hours and Days in a Row
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Working Hours Per Day
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours Per Day',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fixedHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null || hours <= 0 || hours > 24) {
                      return 'Invalid (1-24)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Working Days Per Month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Days Per Month',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: workingDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Days',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days <= 0 || days > 31) {
                      return 'Invalid (1-31)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Salary Input Type
      Text(
        'Salary Input Type',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedInputType = SalaryInputType.monthly),
                  child: Row(
                    children: [
                      Radio<SalaryInputType>(
                        value: SalaryInputType.monthly,
                        groupValue: selectedInputType,
                        onChanged: (value) {
                          setState(() => selectedInputType = value!);
                        },
                      ),
                      const Expanded(
                        child: Text('Monthly'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedInputType = SalaryInputType.daily),
                  child: Row(
                    children: [
                      Radio<SalaryInputType>(
                        value: SalaryInputType.daily,
                        groupValue: selectedInputType,
                        onChanged: (value) {
                          setState(() => selectedInputType = value!);
                        },
                      ),
                      const Expanded(
                        child: Text('Daily'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedInputType = SalaryInputType.hourly),
                  child: Row(
                    children: [
                      Radio<SalaryInputType>(
                        value: SalaryInputType.hourly,
                        groupValue: selectedInputType,
                        onChanged: (value) {
                          setState(() => selectedInputType = value!);
                        },
                      ),
                      const Expanded(
                        child: Text('Hourly'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),

      // Save Button
      ElevatedButton(
        onPressed: isLoading ? null : _handleSave,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Save Salary Configuration'),
        ),
      ),
      
      const SizedBox(height: 16),
    ];
  }
}
