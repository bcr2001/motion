import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/sql_date_range.dart';

void main() {
  group('SqlDateRange', () {
    test('builds an index-friendly ISO year range', () {
      final range = SqlDateRange.year('2026');

      expect(range.startDate, '2026-01-01');
      expect(range.endDate, '2026-12-31');
      expect(range.args, ['2026-01-01', '2026-12-31']);
    });

    test('rejects invalid year values', () {
      expect(
        () => SqlDateRange.year('twenty twenty six'),
        throwsFormatException,
      );
    });
  });
}
