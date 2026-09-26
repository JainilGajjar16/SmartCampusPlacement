import 'package:flutter/material.dart';

/// Helper utility for normalizing application statuses and providing consistent
/// UI colors, icons, and timeline step indexing across the app.
class ApplicationStatusHelper {
  static const String statusApplied = 'Applied';
  static const String statusUnderReview = 'Under Review';
  static const String statusShortlisted = 'Shortlisted';
  static const String statusSelected = 'Selected';
  static const String statusRejected = 'Rejected';

  /// Standard order of positive placement progression stages.
  static const List<String> pipelineStages = [
    statusApplied,
    statusUnderReview,
    statusShortlisted,
    statusSelected,
  ];

  /// Standardizes arbitrary status strings from backend/sheet into standard status names.
  static String normalizeStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.trim().isEmpty) {
      return statusApplied;
    }
    final clean = rawStatus.trim().toLowerCase();
    if (clean.contains('select')) return statusSelected;
    if (clean.contains('shortlist')) return statusShortlisted;
    if (clean.contains('review') || clean.contains('pending') || clean.contains('evaluat')) {
      return statusUnderReview;
    }
    if (clean.contains('reject') || clean.contains('declin')) return statusRejected;
    return statusApplied;
  }

  /// Primary color associated with status.
  static Color getStatusColor(String status) {
    final norm = normalizeStatus(status);
    switch (norm) {
      case statusUnderReview:
        return const Color(0xFFD97706); // Amber
      case statusShortlisted:
        return const Color(0xFF7C3AED); // Purple
      case statusSelected:
        return const Color(0xFF059669); // Emerald Green
      case statusRejected:
        return const Color(0xFFDC2626); // Red
      case statusApplied:
      default:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  /// Soft background color associated with status.
  static Color getStatusBgColor(String status) {
    final norm = normalizeStatus(status);
    switch (norm) {
      case statusUnderReview:
        return const Color(0xFFFEF3C7);
      case statusShortlisted:
        return const Color(0xFFF3E8FF);
      case statusSelected:
        return const Color(0xFFD1FAE5);
      case statusRejected:
        return const Color(0xFFFEE2E2);
      case statusApplied:
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  /// Border color associated with status chip.
  static Color getStatusBorderColor(String status) {
    final norm = normalizeStatus(status);
    switch (norm) {
      case statusUnderReview:
        return const Color(0xFFFBBF24);
      case statusShortlisted:
        return const Color(0xFFC084FC);
      case statusSelected:
        return const Color(0xFF34D399);
      case statusRejected:
        return const Color(0xFFF87171);
      case statusApplied:
      default:
        return const Color(0xFF818CF8);
    }
  }

  /// Icon associated with status.
  static IconData getStatusIcon(String status) {
    final norm = normalizeStatus(status);
    switch (norm) {
      case statusUnderReview:
        return Icons.manage_search_rounded;
      case statusShortlisted:
        return Icons.star_rounded;
      case statusSelected:
        return Icons.check_circle_rounded;
      case statusRejected:
        return Icons.cancel_rounded;
      case statusApplied:
      default:
        return Icons.send_rounded;
    }
  }

  /// 0-indexed stage position in [pipelineStages]. Returns -1 for Rejected.
  static int getStepIndex(String status) {
    final norm = normalizeStatus(status);
    if (norm == statusRejected) return -1;
    final index = pipelineStages.indexOf(norm);
    return index != -1 ? index : 0;
  }

  /// Helper explanation message for timeline details.
  static String getStatusDescription(String status) {
    final norm = normalizeStatus(status);
    switch (norm) {
      case statusUnderReview:
        return 'Your profile and application details are currently under evaluation by the recruitment team.';
      case statusShortlisted:
        return 'Congratulations! You have been shortlisted for the next assessment or interview round.';
      case statusSelected:
        return 'Awesome news! You have been selected for this position. Offer details will follow.';
      case statusRejected:
        return 'Thank you for applying. Unfortunately, your application was not selected for this position.';
      case statusApplied:
      default:
        return 'Your job application has been successfully submitted and logged in the system.';
    }
  }
}
