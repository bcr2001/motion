import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/tracking_time_policy.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

class DailyCategorySummary {
  const DailyCategorySummary({
    required this.name,
    required this.minutes,
    required this.xp,
  });

  final String name;
  final double minutes;
  final int xp;
}

class DailyStreakCheck {
  const DailyStreakCheck({
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.requirement,
    required this.trackedMinutes,
    required this.isMet,
    required this.isAtRisk,
  });

  final String subcategoryName;
  final String mainCategoryName;
  final double requirement;
  final double trackedMinutes;
  final bool isMet;
  final bool isAtRisk;
}

class DailyReviewData {
  const DailyReviewData({
    required this.entries,
    required this.xpBreakdown,
  });

  final List<Subcategories> entries;
  final Map<String, int> xpBreakdown;

  double get trackedMinutes => entries.fold<double>(
        0,
        (total, entry) => total + entry.timeSpent,
      );

  double get remainingMinutes =>
      (TrackingTimePolicy.maxDailyMinutes - trackedMinutes)
          .clamp(0, TrackingTimePolicy.maxDailyMinutes)
          .toDouble();

  double get trackedProgress =>
      (trackedMinutes / TrackingTimePolicy.maxDailyMinutes)
          .clamp(0, 1)
          .toDouble();

  int get totalXp => xpBreakdown.values.fold<int>(0, (sum, xp) => sum + xp);

  List<DailyCategorySummary> get categorySummaries {
    final totals = <String, double>{};
    for (final entry in entries) {
      totals.update(
        entry.mainCategoryName,
        (minutes) => minutes + entry.timeSpent,
        ifAbsent: () => entry.timeSpent,
      );
    }
    final summaries = totals.entries
        .map(
          (entry) => DailyCategorySummary(
            name: entry.key,
            minutes: entry.value,
            xp: xpBreakdown[entry.key] ?? 0,
          ),
        )
        .toList();
    summaries.sort((first, second) => second.minutes.compareTo(first.minutes));
    return summaries;
  }

  List<DailyStreakCheck> streakChecks({
    required List<Assigner> assignments,
    required String currentUser,
    required DateTime selectedDate,
    required DateTime today,
  }) {
    final totals = <String, double>{};
    for (final entry in entries) {
      totals.update(
        _subcategoryKey(entry.mainCategoryName, entry.subcategoryName),
        (minutes) => minutes + entry.timeSpent,
        ifAbsent: () => entry.timeSpent,
      );
    }

    final selectedDay = MotionDateUtils.dateOnly(selectedDate);
    final currentDay = MotionDateUtils.dateOnly(today);
    final checks = <DailyStreakCheck>[];
    for (final assignment in assignments) {
      if (assignment.currentLoggedInUser != currentUser ||
          assignment.isArchive == 1 ||
          assignment.isStreakActive != 1) {
        continue;
      }
      final tracked = totals[_subcategoryKey(
            assignment.mainCategoryName,
            assignment.subcategoryName,
          )] ??
          0;
      final streakType = SubcategoryStreakTypeValues.fromStoredValue(
        assignment.streakType,
      );
      final requirement = streakType == SubcategoryStreakType.targetTime
          ? assignment.streakTargetMinutes
          : 0.0;
      final isMet = streakType == SubcategoryStreakType.targetTime
          ? tracked >= requirement
          : tracked > 0;
      checks.add(DailyStreakCheck(
        subcategoryName: assignment.subcategoryName,
        mainCategoryName: assignment.mainCategoryName,
        requirement: requirement,
        trackedMinutes: tracked,
        isMet: isMet,
        isAtRisk: !isMet && selectedDay == currentDay,
      ));
    }
    checks.sort((first, second) {
      if (first.isMet != second.isMet) return first.isMet ? -1 : 1;
      return first.subcategoryName.compareTo(second.subcategoryName);
    });
    return checks;
  }

  static String _subcategoryKey(String mainCategory, String subcategory) =>
      '$mainCategory\u0000$subcategory';
}

class DailyReviewLoader {
  const DailyReviewLoader({
    required this.subcategoryProvider,
    required this.experienceProvider,
  });

  final SubcategoryTrackerDatabaseProvider subcategoryProvider;
  final ExperiencePointTableProvider experienceProvider;

  Future<DailyReviewData> load({
    required String currentUser,
    required String date,
  }) async {
    final results = await Future.wait<Object>([
      subcategoryProvider.retrieveSubcategoryEntriesForDate(
        date: date,
        currentUser: currentUser,
      ),
      experienceProvider.retrieveDailyExperiencePointBreakdown(
        currentUser: currentUser,
        selectedDate: date,
      ),
    ]);
    return DailyReviewData(
      entries: results[0] as List<Subcategories>,
      xpBreakdown: results[1] as Map<String, int>,
    );
  }
}
