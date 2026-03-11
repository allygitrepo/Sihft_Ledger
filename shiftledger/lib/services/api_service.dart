import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constant.dart';

class ApiService {
  /// General method to handle POST requests
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    print('API POST Request - URL: $url');
    print('API POST Request - Body: ${jsonEncode(body)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      print('API Connection Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// General method to handle GET requests
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('API Response Status: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    try {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ??
              'Error ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('JSON Decode Error: $e');
      return {
        'success': false,
        'message': 'Invalid response from server (${response.statusCode})',
      };
    }
  }

  /// General method to handle PUT requests
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// General method to handle DELETE requests
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // --- Authentication ---

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    return await post(ApiConstant.authLogin, {
      'phone': phone,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register({
    required String ownerName,
    required String phone,
    String? email,
    required String password,
  }) async {
    return await post(ApiConstant.authRegister, {
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String ownerName,
    required String phone,
    String? email,
    required String token,
  }) async {
    return await put(ApiConstant.authUpdateProfile, {
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
    }, headers: _authHeader(token));
  }

  // --- Company ---

  static Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String industryType,
    String? address,
    String? companyPhoto,
    required String token,
  }) async {
    return await post(ApiConstant.companiesBase, {
      'company_name': companyName,
      'industry_type': industryType,
      'address': address,
      'company_logo': companyPhoto, // Backend expects company_logo
    }, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> getCompanies(String token) async {
    return await get(ApiConstant.companiesBase, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    required String companyName,
    required String industryType,
    String? address,
    String? companyPhoto,
    required String token,
  }) async {
    return await put(ApiConstant.updateCompany(companyId), {
      'company_name': companyName,
      'industry_type': industryType,
      'address': address,
      'company_logo': companyPhoto,
    }, headers: _authHeader(token));
  }

  static Map<String, String> _authHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Departments ---

  static Future<Map<String, dynamic>> getDepartments(
    String companyId,
    String token,
  ) async {
    return await get(
      '${ApiConstant.departmentsBase}?company_id=$companyId',
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> createDepartment({
    required String companyId,
    required String departmentName,
    required String token,
  }) async {
    return await post(ApiConstant.departmentsBase, {
      'company_id': companyId,
      'department_name': departmentName,
    }, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> updateDepartment({
    required String id,
    required String departmentName,
    required bool status,
    required String token,
  }) async {
    return await put(ApiConstant.updateDepartment(id), {
      'department_name': departmentName,
      'status': status,
    }, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> deleteDepartment(
    String id,
    String token,
  ) async {
    return await delete(
      ApiConstant.deleteDepartment(id),
      headers: _authHeader(token),
    );
  }

  // --- Designations ---

  static Future<Map<String, dynamic>> getDesignations(
    String departmentId,
    String token,
  ) async {
    return await get(
      '${ApiConstant.designationsBase}?department_id=$departmentId',
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> createDesignation({
    required String departmentId,
    required String designationName,
    required String token,
  }) async {
    return await post(ApiConstant.designationsBase, {
      'department_id': departmentId,
      'designation_name': designationName,
    }, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> updateDesignation({
    required String id,
    required String designationName,
    required bool status,
    required String token,
  }) async {
    return await put(ApiConstant.updateDesignation(id), {
      'designation_name': designationName,
      'status': status,
    }, headers: _authHeader(token));
  }

  static Future<Map<String, dynamic>> deleteDesignation(
    String id,
    String token,
  ) async {
    return await delete(
      ApiConstant.deleteDesignation(id),
      headers: _authHeader(token),
    );
  }

  // --- Employees ---

  static Future<Map<String, dynamic>> getEmployees(
    String companyId,
    String token,
  ) async {
    return await get(
      '${ApiConstant.employeesBase}?company_id=$companyId',
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> data,
    String token,
  ) async {
    return await post(
      ApiConstant.employeesBase,
      data,
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    return await put(
      ApiConstant.updateEmployee(id),
      data,
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> deleteEmployee(
    String id,
    String token,
  ) async {
    return await delete(
      ApiConstant.deleteEmployee(id),
      headers: _authHeader(token),
    );
  }

  // --- Salary Configuration ---

  static Future<Map<String, dynamic>> getSalaryConfig(
    String companyId,
    String token,
  ) async {
    return await get(
      ApiConstant.getSalaryConfig(companyId),
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> saveSalaryConfig(
    Map<String, dynamic> data,
    String token,
  ) async {
    return await post(
      ApiConstant.salaryConfigBase,
      data,
      headers: _authHeader(token),
    );
  }

  // --- Overtime Slots ---

  static Future<Map<String, dynamic>> getOvertimeSlots(
    String companyId,
    String token,
  ) async {
    return await get(
      '${ApiConstant.overtimeSlotsBase}?company_id=$companyId',
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> createOvertimeSlot(
    Map<String, dynamic> data,
    String token,
  ) async {
    return await post(
      ApiConstant.overtimeSlotsBase,
      data,
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> updateOvertimeSlot(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    return await put(
      '${ApiConstant.overtimeSlotsBase}/$id',
      data,
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> deleteOvertimeSlot(
    String id,
    String token,
  ) async {
    return await delete(
      '${ApiConstant.overtimeSlotsBase}/$id',
      headers: _authHeader(token),
    );
  }

  // --- Employee Overtime Config ---

  static Future<Map<String, dynamic>> getEmployeeOvertimeConfig(
    String employeeId,
    String token,
  ) async {
    return await get(
      '${ApiConstant.employeeOvertimeConfigsBase}/employee/$employeeId',
      headers: _authHeader(token),
    );
  }

  static Future<Map<String, dynamic>> saveEmployeeOvertimeConfig(
    Map<String, dynamic> data,
    String token,
  ) async {
    return await post(
      ApiConstant.employeeOvertimeConfigsBase,
      data,
      headers: _authHeader(token),
    );
  }
}
