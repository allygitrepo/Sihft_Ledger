import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_model.dart';
import '../providers/settings_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/overtime_provider.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';
import '../widgets/toast.dart';

class OvertimeConfigurationScreen extends ConsumerStatefulWidget {
  const OvertimeConfigurationScreen({super.key});

  @override
  ConsumerState<OvertimeConfigurationScreen> createState() =>
      _OvertimeConfigurationScreenState();
}

class _OvertimeConfigurationScreenState
    extends ConsumerState<OvertimeConfigurationScreen> {
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

      // Apply hour-wise configuration to all current employees using existing route
      if (selectedOvertimeType == OvertimeType.hourwise && overtimeEnabled) {
        final employees = ref.read(employeeProvider).employees;
        final overtimeHelper = ref.read(overtimeProvider.notifier);

        for (var emp in employees) {
          await overtimeHelper.saveEmployeeConfig(
            employeeId: emp.id,
            overtimeEnabled: overtimeEnabled,
            hourlyRate: double.parse(overtimeRateController.text),
          );
        }
      }

      setState(() => isLoading = false);

      if (mounted) {
        ToastHelper.success('Overtime configuration saved successfully');
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
          : AppBar(title: const Text('Overtime Configuration')),
      body: Stack(
        children: [
          isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context, screenHeight),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: AppLoader(size: 80)),
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
              children: _buildFormContent(
                context,
                MediaQuery.of(context).size.height,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(BuildContext context, double screenHeight) {
    return [
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
      const SizedBox(height: 24),

      if (overtimeEnabled) ...[
        // Overtime Type
        Text(
          'Overtime Calculation Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        const SizedBox(height: 24),

        // Default Overtime Rate
        if (selectedOvertimeType == OvertimeType.hourwise) ...[
          Text(
            'Default Overtime Rate',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
        ],
      ],

      // Save Button
      ElevatedButton(
        onPressed: isLoading ? null : _handleSave,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Save Overtime Configuration'),
        ),
      ),

      const SizedBox(height: 16),
    ];
  }
}
