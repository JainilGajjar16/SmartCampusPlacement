import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/app_validators.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/fade_slide_transition.dart';

/// Screen for entering and confirming a new password for a verified user.
class ResetPasswordScreen extends StatefulWidget {
  final String userId;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = GoogleSheetsService();

  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPasswordPressed() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final response = await _apiService.resetPassword(
        userId: widget.userId,
        email: widget.email,
        newPassword: _newPasswordController.text,
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
          message: AppStrings.passwordResetSuccess,
        );

        // Clear previous navigation stack and navigate directly to Login
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } else {
        AppSnackBar.show(
          context,
          message: message,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackground(context);
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getCardBorder(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeSlideTransition(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Branding Logo Icon
                        const Center(
                          child: AppLogo(size: 78),
                        ),
                        const SizedBox(height: 24),

                        // Header Titles
                        Text(
                          AppStrings.resetPasswordTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.resetPasswordSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Verified Account Info Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account: ${widget.userId}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      widget.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form Container Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
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
                            // New Password Input
                            CustomTextField(
                              controller: _newPasswordController,
                              labelText: AppStrings.newPasswordLabel,
                              hintText: AppStrings.newPasswordHint,
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _isNewPasswordObscured,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isNewPasswordObscured
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordObscured =
                                        !_isNewPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Confirm New Password Input
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: AppStrings.confirmNewPasswordLabel,
                              hintText: AppStrings.confirmNewPasswordHint,
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _isConfirmPasswordObscured,
                              textInputAction: TextInputAction.done,
                              validator: (val) =>
                                  AppValidators.validateConfirmPassword(
                                val,
                                _newPasswordController.text,
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

                      // Reset Password CTA Button
                      CustomButton(
                        text: AppStrings.resetPassword,
                        icon: Icons.published_with_changes_rounded,
                        isLoading: _isLoading,
                        onPressed: _onResetPasswordPressed,
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
    ),
  );
}
}
