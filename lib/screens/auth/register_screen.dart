import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/app_validators.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Registration Screen matching the exact visual styling from design screenshot (Image 2).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = GoogleSheetsService();

  String _selectedRole = AppStrings.studentRole;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final response = await _apiService.registerUser(
        userId: _userIdController.text,
        name: _fullNameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        password: _passwordController.text,
        role: _selectedRole,
        github: '',
        linkedin: '',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final bool isSuccess = response['success'] == true;
      final String message =
          response['message']?.toString() ?? AppStrings.apiServerError;

      if (isSuccess) {
        AppSnackBar.show(
          context,
          message: message,
        );

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        });
      } else {
        AppSnackBar.show(
          context,
          message: message,
          isError: true,
        );
      }
    }
  }

  void _navigateToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Title Header
                      const Text(
                        AppStrings.createAccount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.registerSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card Container for Form Fields
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role Selection Selector Header
                            const Text(
                              AppStrings.roleLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _RoleChip(
                                    label: AppStrings.studentRole,
                                    icon: Icons.school_rounded,
                                    isSelected:
                                        _selectedRole == AppStrings.studentRole,
                                    onTap: () {
                                      setState(() {
                                        _selectedRole = AppStrings.studentRole;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RoleChip(
                                    label: AppStrings.hrRole,
                                    icon: Icons.business_center_rounded,
                                    isSelected: _selectedRole == AppStrings.hrRole,
                                    onTap: () {
                                      setState(() {
                                        _selectedRole = AppStrings.hrRole;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Full Name Field
                            CustomTextField(
                              controller: _fullNameController,
                              labelText: AppStrings.fullNameLabel,
                              hintText: AppStrings.fullNameHint,
                              prefixIcon: Icons.person_rounded,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validateFullName,
                            ),
                            const SizedBox(height: 16),

                            // User ID Field
                            CustomTextField(
                              controller: _userIdController,
                              labelText: AppStrings.userIdLabel,
                              hintText: AppStrings.userIdHint,
                              prefixIcon: Icons.account_circle_rounded,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validateUserId,
                            ),
                            const SizedBox(height: 16),

                            // Email Address Field
                            CustomTextField(
                              controller: _emailController,
                              labelText: AppStrings.emailLabel,
                              hintText: AppStrings.emailHint,
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validateEmail,
                            ),
                            const SizedBox(height: 16),

                            // Mobile Number Field
                            CustomTextField(
                              controller: _mobileController,
                              labelText: AppStrings.mobileLabel,
                              hintText: AppStrings.mobileHint,
                              prefixIcon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validateMobile,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              labelText: AppStrings.passwordLabel,
                              hintText: AppStrings.passwordHint,
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _isPasswordObscured,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordObscured = !_isPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: AppStrings.confirmPasswordLabel,
                              hintText: AppStrings.confirmPasswordHint,
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _isConfirmPasswordObscured,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  AppValidators.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordObscured
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordObscured =
                                        !_isConfirmPasswordObscured;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Register CTA Button
                      CustomButton(
                        text: AppStrings.register,
                        icon: Icons.how_to_reg_rounded,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _onRegisterPressed,
                      ),

                      const SizedBox(height: 24),

                      // Login Link Prompt
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            AppStrings.alreadyHaveAccountPrompt,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: const Text(
                              AppStrings.loginLink,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper chip widget for role selection matching design in Image 2.
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iconChipBg : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


