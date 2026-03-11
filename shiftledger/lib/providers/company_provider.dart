import 'dart:io';
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';
import '../services/setup_service.dart';
import '../widgets/toast.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utills/image_converter.dart';

// Company state model
class CompanyState {
  final bool isLoading;
  final CompanyModel? company;
  final String companyName;
  final String industryType;
  final String? address;
  final String? companyPhoto; // Base64 string
  final File? photoFile; // Temporary file for preview
  final Uint8List? photoBytes; // Bytes fallback for web/desktop

  const CompanyState({
    this.isLoading = false,
    this.company,
    this.companyName = '',
    this.industryType = '',
    this.address,
    this.companyPhoto,
    this.photoFile,
    this.photoBytes,
  });

  CompanyState copyWith({
    bool? isLoading,
    CompanyModel? company,
    String? companyName,
    String? industryType,
    String? address,
    String? companyPhoto,
    File? photoFile,
    Uint8List? photoBytes,
  }) {
    return CompanyState(
      isLoading: isLoading ?? this.isLoading,
      company: company ?? this.company,
      companyName: companyName ?? this.companyName,
      industryType: industryType ?? this.industryType,
      address: address ?? this.address,
      companyPhoto: companyPhoto ?? this.companyPhoto,
      photoFile: photoFile ?? this.photoFile,
      photoBytes: photoBytes ?? this.photoBytes,
    );
  }
}

class CompanyNotifier extends StateNotifier<CompanyState> {
  final Ref ref;
  CompanyNotifier(this.ref) : super(const CompanyState()) {
    _checkAndLoadCompany();
  }

  Future<void> _checkAndLoadCompany() async {
    final company = await CompanyService.loadCompany();
    if (company != null) {
      // Decode image for preview if available
      Uint8List? decodedBytes;
      if (company.companyPhoto != null) {
        decodedBytes = ImageConverter.fromBase64(company.companyPhoto!);
      }
      state = state.copyWith(company: company, photoBytes: decodedBytes);

      // If ID is missing, try to sync with backend
      if (company.id == null) {
        syncCompanyWithBackend();
      }
    } else {
      // If no local company, try to sync with backend if token exists
      // This handles re-login on a fresh install or cleared data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        syncCompanyWithBackend();
      });
    }
  }

  /// Sync company data with backend to ensure ID is present
  Future<void> syncCompanyWithBackend() async {
    print('Starting company sync...');
    try {
      final token = ref.read(authProvider).token;
      if (token == null) {
        print('Sync aborted: Token is null');
        return;
      }

      final response = await ApiService.getCompanies(token);
      print('Sync response: ${response['success']}');
      if (response['success'] == true) {
        final List<dynamic> companies = response['companies'] ?? [];
        print('Found ${companies.length} companies on backend');
        if (companies.isNotEmpty) {
          // Take the first company (assuming 1 owner = 1 company for now)
          final data = companies.first;
          print('Backend Company ID: ${data['id']}');
          final updatedCompany = CompanyModel(
            id: data['id']?.toString(),
            companyName: data['company_name'] ?? state.companyName,
            industryType: data['industry_type'] ?? state.industryType,
            address: data['address'],
            companyPhoto: data['company_logo'] ?? state.companyPhoto,
            createdAt: data['created_at'] != null
                ? DateTime.parse(data['created_at'])
                : DateTime.now(),
          );

          await CompanyService.saveCompany(updatedCompany);
          state = state.copyWith(company: updatedCompany);
          print('Company state updated with ID: ${updatedCompany.id}');
        }
      }
    } catch (e) {
      print('Failed to sync company: $e');
    }
  }

  // Setters for form fields
  void setCompanyName(String value) {
    state = state.copyWith(companyName: value.trim());
  }

  void setIndustryType(String value) {
    state = state.copyWith(industryType: value);
  }

  void setAddress(String value) {
    state = state.copyWith(address: value.trim());
  }

  /// Set company photo from file
  Future<void> setCompanyPhoto(File file) async {
    try {
      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Convert to base64 using utility
      final extension = file.path.split('.').last;
      final base64String = ImageConverter.toBase64(bytes, extension);

      state = state.copyWith(
        companyPhoto: base64String,
        photoFile: file,
        photoBytes: bytes,
      );

      ToastHelper.success('Photo uploaded successfully');
    } catch (e) {
      ToastHelper.error('Failed to upload photo: $e');
    }
  }

  /// Set company photo from bytes (fallback for web/desktop)
  Future<void> setCompanyPhotoFromBytes(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      // Convert to base64 using utility
      final extension = filename.split('.').last;
      final base64String = ImageConverter.toBase64(bytes, extension);

      state = state.copyWith(companyPhoto: base64String, photoBytes: bytes);

      ToastHelper.success('Photo uploaded successfully');
    } catch (e) {
      ToastHelper.error('Failed to upload photo: $e');
    }
  }

  /// Clear company photo
  void clearCompanyPhoto() {
    state = state.copyWith(
      companyPhoto: null,
      photoFile: null,
      photoBytes: null,
    );
  }

  /// Register company (Step 2 of registration)
  Future<bool> registerCompany() async {
    if (state.companyName.isEmpty || state.industryType.isEmpty) {
      ToastHelper.error('Please fill all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) {
        state = state.copyWith(isLoading: false);
        ToastHelper.error('Authentication token missing. Please login again.');
        return false;
      }

      final response = await ApiService.registerCompany(
        companyName: state.companyName,
        industryType: state.industryType,
        address: state.address,
        companyPhoto: state.companyPhoto,
        token: token,
      );

      if (response['success'] == true) {
        final companyData = response['company'];
        final companyId = companyData != null
            ? companyData['id']?.toString()
            : null;

        final company = CompanyModel(
          id: companyId,
          companyName: state.companyName,
          industryType: state.industryType,
          address: state.address?.isEmpty == true ? null : state.address,
          companyPhoto: state.companyPhoto,
          createdAt: DateTime.now(),
        );

        // Save company data locally as well
        await CompanyService.saveCompany(company);

        // Initialize default settings and complete setup
        await SetupService.finalizeSetup();

        state = state.copyWith(isLoading: false, company: company);

        ToastHelper.success('Company registered successfully');
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        ToastHelper.error(response['message'] ?? 'Failed to register company');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastHelper.error('Failed to register company: $e');
      return false;
    }
  }

  /// Update company profile
  Future<bool> updateCompany({
    required String companyName,
    required String industryType,
    String? address,
    String? companyPhoto,
  }) async {
    if (companyName.isEmpty || industryType.isEmpty) {
      ToastHelper.error('Company name and industry type are required');
      return false;
    }

    if (state.company?.id == null) {
      ToastHelper.error('Company ID not found');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) {
        state = state.copyWith(isLoading: false);
        ToastHelper.error('Authentication token missing');
        return false;
      }

      final response = await ApiService.updateCompany(
        companyId: state.company!.id!,
        companyName: companyName,
        industryType: industryType,
        address: address,
        companyPhoto: companyPhoto,
        token: token,
      );

      if (response['success'] == true) {
        final updatedCompany = CompanyModel(
          id: state.company!.id,
          companyName: companyName,
          industryType: industryType,
          address: address?.isEmpty == true ? null : address,
          companyPhoto: companyPhoto,
          createdAt: state.company!.createdAt,
        );

        await CompanyService.saveCompany(updatedCompany);
        state = state.copyWith(isLoading: false, company: updatedCompany);

        ToastHelper.success('Company updated successfully');
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        ToastHelper.error(response['message'] ?? 'Failed to update company');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastHelper.error('Failed to update company: $e');
      return false;
    }
  }

  /// Clear company data
  Future<void> clearCompany() async {
    await CompanyService.clearCompany();
    state = const CompanyState();
  }

  CompanyState get currentState => state;
}

// Provider for company management
final companyProvider = StateNotifierProvider<CompanyNotifier, CompanyState>((
  ref,
) {
  final notifier = CompanyNotifier(ref);

  // Watch for token changes to trigger sync if company is missing
  ref.listen(authProvider, (previous, next) {
    if (next.token != null && next.token != previous?.token) {
      if (notifier.currentState.company == null ||
          notifier.currentState.company?.id == null) {
        notifier.syncCompanyWithBackend();
      }
    }
  });

  return notifier;
});
