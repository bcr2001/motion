import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_reusable/date_re/year_progress.dart';

void main() {
  group('YearProgress', () {
    test('uses 365 days for regular years', () {
      expect(YearProgress.daysInYear(2026), 365);
    });

    test('uses 366 days for leap years', () {
      expect(YearProgress.daysInYear(2024), 366);
    });

    test('formats tracked days using the selected year length', () {
      expect(
        YearProgress.formatTrackedDays(trackedDays: 366, year: 2024),
        '366/366',
      );
      expect(
        YearProgress.formatTrackedDays(trackedDays: 365, year: 2026),
        '365/365',
      );
    });

    test('calculates percent with the actual length of the year', () {
      expect(
        YearProgress.percentComplete(elapsedDays: 183, year: 2024),
        50,
      );
    });

    test('bounds percent complete between 0 and 100', () {
      expect(
        YearProgress.percentComplete(elapsedDays: -1, year: 2026),
        0,
      );
      expect(
        YearProgress.percentComplete(elapsedDays: 500, year: 2026),
        100,
      );
    });
  });
}
