import '../constants/app_constants.dart';

/// Form field validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s-]{7,15}$');

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, 'Email');
    if (missing != null) return missing;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  /// Phone is optional; only validated when something is entered.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? taskTitle(String? value) {
    final missing = required(value, 'Title');
    if (missing != null) return missing;
    if (value!.trim().length > AppConstants.taskTitleMaxLength) {
      return 'Title must be ${AppConstants.taskTitleMaxLength} characters or less';
    }
    return null;
  }
}
