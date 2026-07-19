import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_analytics/analytics_models.dart';
import 'package:motion/motion_screens/ms_analysis/date_range_analysis_data.dart';

void main() {
  test('date range summary derives averages from typed values', () {
    const data = DateRangeAnalysisData(
      snapshot: ReportSnapshot(
        trackedDays: 4,
        accountedMinutes: 480,
        unaccountedMinutes: 0,
        totalXp: 80,
        xpDays: 4,
        efficiencyScore: 50,
        bestDay: '2026-07-04',
        bestDayXp: 25,
        lowestDay: '2026-07-01',
        lowestDayXp: 12,
      ),
      dailyXpTrend: [],
      mainCategoryBreakdown: [],
      topSubcategories: [],
      totalTrackedMinutes: 480,
      totalSelectedDays: 7,
    );

    expect(data.hasTrackedData, isTrue);
    expect(data.averageTrackedMinutes, 120);
    expect(data.totalXp, 80);
  });
}
