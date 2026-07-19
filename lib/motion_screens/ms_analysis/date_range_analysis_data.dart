import 'package:motion/motion_core/mc_analytics/analytics_models.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

class DateRangeAnalysisData {
  final ReportSnapshot snapshot;
  final List<DailyXpPoint> dailyXpTrend;
  final List<CategoryTimeTotal> mainCategoryBreakdown;
  final List<SubcategoryTimeTotal> topSubcategories;
  final double totalTrackedMinutes;
  final int totalSelectedDays;

  const DateRangeAnalysisData({
    required this.snapshot,
    required this.dailyXpTrend,
    required this.mainCategoryBreakdown,
    required this.topSubcategories,
    required this.totalTrackedMinutes,
    required this.totalSelectedDays,
  });

  bool get hasTrackedData => totalTrackedMinutes > 0 || totalXp > 0;
  int get trackedDays => snapshot.trackedDays;
  int get totalXp => snapshot.totalXp;
  double get efsScore => snapshot.efficiencyScore;
  double get averageTrackedMinutes =>
      trackedDays <= 0 ? 0 : totalTrackedMinutes / trackedDays;
}

class DateRangeAnalysisLoader {
  final MainCategoryTrackerProvider mainProvider;
  final SubcategoryTrackerDatabaseProvider subcategoryProvider;

  const DateRangeAnalysisLoader({
    required this.mainProvider,
    required this.subcategoryProvider,
  });

  Future<DateRangeAnalysisData> load({
    required String currentUser,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final firstDay = MotionDateUtils.formatDbDate(startDate);
    final lastDay = MotionDateUtils.formatDbDate(endDate);

    final results = await Future.wait<Object>([
      mainProvider.retrieveReportSnapshot(
        currentUser: currentUser,
        firstDay: firstDay,
        lastDay: lastDay,
      ),
      mainProvider.retrieveDailyXpTrendPoints(
        currentUser: currentUser,
        firstDay: firstDay,
        lastDay: lastDay,
      ),
      mainProvider.retrieveCategoryTimeTotalsForPeriod(
        currentUser: currentUser,
        firstDay: firstDay,
        lastDay: lastDay,
      ),
      mainProvider.retrieveTopSubcategoryTotalsForPeriod(
        currentUser: currentUser,
        firstDay: firstDay,
        lastDay: lastDay,
        limit: 8,
      ),
      subcategoryProvider.retrieveMonthTotalTimeSpent(
        currentUser,
        firstDay,
        lastDay,
      ),
    ]);

    return DateRangeAnalysisData(
      snapshot: results[0] as ReportSnapshot,
      dailyXpTrend: results[1] as List<DailyXpPoint>,
      mainCategoryBreakdown: results[2] as List<CategoryTimeTotal>,
      topSubcategories: results[3] as List<SubcategoryTimeTotal>,
      totalTrackedMinutes: results[4] as double,
      totalSelectedDays: MotionDateUtils.inclusiveDaysBetween(
        startDate,
        endDate,
      ),
    );
  }
}
