import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_placement/core/utils/application_status_helper.dart';

void main() {
  group('ApplicationStatusHelper Date Formatting Unit Tests', () {
    test('formats raw JavaScript Date string correctly', () {
      const rawJsDate = 'Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)';
      final formatted = ApplicationStatusHelper.formatDisplayDateTime(rawJsDate);
      expect(formatted, equals('06 Oct 2026, 02:49 PM'));

      final dateOnly = ApplicationStatusHelper.formatDisplayDate(rawJsDate);
      expect(dateOnly, equals('06 Oct 2026'));
    });

    test('formats ISO-8601 timestamp string correctly', () {
      const iso = '2026-10-06T14:49:26';
      final formatted = ApplicationStatusHelper.formatDisplayDateTime(iso);
      expect(formatted, equals('06 Oct 2026, 02:49 PM'));

      final dateOnly = ApplicationStatusHelper.formatDisplayDate(iso);
      expect(dateOnly, equals('06 Oct 2026'));
    });

    test('formats YYYY-MM-DD date string correctly', () {
      const dateStr = '2026-10-06';
      final formatted = ApplicationStatusHelper.formatDisplayDate(dateStr);
      expect(formatted, equals('06 Oct 2026'));
    });

    test('handles empty or null inputs safely', () {
      expect(ApplicationStatusHelper.formatDisplayDateTime(''), equals(''));
      expect(ApplicationStatusHelper.formatDisplayDateTime(null), equals(''));
      expect(ApplicationStatusHelper.formatDisplayDate(''), equals(''));
      expect(ApplicationStatusHelper.formatDisplayDate(null), equals(''));
    });

    test('fallback cleans timezone string gracefully if unparseable', () {
      const weird = 'SomeDate GMT+0530 (IST)';
      expect(ApplicationStatusHelper.formatDisplayDateTime(weird), equals('SomeDate'));
    });
  });
}
