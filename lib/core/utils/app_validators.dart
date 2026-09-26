import '../constants/app_strings.dart';

/// Pure validation utilities for authentication forms.
abstract class AppValidators {
  /// Regular expression pattern for email validation.
  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  /// Regular expression pattern for 10-digit mobile number validation.
  static final RegExp _mobileRegExp = RegExp(r'^[0-9]{10}$');

  /// Validates User ID input.
  static String? validateUserId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errUserIdRequired;
    }
    if (value.trim().length < 3) {
      return AppStrings.errUserIdMinLength;
    }
    return null;
  }

  /// Validates email address input.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errEmailRequired;
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return AppStrings.errEmailInvalid;
    }
    return null;
  }

  /// Validates password input.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errPasswordRequired;
    }
    if (value.length < 6) {
      return AppStrings.errPasswordMinLength;
    }
    return null;
  }

  /// Validates full name input.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errFullNameRequired;
    }
    return null;
  }

  /// Validates mobile number input.
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errMobileRequired;
    }
    final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!_mobileRegExp.hasMatch(cleanNumber)) {
      return AppStrings.errMobileInvalid;
    }
    return null;
  }

  /// Validates confirmation password against the original password.
  static String? validateConfirmPassword(
      String? confirmPassword, String originalPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppStrings.errConfirmPasswordRequired;
    }
    if (confirmPassword != originalPassword) {
      return AppStrings.errPasswordsDoNotMatch;
    }
    return null;
  }
}
