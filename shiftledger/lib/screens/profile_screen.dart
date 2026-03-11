import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_spacing.dart';
import '../utills/validator.dart';
import '../utills/image_converter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;

  // Personal Info Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Company Info Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _industryTypeController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authState = ref.read(authProvider);
    final companyState = ref.read(companyProvider);

    // Personal Info
    _nameController = TextEditingController(
      text: authState.userData?['owner_name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: authState.userData?['phone'] ?? '',
    );
    _emailController = TextEditingController(
      text: authState.userData?['email'] ?? '',
    );

    // Company Info
    _companyNameController = TextEditingController(
      text: companyState.company?.companyName ?? '',
    );
    _industryTypeController = TextEditingController(
      text: companyState.company?.industryType ?? '',
    );
    _addressController = TextEditingController(
      text: companyState.company?.address ?? '',
    );
    _selectedImageBytes = null;
    _selectedImageExtension = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _industryTypeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final companyState = ref.read(companyProvider);

    // Update personal info
    await ref.read(authProvider.notifier).updateProfile(
          ownerName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );

    // Update company info if company exists
    if (companyState.company != null) {
      String? companyPhoto = companyState.company?.companyPhoto;
      
      if (_selectedImageBytes != null && _selectedImageExtension != null) {
        companyPhoto = ImageConverter.toBase64(
          _selectedImageBytes!, 
          _selectedImageExtension!,
        );
      }

      await ref.read(companyProvider.notifier).updateCompany(
            companyName: _companyNameController.text.trim(),
            industryType: _industryTypeController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            companyPhoto: companyPhoto,
          );
    }

    setState(() {
      _isEditMode = false;
    });
  }

  void _cancelEdit() {
    // Reset controllers to original values
    _initializeControllers();
    setState(() {
      _isEditMode = false;
      _selectedImageBytes = null;
      _selectedImageExtension = null;
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditMode) return;
    
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedImageExtension = result.files.single.extension ?? 'png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final companyState = ref.watch(companyProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isLoading = authState.isLoading || companyState.isLoading;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Company Logo or Default Avatar
              _buildProfileAvatar(context, companyState),
              const SizedBox(height: 12),
              Text(
                authState.userData?['owner_name'] ?? 'User',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                authState.userData?['email'] ??
                    authState.userData?['phone'] ??
                    '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Information Cards - Responsive Layout
              isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildPersonalInfoCard(context, isLoading),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildCompanyInfoCard(
                              context,
                              companyState,
                              isLoading,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildPersonalInfoCard(context, isLoading),
                        const SizedBox(height: 16),
                        _buildCompanyInfoCard(context, companyState, isLoading),
                      ],
                    ),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: isDesktop ? 600 : double.infinity,
                child: _isEditMode
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _saveProfile,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(isLoading ? 'Saving...' : 'Save'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(0, 50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _cancelEdit,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(0, 50),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditMode = true;
                                });
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldLogout == true) {
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, bool isLoading) {
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              context: context,
              icon: Icons.person,
              label: 'Full Name',
              controller: _nameController,
              validator: (value) => AppValidator.validateName(value, 'Name'),
              enabled: _isEditMode && !isLoading,
            ),
            const Divider(height: 24),
            _buildEditableField(
              context: context,
              icon: Icons.phone,
              label: 'Mobile Number',
              controller: _phoneController,
              validator: (value) =>
                  AppValidator.validatePhoneNumber(value, 'Mobile Number'),
              keyboardType: TextInputType.phone,
              enabled: _isEditMode && !isLoading,
            ),
            const Divider(height: 24),
            _buildEditableField(
              context: context,
              icon: Icons.email,
              label: 'Email Address (Optional)',
              controller: _emailController,
              validator: (value) => AppValidator.validateEmail(value),
              keyboardType: TextInputType.emailAddress,
              enabled: _isEditMode && !isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard(
    BuildContext context,
    CompanyState companyState,
    bool isLoading,
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              context: context,
              icon: Icons.business_center,
              label: 'Company Name',
              controller: _companyNameController,
              validator: (value) =>
                  AppValidator.validateName(value, 'Company Name'),
              enabled: _isEditMode && !isLoading,
            ),
            const Divider(height: 24),
            _buildEditableField(
              context: context,
              icon: Icons.category,
              label: 'Industry Type',
              controller: _industryTypeController,
              validator: (value) =>
                  AppValidator.validateName(value, 'Industry Type'),
              enabled: _isEditMode && !isLoading,
            ),
            const Divider(height: 24),
            _buildEditableField(
              context: context,
              icon: Icons.location_on,
              label: 'Address (Optional)',
              controller: _addressController,
              validator: null,
              maxLines: 2,
              enabled: _isEditMode && !isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, CompanyState companyState) {
    return GestureDetector(
      onTap: _isEditMode ? _pickImage : null,
      child: Stack(
        children: [
          _buildAvatarImage(context, companyState),
          if (_isEditMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context, CompanyState companyState) {
    if (_selectedImageBytes != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            _selectedImageBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final companyPhoto = companyState.company?.companyPhoto;
    
    if (companyPhoto != null && companyPhoto.isNotEmpty) {
      // Show company logo if available
      try {
        final imageBytes = ImageConverter.fromBase64(companyPhoto);
        if (imageBytes != null) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(context);
                },
              ),
            ),
          );
        }
      } catch (e) {
        return _buildDefaultAvatar(context);
      }
    }
    
    // Show default avatar if no company logo
    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.business, size: 60, color: Colors.white),
    );
  }

  Widget _buildEditableField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool enabled,
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
              if (_isEditMode)
                TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  enabled: enabled,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: enabled ? null : Colors.grey[100],
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  controller.text.isEmpty ? 'N/A' : controller.text,
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
