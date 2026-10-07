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

  /// Formats raw timestamp string into user-friendly UI display string, e.g. "06 Oct 2026, 02:49 PM"
  static String formatDisplayDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    final dt = _tryParseDateTime(trimmed);
    if (dt != null) {
      return _formatToDisplay(dt, includeTime: true);
    }
    return _cleanupRawDateString(trimmed);
  }

  /// Formats raw timestamp string into user-friendly UI date, e.g. "06 Oct 2026"
  static String formatDisplayDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    final dt = _tryParseDateTime(trimmed);
    if (dt != null) {
      return _formatToDisplay(dt, includeTime: false);
    }
    return _cleanupRawDateString(trimmed);
  }

  static DateTime? _tryParseDateTime(String str) {
    if (str.isEmpty) return null;

    // 1. Try standard ISO-8601 or YYYY-MM-DD
    final isoParsed = DateTime.tryParse(str);
    if (isoParsed != null) {
      return isoParsed.isUtc ? isoParsed.toLocal() : isoParsed;
    }

    // 2. Try JavaScript Date format: "Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)"
    // or "Tue Oct 06 2026 14:49:26"
    final jsRegex = RegExp(
      r'^[A-Za-z]{3}\s+([A-Za-z]{3})\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?',
    );
    final jsMatch = jsRegex.firstMatch(str);
    if (jsMatch != null) {
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final mStr = jsMatch.group(1)?.toLowerCase() ?? 'jan';
      final month = months[mStr] ?? 1;
      final day = int.tryParse(jsMatch.group(2) ?? '1') ?? 1;
      final year = int.tryParse(jsMatch.group(3) ?? '2026') ?? 2026;
      final hour = int.tryParse(jsMatch.group(4) ?? '0') ?? 0;
      final minute = int.tryParse(jsMatch.group(5) ?? '0') ?? 0;
      final second = int.tryParse(jsMatch.group(6) ?? '0') ?? 0;
      return DateTime(year, month, day, hour, minute, second);
    }

    // 3. Try epoch milliseconds
    if (RegExp(r'^\d{10,13}$').hasMatch(str)) {
      final ms = int.tryParse(str);
      if (ms != null) {
        final adjustedMs = ms < 10000000000 ? ms * 1000 : ms;
        return DateTime.fromMillisecondsSinceEpoch(adjustedMs).toLocal();
      }
    }

    // 4. Try DD/MM/YYYY or DD-MM-YYYY
    final slashRegex = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    );
    final slashMatch = slashRegex.firstMatch(str);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1)!) ?? 1;
      final month = int.tryParse(slashMatch.group(2)!) ?? 1;
      final year = int.tryParse(slashMatch.group(3)!) ?? 2026;
      final hour = int.tryParse(slashMatch.group(4) ?? '0') ?? 0;
      final minute = int.tryParse(slashMatch.group(5) ?? '0') ?? 0;
      final second = int.tryParse(slashMatch.group(6) ?? '0') ?? 0;
      return DateTime(year, month, day, hour, minute, second);
    }

    return null;
  }

  static String _formatToDisplay(DateTime dt, {required bool includeTime}) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = monthNames[dt.month - 1];
    final year = dt.year.toString();

    if (!includeTime) {
      return '$day $month $year';
    }

    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hourStr:$minuteStr $period';
  }

  static String _cleanupRawDateString(String raw) {
    var cleaned = raw;
    if (cleaned.contains(' GMT')) {
      cleaned = cleaned.split(' GMT')[0].trim();
    }
    if (cleaned.contains('(') && cleaned.contains(')')) {
      cleaned = cleaned.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    }
    return cleaned;
  }
}
