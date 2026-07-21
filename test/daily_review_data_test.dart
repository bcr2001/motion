import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_screens/ms_daily_review/daily_review_data.dart';

void main() {
  group('DailyReviewData', () {
    final entries = [
      Subcategories(
        id: 1,
        date: '2026-07-20',
        mainCategoryName: 'Skills',
        subcategoryName: 'Chess',
        timeSpent: 90,
        currentLoggedInUser: 'user-1',
      ),
      Subcategories(
        id: 2,
        date: '2026-07-20',
        mainCategoryName: 'Sleep',
        subcategoryName: 'Sleep',
        timeSpent: 480,
        currentLoggedInUser: 'user-1',
      ),
    ];

    test('derives 24-hour, XP, and ordered category summaries', () {
      final data = DailyReviewData(
        entries: entries,
        xpBreakdown: const {
          'Skills': 7,
          'Sleep': 25,
          'Tracking Bonus': 1,
        },
      );

      expect(data.trackedMinutes, 570);
      expect(data.remainingMinutes, 870);
      expect(data.trackedProgress, closeTo(570 / 1440, 0.0001));
      expect(data.totalXp, 33);
      expect(data.categorySummaries.map((item) => item.name), [
        'Sleep',
        'Skills',
      ]);
      expect(data.categorySummaries.last.xp, 7);
    });

    test('reports met and at-risk streak requirements for today', () {
      final data = DailyReviewData(
        entries: entries,
        xpBreakdown: const {},
      );
      final assignments = [
        Assigner(
          currentLoggedInUser: 'user-1',
          subcategoryName: 'Chess',
          mainCategoryName: 'Skills',
          dateCreated: '2026-01-01',
          isStreakActive: 1,
          streakType: SubcategoryStreakTypeValues.targetTime,
          streakTargetMinutes: 60,
        ),
        Assigner(
          currentLoggedInUser: 'user-1',
          subcategoryName: 'Reading',
          mainCategoryName: 'Self Development',
          dateCreated: '2026-01-01',
          isStreakActive: 1,
          streakType: SubcategoryStreakTypeValues.anyTime,
        ),
      ];

      final checks = data.streakChecks(
        assignments: assignments,
        currentUser: 'user-1',
        selectedDate: DateTime(2026, 7, 20),
        today: DateTime(2026, 7, 20),
      );

      expect(checks, hasLength(2));
      expect(checks.first.subcategoryName, 'Chess');
      expect(checks.first.isMet, isTrue);
      expect(checks.last.subcategoryName, 'Reading');
      expect(checks.last.isAtRisk, isTrue);
    });

    test('labels an unmet historical streak as missed', () {
      const data = DailyReviewData(entries: [], xpBreakdown: {});
      final checks = data.streakChecks(
        assignments: [
          Assigner(
            currentLoggedInUser: 'user-1',
            subcategoryName: 'Reading',
            mainCategoryName: 'Self Development',
            dateCreated: '2026-01-01',
            isStreakActive: 1,
            streakType: SubcategoryStreakTypeValues.anyTime,
          ),
        ],
        currentUser: 'user-1',
        selectedDate: DateTime(2026, 7, 19),
        today: DateTime(2026, 7, 20),
      );

      expect(checks.single.isMet, isFalse);
      expect(checks.single.isAtRisk, isFalse);
    });
  });
}
