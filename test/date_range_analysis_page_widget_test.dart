import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_analytics/analytics_models.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_screens/ms_analysis/date_range_analysis_page.dart';
import 'package:provider/provider.dart';

class _EmptyMainCategoryProvider extends MainCategoryTrackerProvider {
  @override
  Future<ReportSnapshot> retrieveReportSnapshot({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    return ReportSnapshot.empty;
  }

  @override
  Future<List<DailyXpPoint>> retrieveDailyXpTrendPoints({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    return const [];
  }

  @override
  Future<List<CategoryTimeTotal>> retrieveCategoryTimeTotalsForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    return const [];
  }

  @override
  Future<List<SubcategoryTimeTotal>> retrieveTopSubcategoryTotalsForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
    int limit = 5,
  }) async {
    return const [];
  }
}

class _EmptySubcategoryProvider extends SubcategoryTrackerDatabaseProvider {
  @override
  Future<double> retrieveMonthTotalTimeSpent(
    String currentUser,
    String firstDay,
    String lastDay,
  ) async {
    return 0;
  }
}

void main() {
  testWidgets('date range page shows a useful empty state', (tester) async {
    final mainProvider = _EmptyMainCategoryProvider();
    final subcategoryProvider = _EmptySubcategoryProvider();
    addTearDown(mainProvider.dispose);
    addTearDown(subcategoryProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: UserUidProvider(
              initialUserUid: 'user-1',
              isInitialized: true,
            ),
          ),
          ChangeNotifierProvider<MainCategoryTrackerProvider>.value(
            value: mainProvider,
          ),
          ChangeNotifierProvider<SubcategoryTrackerDatabaseProvider>.value(
            value: subcategoryProvider,
          ),
        ],
        child: const MaterialApp(home: DateRangeAnalysisPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Date Range Analysis'), findsOneWidget);
    expect(find.text('No data in this range'), findsOneWidget);
    expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
  });
}
