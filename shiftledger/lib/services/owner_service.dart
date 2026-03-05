import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/owner_model.dart';

class OwnerService {
  static const String _ownerKey = 'owner_data';

  /// Save owner data to SharedPreferences
  static Future<void> saveOwner(OwnerModel owner) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(owner.toJson());
    await prefs.setString(_ownerKey, jsonString);
  }

  /// Load owner data from SharedPreferences
  static Future<OwnerModel?> loadOwner() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_ownerKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return OwnerModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Check if owner exists
  static Future<bool> hasOwner() async {
    final owner = await loadOwner();
    return owner != null;
  }

  /// Clear owner data
  static Future<void> clearOwner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerKey);
  }

  /// Validate login credentials
  static Future<bool> validateLogin(String mobileNumber, String password) async {
    final owner = await loadOwner();
    if (owner == null) return false;
    
    return owner.mobileNumber == mobileNumber && owner.password == password;
  }
}
