import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../routes/app_routes.dart';
import '../widgets/app_logo.dart';

/// Splash screen displaying app branding for 4.5 seconds before automatically navigating to the Login page.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _splashTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Duration set to 4.5 seconds (between 4 and 5 seconds as requested)
  static const Duration splashDuration = Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    // Start 4.5-second timer to navigate automatically to Login page
    _splashTimer = Timer(splashDuration, _navigateToLogin);
  }

  void _navigateToLogin() {
    if (!mounted) return;
    _splashTimer?.cancel();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: InkWell(
          onTap: _navigateToLogin, // Allows tapping to skip splash if desired
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Central Branding Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo Icon with Glow
                          const AppLogo(size: 110),
                          const SizedBox(height: 36),

                          // App Title
                          Text(
                            AppStrings.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // App Subtitle
                          Text(
                            AppStrings.appSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getTextSecondary(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Subtle Loading Bar showing progress over 4.5 seconds
                          SizedBox(
                            width: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: AppColors.getCardBorder(context),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Caption
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  'Powered by Campus Placement Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextLight(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

