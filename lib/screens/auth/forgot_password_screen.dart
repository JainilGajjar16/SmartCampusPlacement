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

/// Screen for verifying User ID and Registered Email prior to password reset.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _apiService = GoogleSheetsService();

  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onVerifyPressed() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final userId = _userIdController.text.trim();
      final email = _emailController.text.trim();

      final response = await _apiService.verifyResetUser(
        userId: userId,
        email: email,
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

        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: {
            'userId': userId,
            'email': email,
          },
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

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _navigateToLogin,
        ),
      ),
      body: SafeArea(
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
                      // App Logo Icon
                      const Center(
                        child: AppLogo(size: 78),
                      ),
                      const SizedBox(height: 24),

                      // Header Titles
                      const Text(
                        AppStrings.forgotPasswordTitle,
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
                        AppStrings.forgotPasswordSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Container Card
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
                            // User ID Input
                            CustomTextField(
                              controller: _userIdController,
                              labelText: AppStrings.userIdLabel,
                              hintText: AppStrings.userIdHint,
                              prefixIcon: Icons.person_rounded,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.validateUserId,
                            ),
                            const SizedBox(height: 20),

                            // Email Address Input
                            CustomTextField(
                              controller: _emailController,
                              labelText: AppStrings.emailLabel,
                              hintText: AppStrings.emailHint,
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: AppValidators.validateEmail,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Verify Account CTA Button
                      CustomButton(
                        text: AppStrings.verifyAccount,
                        icon: Icons.check_circle_rounded,
                        isLoading: _isLoading,
                        onPressed: _onVerifyPressed,
                      ),

                      const SizedBox(height: 24),

                      // Return to Login Link
                      Center(
                        child: GestureDetector(
                          onTap: _navigateToLogin,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Back to ${AppStrings.loginLink}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
