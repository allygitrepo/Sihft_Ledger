class ApiConstant {
  // Base URLs
  static const String serverUrl =
      "http://192.168.1.6:3000"; // Android Emulator default for localhost
  static const String baseUrl = "$serverUrl/shiftledger";

  // Health Check
  static const String healthCheck = "$serverUrl/"; // Root health check

  // Authentication
  static const String authRegister = "$baseUrl/user/register";
  static const String authLogin = "$baseUrl/user/login";
  static const String authUpdateProfile = "$baseUrl/user/update-profile";

  // Companies Management
  static const String companiesBase = "$baseUrl/companies";
  static String getCompanyById(String id) => "$companiesBase/$id";
  static String updateCompany(String id) => "$companiesBase/$id";
  static String deleteCompany(String id) => "$companiesBase/$id";

  // Departments Management
  static const String departmentsBase = "$baseUrl/departments";
  static String getDepartmentById(String id) => "$departmentsBase/$id";
  static String updateDepartment(String id) => "$departmentsBase/$id";
  static String deleteDepartment(String id) => "$departmentsBase/$id";

  // Designations Management
  static const String designationsBase = "$baseUrl/designations";
  static String getDesignationById(String id) => "$designationsBase/$id";
  static String updateDesignation(String id) => "$designationsBase/$id";
  static String deleteDesignation(String id) => "$designationsBase/$id";

  // Employee Management
  static const String employeesBase = "$baseUrl/employees";
  static const String employeesBulk = "$employeesBase/bulk";
  static String getEmployeeById(String id) => "$employeesBase/$id";
  static String updateEmployee(String id) => "$employeesBase/$id";
  static String deleteEmployee(String id) => "$employeesBase/$id";

  // Attendance Management
  static const String attendanceBase = "$baseUrl/attendance";
  static const String clockIn = "$attendanceBase/clock-in";
  static const String clockOut = "$attendanceBase/clock-out";
  static String getAttendanceByEmployee(String empId) =>
      "$attendanceBase/employee/$empId";
  static String updateAttendanceStatus(String id) =>
      "$attendanceBase/status/$id";

  // Salary & Payroll Management
  static const String salariesBase = "$baseUrl/salaries";
  static const String salaryConfigBase = salariesBase;
  static String getSalaryConfig(String companyId) =>
      "$salaryConfigBase/company/$companyId";
  static const String employeeSalariesBase = "$baseUrl/employee-salaries";
  static const String overtimeSlotsBase = "$baseUrl/overtime-slots";
  static const String employeeOvertimeConfigsBase =
      "$baseUrl/employee-overtime-configs";

  // HTTP Methods
  static const String methodGet = 'GET';
  static const String methodPost = 'POST';
  static const String methodPut = 'PUT';
  static const String methodDelete = 'DELETE';

  // Response Status
  static const int statusSuccess = 200;
  static const int statusCreated = 201;
  static const int statusAccepted = 202;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;
}
