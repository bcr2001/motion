import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_analytics/analytics_models.dart';

void main() {
  group('analytics models', () {
    test('parses a report snapshot without leaking database value types', () {
      final snapshot = ReportSnapshot.fromMap({
        'trackedDays': 12,
        'accountedMinutes': 4321.5,
        'unaccountedMinutes': '900',
        'totalXp': 420,
        'xpDays': 11,
        'efficiencyScore': 63.75,
        'bestDay': '2026-07-12',
        'bestDayXp': 52,
        'lowestDay': null,
        'lowestDayXp': 0,
      });

      expect(snapshot.trackedDays, 12);
      expect(snapshot.accountedMinutes, 4321.5);
      expect(snapshot.unaccountedMinutes, 900);
      expect(snapshot.bestDay, '2026-07-12');
      expect(snapshot.lowestDay, isNull);
    });

    test('parses typed trend and category totals', () {
      final point = DailyXpPoint.fromMap({
        'date': '2026-07-18',
        'totalXp': 49,
      });
      final category = CategoryTimeTotal.fromMap({
        'mainCategoryName': 'Skills',
        'totalTimeSpent': 8.5,
      });
      final subcategory = SubcategoryTimeTotal.fromMap({
        'subcategoryName': 'Chess',
        'mainCategoryName': 'Skills',
        'totalTimeSpent': 101,
      });

      expect(point.totalXp, 49);
      expect(category.totalHours, 8.5);
      expect(subcategory.totalMinutes, 101);
    });
  });
}
