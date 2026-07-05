import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

void main() {
  group('MotionDateUtils', () {
    test('formats stored database dates consistently', () {
      expect(
        MotionDateUtils.formatDbDate(DateTime(2026, 6, 4, 22, 30)),
        '2026-06-04',
      );
    });

    test('normalizes supported imported date formats', () {
      expect(MotionDateUtils.normalizeStoredDate('2026-06-04'), '2026-06-04');
      expect(MotionDateUtils.normalizeStoredDate('6/4/2026'), '2026-06-04');
      expect(MotionDateUtils.normalizeStoredDate('25/4/2026'), '2026-04-25');
    });

    test('creates month, week, and year ranges as stored dates', () {
      final date = DateTime(2026, 6, 17);

      expect(MotionDateUtils.monthRange(date).sqlArgs, [
        '2026-06-01',
        '2026-06-30',
      ]);
      expect(MotionDateUtils.weekRange(date).sqlArgs, [
        '2026-06-15',
        '2026-06-21',
      ]);
      expect(MotionDateUtils.yearRange(2026).sqlArgs, [
        '2026-01-01',
        '2026-12-31',
      ]);
    });

    test('allows current date injection for deterministic tests', () {
      final today = MotionDateUtils.todayIso(
        now: () => DateTime(2026, 7, 5, 23, 59),
      );

      expect(today, '2026-07-05');
    });
  });
}
