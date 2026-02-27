import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_model.dart';
import '../providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';

class OvertimeConfigurationScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeSetup;
  
  const OvertimeConfigurationScreen({
    super.key,
    this.isFirstTimeSetup = false,
  });

  @override
  ConsumerState<OvertimeConfigurationScreen> createState() => _OvertimeConfigurationScreenState();
}

class _OvertimeConfigurationScreenState extends ConsumerState<OvertimeConfigurationScreen> {
  late GlobalKey<FormState> formKey;
  late bool overtimeEnabled;
  late OvertimeType selectedOvertimeType;
  late TextEditingController overtimeRateController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    
    final settings = ref.read(settingsProvider);
    overtimeEnabled = settings.overtimeEnabled;
    selectedOvertimeType = settings.defaultOvertimeType;
    overtimeRateController = TextEditingController(
      text: settings.defaultOvertimeRate.toString(),
    );
  }

  @override
  void dispose() {
    overtimeRateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final settings = ref.read(settingsProvider);
      final updatedSettings = settings.copyWith(
        overtimeEnabled: overtimeEnabled,
        defaultOvertimeType: selectedOvertimeType,
        defaultOvertimeRate: double.parse(overtimeRateController.text),
      );

      await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

      setState(() => isLoading = false);

      if (mounted) {
        ToastHelper.success('Overtime configuration saved successfully');
        
        if (widget.isFirstTimeSetup) {
          // Navigate to login after first-time setup
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
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
        title: const Text('Overtime Configuration'),
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
                              Icons.timer,
                              size: 48,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Overtime Setup',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure overtime calculation rules for your company',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],

                  // Overtime Enabled
                  Card(
                    child: SwitchListTile(
                      title: const Text('Enable Overtime'),
                      subtitle: const Text('Allow overtime calculation for employees'),
                      value: overtimeEnabled,
                      onChanged: (value) {
                        setState(() => overtimeEnabled = value);
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  if (overtimeEnabled) ...[
                    // Overtime Type
                    Text(
                      'Overtime Calculation Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<OvertimeType>(
                            title: const Text('Hour-wise Overtime'),
                            subtitle: const Text('Pay per overtime hour worked'),
                            value: OvertimeType.hourwise,
                            groupValue: selectedOvertimeType,
                            onChanged: (value) {
                              setState(() => selectedOvertimeType = value!);
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<OvertimeType>(
                            title: const Text('Slot-wise Overtime'),
                            subtitle: const Text('Pay based on overtime hour slots'),
                            value: OvertimeType.slotwise,
                            groupValue: selectedOvertimeType,
                            onChanged: (value) {
                              setState(() => selectedOvertimeType = value!);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Default Overtime Rate
                    if (selectedOvertimeType == OvertimeType.hourwise) ...[
                      Text(
                        'Default Overtime Rate',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: overtimeRateController,
                        decoration: const InputDecoration(
                          labelText: 'Rate per hour',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                          helperText: 'Default rate for overtime hours',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter overtime rate';
                          }
                          final rate = double.tryParse(value);
                          if (rate == null || rate <= 0) {
                            return 'Please enter valid rate';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],

                    // Slot Configuration Button
                    if (selectedOvertimeType == OvertimeType.slotwise) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Manage Overtime Slots'),
                          subtitle: const Text('Configure overtime hour slots and rates'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(context, '/overtime-slots');
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ],

                  // Save Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSave,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        widget.isFirstTimeSetup
                            ? 'Complete Setup'
                            : 'Save Overtime Configuration',
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
