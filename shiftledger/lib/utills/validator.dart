class AppValidator {
  /// Validates names (owner, company, employee) 
  /// Accepts alphabets, dots (.) and spaces.
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final nameRegExp = RegExp(r'^[a-zA-Z. ]+$');
    if (!nameRegExp.hasMatch(value)) {
      return '$fieldName can only contain alphabets, dots, and spaces';
    }
    return null;
  }

  /// Validates proper 10-digit mobile numbers
  static String? validatePhoneNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final phoneRegExp = RegExp(r'^\d{10}$');
    if (!phoneRegExp.hasMatch(value)) {
      return '$fieldName must be a valid 10-digit number';
    }
    return null;
  }

  /// Validates proper email format (optional)
  static String? validateEmail(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Email is required' : null;
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates passwords: alphabets, numbers and minimum one special character
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    final hasAlphabets = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasAlphabets) {
      return 'Password must contain at least one alphabet';
    }
    if (!hasNumbers) {
      return 'Password must contain at least one number';
    }
    if (!hasSpecialChar) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validates company address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }
    return null;
  }

  /// Validates employee salary (positive numbers only)
  static String? validateSalary(String? value) {
    if (value == null || value.isEmpty) {
      return 'Salary is required';
    }
    final salary = double.tryParse(value);
    if (salary == null) {
      return 'Please enter a valid numerical value';
    }
    if (salary <= 0) {
      return 'Salary must be a positive number';
    }
    return null;
  }
}
