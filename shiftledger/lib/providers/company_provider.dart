import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';
import '../services/setup_service.dart';
import '../widgets/toast.dart';

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
  CompanyNotifier() : super(const CompanyState()) {
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final company = await CompanyService.loadCompany();
    if (company != null) {
      state = state.copyWith(company: company);
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

      // Convert to base64
      final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

      state = state.copyWith(companyPhoto: base64String, photoFile: file);

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
      // Convert to base64
      final ext = filename.split('.').last.toLowerCase();
      final mimeType = ext == 'jpg' || ext == 'jpeg'
          ? 'image/jpeg'
          : 'image/png';
      final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

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
      final company = CompanyModel(
        companyName: state.companyName,
        industryType: state.industryType,
        address: state.address?.isEmpty == true ? null : state.address,
        companyPhoto: state.companyPhoto,
        createdAt: DateTime.now(),
      );

      // Save company data
      await CompanyService.saveCompany(company);

      // Initialize default settings and complete setup
      await SetupService.finalizeSetup();

      state = state.copyWith(isLoading: false, company: company);

      ToastHelper.success('Company registered successfully');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ToastHelper.error('Failed to register company: $e');
      return false;
    }
  }

  /// Clear company data
  Future<void> clearCompany() async {
    await CompanyService.clearCompany();
    state = const CompanyState();
  }
}

// Provider for company management
final companyProvider = StateNotifierProvider<CompanyNotifier, CompanyState>((
  ref,
) {
  return CompanyNotifier();
});
