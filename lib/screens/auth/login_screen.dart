import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/app_validators.dart';
import '../../main.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../dashboard/company_dashboard_screen.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Login Screen matching the exact visual styling from design screenshot (Image 1).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = GoogleSheetsService();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final String inputUserId = _userIdController.text.trim();
      final String inputPassword = _passwordController.text;

      setState(() {
        _isLoading = true;
      });

      final response = await _apiService.loginUser(
        userId: inputUserId,
        password: inputPassword,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final bool isSuccess = response['success'] == true;
      final String message =
          response['message']?.toString() ?? AppStrings.apiServerError;

      if (isSuccess) {
        final String userId =
            response['userId']?.toString().trim() ?? inputUserId;
        final String rawRole = response['role']?.toString() ?? 'Student';
        final String role = rawRole.trim().toLowerCase();
        final String? name = response['name']?.toString() ??
            (response['profile'] is Map ? response['profile']['name']?.toString() : null) ??
            (response['data'] is Map ? response['data']['name']?.toString() : null) ??
            (response['user'] is Map ? response['user']['name']?.toString() : null);
        final String status =
            (response['status'] ?? response['userStatus'] ?? 'Active')
                .toString()
                .trim()
                .toLowerCase();

        if (status == 'inactive' || status == 'disabled') {
          AppSnackBar.show(
            context,
            message: 'Your account is inactive. Please contact administrator.',
            isError: true,
          );
          return;
        }

        UserSession().setSession(
          userId: userId,
          role: rawRole,
          name: name,
        );

        AppSnackBar.show(
          context,
          message: message,
        );

        final String upperUserId = userId.toUpperCase();

        if (role == 'company' ||
            role == 'hr' ||
            role == 'recruiter' ||
            upperUserId.startsWith('COM')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const CompanyDashboard(),
            ),
            (route) => false,
          );
          return;
        } else if (role == 'admin' || upperUserId.startsWith('ADM')) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.adminDashboard,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      } else {
        AppSnackBar.show(
          context,
          message: message,
          isError: true,
        );
      }
    }
  }

  void _onForgotPasswordPressed() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: ThemeToggleButton(themeProvider: globalThemeProvider),
            ),
            Center(
              child: FadeSlideTransition(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                              AppStrings.welcomeBack,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.getTextPrimary(context),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                      const Text(
                        AppStrings.loginSubtitle,
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

                            // Password Input
                            CustomTextField(
                              controller: _passwordController,
                              labelText: AppStrings.passwordLabel,
                              hintText: AppStrings.passwordHint,
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _isPasswordObscured,
                              textInputAction: TextInputAction.done,
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
                            const SizedBox(height: 14),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _onForgotPasswordPressed,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  AppStrings.forgotPassword,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Gradient Login CTA Button
                      CustomButton(
                        text: AppStrings.login,
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: _onLoginPressed,
                      ),

                      const SizedBox(height: 24),

                      // Create Account Prompt
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            AppStrings.createAccountPrompt,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToRegister,
                            child: const Text(
                              AppStrings.createNewAccount,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
);
}
}


