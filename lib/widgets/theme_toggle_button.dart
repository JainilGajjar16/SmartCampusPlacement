import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';

/// Reusable Theme Toggle Button with smooth icon transition.
class ThemeToggleButton extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Color? color;
  final double size;

  const ThemeToggleButton({
    super.key,
    required this.themeProvider,
    this.color,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode(context);

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey<bool>(isDark),
            color: color ?? AppColors.getTextPrimary(context),
            size: size,
          ),
        ),
        onPressed: () => themeProvider.toggleTheme(context),
      ),
    );
  }
}
