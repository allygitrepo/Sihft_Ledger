import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_model.dart';

class CompanyService {
  static const String _companyKey = 'company_data';

  /// Save company data to SharedPreferences
  static Future<void> saveCompany(CompanyModel company) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(company.toJson());
    await prefs.setString(_companyKey, jsonString);
  }

  /// Load company data from SharedPreferences
  static Future<CompanyModel?> loadCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_companyKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CompanyModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Check if company exists
  static Future<bool> hasCompany() async {
    final company = await loadCompany();
    return company != null;
  }

  /// Clear company data
  static Future<void> clearCompany() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_companyKey);
  }
}
