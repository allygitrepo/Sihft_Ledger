import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/company_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_assets.dart';
import '../utills/app_spacing.dart';
import '../widgets/loader.dart';

class CompanyRegisterScreen extends ConsumerStatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  ConsumerState<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends ConsumerState<CompanyRegisterScreen> {
  late GlobalKey<FormState> formKey;
  
  // Industry types
  final List<String> industryTypes = [
    'Manufacturing',
    'Textile',
    'Construction',
    'IT',
    'Retail',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await ref.read(companyProvider.notifier).setCompanyPhoto(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      final success = await ref.read(companyProvider.notifier).registerCompany();
      
      if (success && mounted) {
        // Navigate to salary configuration for first-time setup
        Navigator.pushReplacementNamed(
          context,
          '/salary-configuration',
          arguments: {'isFirstTimeSetup': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final companyState = ref.watch(companyProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Company Details'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.getMaxFormWidth(context),
                      minHeight: screenHeight - padding.top - 48,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo/Title
                          Image.asset(
                            AppAssets.appLogo,
                            height: AppAssets.logoSizeAuth,
                            width: AppAssets.logoSizeAuth,
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          Text(
                            'Company Registration',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Step 2 of 2',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.06),

                          // Company Photo Upload
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: companyState.photoFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          companyState.photoFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Company Logo',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          if (companyState.photoFile != null)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  ref.read(companyProvider.notifier).clearCompanyPhoto();
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Remove Photo'),
                              ),
                            ),
                          SizedBox(height: screenHeight * 0.04),

                          // Company Name Field
                          TextFormField(
                            onChanged: (value) => ref.read(companyProvider.notifier).setCompanyName(value),
                            decoration: const InputDecoration(
                              labelText: 'Company Name *',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter company name';
                              }
                              if (value.length < 2) {
                                return 'Company name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Industry Type Dropdown
                          DropdownButtonFormField<String>(
                            value: companyState.industryType.isEmpty ? null : companyState.industryType,
                            decoration: const InputDecoration(
                              labelText: 'Industry Type *',
                              prefixIcon: Icon(Icons.factory),
                              border: OutlineInputBorder(),
                            ),
                            items: industryTypes.map((String industry) {
                              return DropdownMenuItem<String>(
                                value: industry,
                                child: Text(industry),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(companyProvider.notifier).setIndustryType(value);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select industry type';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Company Address Field
                          TextFormField(
                            onChanged: (value) => ref.read(companyProvider.notifier).setAddress(value),
                            decoration: const InputDecoration(
                              labelText: 'Company Address (Optional)',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                          SizedBox(height: screenHeight * 0.04),

                          // Register Button
                          ElevatedButton(
                            onPressed: companyState.isLoading ? null : _handleRegister,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('Complete Registration'),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Required fields note
                          Text(
                            '* Required fields',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Full screen loader
          if (companyState.isLoading)
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
