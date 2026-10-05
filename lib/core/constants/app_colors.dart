import 'package:flutter/material.dart';

/// Centralized color palette for Smart Campus Placement app.
/// Tailored precisely to match modern indigo/blue placement theme visuals
/// with complete Light & Dark Mode palette support.
abstract class AppColors {
  // Brand Primary & Gradient Colors
  static const Color primary = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Blue
  static const Color primaryDark = Color(0xFF1E1B4B); // Deep Navy Slate
  static const Color accent = Color(0xFF0EA5E9); // Cyan Accent

  // Light Background & Surface Colors
  static const Color background = Color(0xFFF6F8FC); // Light grayish surface
  static const Color surface = Colors.white; // Pure white card surface
  static const Color cardBorder = Color(0xFFE2E8F0); // Subtle border outline
  static const Color inputBg = Color(0xFFFAFAFA); // Soft input background

  // Dark Background & Surface Colors
  static const Color darkBackground = Color(0xFF0F172A); // Deep Navy/Slate dark background
  static const Color darkSurface = Color(0xFF1E293B); // Sleek slate card surface
  static const Color darkCardBorder = Color(0xFF334155); // Subtle dark border outline
  static const Color darkInputBg = Color(0xFF1E293B); // Dark input background

  // Icon Chip Tints
  static const Color iconChipBg = Color(0xFFEEF2FF); // Soft indigo chip background
  static const Color iconChipColor = Color(0xFF4F46E5); // Icon tint color
  static const Color darkIconChipBg = Color(0xFF312E81); // Dark indigo chip background

  // Dashboard Card Tints
  static const Color cardBgProfile = Color(0xFFF0F4FF); // Light blue tint
  static const Color cardBgResume = Color(0xFFE0F2FE); // Light sky tint
  static const Color cardBgJobs = Color(0xFFFEF3C7); // Light amber tint
  static const Color cardBgApplications = Color(0xFFF3E8FF); // Light purple tint
  static const Color tipBg = Color(0xFFEEF2FF); // Light tip container tint

  static const Color darkCardBgProfile = Color(0xFF1E293B);
  static const Color darkCardBgResume = Color(0xFF1E293B);
  static const Color darkCardBgJobs = Color(0xFF1E293B);
  static const Color darkCardBgApplications = Color(0xFF1E293B);
  static const Color darkTipBg = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Bold dark navy/slate text
  static const Color textSecondary = Color(0xFF64748B); // Muted slate subtext
  static const Color textLight = Color(0xFF94A3B8); // Light caption text

  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Crisp white-slate text
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Light slate subtext
  static const Color darkTextLight = Color(0xFF64748B); // Dark caption text

  // Helper Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Context-aware dynamic theme resolution helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackground(BuildContext context) {
    return isDark(context) ? darkBackground : background;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? darkSurface : surface;
  }

  static Color getCardBorder(BuildContext context) {
    return isDark(context) ? darkCardBorder : cardBorder;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  static Color getTextLight(BuildContext context) {
    return isDark(context) ? darkTextLight : textLight;
  }

  static Color getInputBg(BuildContext context) {
    return isDark(context) ? darkInputBg : inputBg;
  }

  static Color getIconChipBg(BuildContext context) {
    return isDark(context) ? darkIconChipBg : iconChipBg;
  }
}
