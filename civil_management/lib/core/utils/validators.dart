import '../config/app_constants.dart';

/// Form validators for the application
/// Provides consistent validation across all forms
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  /// Email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email address
  static String? email(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Email';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final trimmed = value.trim();

    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  /// Password regex patterns
  static final RegExp _hasUpperCase = RegExp(r'[A-Z]');
  static final RegExp _hasLowerCase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Validate password
  static String? password(String? value, {bool requireStrong = true}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
    }

    if (requireStrong) {
      if (!_hasUpperCase.hasMatch(value)) {
        return 'Password must contain at least one uppercase letter';
      }

      if (!_hasLowerCase.hasMatch(value)) {
        return 'Password must contain at least one lowercase letter';
      }

      if (!_hasDigit.hasMatch(value)) {
        return 'Password must contain at least one number';
      }
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Check password strength (returns 0-4)
  static int passwordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (_hasUpperCase.hasMatch(password) && _hasLowerCase.hasMatch(password))
      strength++;
    if (_hasDigit.hasMatch(password)) strength++;
    if (_hasSpecialChar.hasMatch(password)) strength++;

    return strength.clamp(0, 4);
  }

  /// Get password strength label
  static String passwordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // NAME VALIDATION
  // ============================================================

  /// Validate name (full name, first name, etc.)
  static String? name(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Name';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < AppConstants.minNameLength) {
      return '$field must be at least ${AppConstants.minNameLength} characters';
    }

    if (trimmed.length > AppConstants.maxNameLength) {
      return '$field must be less than ${AppConstants.maxNameLength} characters';
    }

    // Check for invalid characters
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(trimmed)) {
      return '$field contains invalid characters';
    }

    return null;
  }

  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  /// Indian phone number regex (10 digits, optionally with +91 or 0)
  static final RegExp _phoneRegex = RegExp(r'^(?:\+91|91|0)?[6-9]\d{9}$');

  /// Validate phone number
  static String? phone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // ============================================================
  // REQUIRED VALIDATION
  // ============================================================

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    final field = fieldName ?? 'This field';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  /// Validate required selection (dropdown, etc.)
  static String? requiredSelection<T>(T? value, {String? fieldName}) {
    final field = fieldName ?? 'Selection';

    if (value == null) {
      return 'Please select a $field';
    }

    return null;
  }

  // ============================================================
  // NUMBER VALIDATION
  // ============================================================

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Value';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number <= 0) {
      return '$field must be greater than 0';
    }

    return null;
  }

  /// Validate number in range
  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Value';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return '$field must be between $min and $max';
    }

    return null;
  }

  /// Validate integer
  static String? integer(
    String? value, {
    String? fieldName,
    bool required = true,
  }) {
    final field = fieldName ?? 'Value';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Please enter a whole number';
    }

    return null;
  }

  // ============================================================
  // CURRENCY VALIDATION
  // ============================================================

  /// Validate currency amount
  static String? currency(
    String? value, {
    String? fieldName,
    bool required = true,
  }) {
    final field = fieldName ?? 'Amount';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    // Remove currency symbol and commas
    final cleaned = value.replaceAll(RegExp(r'[₹,\s]'), '');

    final amount = double.tryParse(cleaned);

    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount < 0) {
      return '$field cannot be negative';
    }

    return null;
  }

  // ============================================================
  // DATE VALIDATION
  // ============================================================

  /// Validate date is not empty
  static String? dateRequired(DateTime? value, {String? fieldName}) {
    final field = fieldName ?? 'Date';

    if (value == null) {
      return 'Please select a $field';
    }

    return null;
  }

  /// Validate date is in the future
  static String? futureDate(DateTime? value, {String? fieldName}) {
    final field = fieldName ?? 'Date';

    if (value == null) {
      return 'Please select a $field';
    }

    if (value.isBefore(DateTime.now())) {
      return '$field must be in the future';
    }

    return null;
  }

  /// Validate date is in the past
  static String? pastDate(DateTime? value, {String? fieldName}) {
    final field = fieldName ?? 'Date';

    if (value == null) {
      return 'Please select a $field';
    }

    if (value.isAfter(DateTime.now())) {
      return '$field cannot be in the future';
    }

    return null;
  }

  /// Validate end date is after start date
  static String? dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null;
    }

    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }

    return null;
  }

  // ============================================================
  // TEXT LENGTH VALIDATION
  // ============================================================

  /// Validate minimum length
  static String? minLength(String? value, int minLen, {String? fieldName}) {
    final field = fieldName ?? 'This field';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    if (value.trim().length < minLen) {
      return '$field must be at least $minLen characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int maxLen, {String? fieldName}) {
    final field = fieldName ?? 'This field';

    if (value != null && value.trim().length > maxLen) {
      return '$field must be less than $maxLen characters';
    }

    return null;
  }

  // ============================================================
  // FILE VALIDATION
  // ============================================================

  /// Validate file extension
  static String? fileExtension(
    String? fileName,
    List<String> allowedExtensions,
  ) {
    if (fileName == null || fileName.isEmpty) {
      return 'Please select a file';
    }

    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Allowed file types: ${allowedExtensions.join(", ")}';
    }

    return null;
  }

  /// Validate file size
  static String? fileSize(
    int? sizeInBytes, {
    int maxSize = AppConstants.maxFileSize,
  }) {
    if (sizeInBytes == null) {
      return 'Unable to determine file size';
    }

    if (sizeInBytes > maxSize) {
      final maxMB = maxSize / (1024 * 1024);
      return 'File size must be less than ${maxMB.toStringAsFixed(0)}MB';
    }

    return null;
  }

  // ============================================================
  // URL VALIDATION
  // ============================================================

  /// URL regex pattern
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validate URL
  static String? url(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }

    if (!_urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ============================================================
  // PINCODE VALIDATION
  // ============================================================

  /// Indian pincode regex (6 digits)
  static final RegExp _pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');

  /// Validate pincode
  static String? pincode(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Pincode is required' : null;
    }

    if (!_pincodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 6-digit pincode';
    }

    return null;
  }

  // ============================================================
  // PAN/GST VALIDATION
  // ============================================================

  /// PAN number regex
  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  /// Validate PAN number
  static String? pan(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'PAN number is required' : null;
    }

    final upper = value.trim().toUpperCase();

    if (!_panRegex.hasMatch(upper)) {
      return 'Please enter a valid PAN number';
    }

    return null;
  }

  /// GST number regex
  static final RegExp _gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  /// Validate GST number
  static String? gst(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'GST number is required' : null;
    }

    final upper = value.trim().toUpperCase();

    if (!_gstRegex.hasMatch(upper)) {
      return 'Please enter a valid GST number';
    }

    return null;
  }
}
