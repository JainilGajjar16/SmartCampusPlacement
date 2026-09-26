import 'package:flutter/material.dart';

/// Centralized color palette for Smart Campus Placement app.
/// Tailored precisely to match modern indigo/blue placement theme visuals.
abstract class AppColors {
  // Brand Primary & Gradient Colors
  static const Color primary = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Blue
  static const Color primaryDark = Color(0xFF1E1B4B); // Deep Navy Slate
  static const Color accent = Color(0xFF0EA5E9); // Cyan Accent

  // Background & Surface Colors
  static const Color background = Color(0xFFF6F8FC); // Light grayish surface
  static const Color surface = Colors.white; // Pure white card surface
  static const Color cardBorder = Color(0xFFE2E8F0); // Subtle border outline
  static const Color inputBg = Color(0xFFFAFAFA); // Soft input background

  // Icon Chip Tints
  static const Color iconChipBg = Color(0xFFEEF2FF); // Soft indigo chip background
  static const Color iconChipColor = Color(0xFF4F46E5); // Icon tint color

  // Dashboard Card Tints
  static const Color cardBgProfile = Color(0xFFF0F4FF); // Light blue tint
  static const Color cardBgResume = Color(0xFFE0F2FE); // Light sky tint
  static const Color cardBgJobs = Color(0xFFFEF3C7); // Light amber tint
  static const Color cardBgApplications = Color(0xFFF3E8FF); // Light purple tint
  static const Color tipBg = Color(0xFFEEF2FF); // Light tip container tint

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Bold dark navy/slate text
  static const Color textSecondary = Color(0xFF64748B); // Muted slate subtext
  static const Color textLight = Color(0xFF94A3B8); // Light caption text

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
}

