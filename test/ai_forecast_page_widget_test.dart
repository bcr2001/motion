import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/motion_providers/ai_pvd/daily_forecast_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/calendar_clock.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calendarClock = CalendarClock.instance;

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'AI action precedes Report and opens the forecast in ${brightness.name} mode',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final xpProvider = _ForecastWidgetExperienceProvider();
        final forecastProvider = DailyForecastProvider(
          xpProvider: xpProvider,
        );
        final userProvider = UserUidProvider(
          initialUserUid: 'user-1',
          isInitialized: true,
        );
        final dateProvider = CurrentDateProvider(clock: calendarClock);
        final yearProvider = CurrentYearProvider(clock: calendarClock);
        addTearDown(xpProvider.dispose);
        addTearDown(forecastProvider.dispose);
        addTearDown(userProvider.dispose);
        addTearDown(dateProvider.dispose);
        addTearDown(yearProvider.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ExperiencePointTableProvider>.value(
                value: xpProvider,
              ),
              ChangeNotifierProvider.value(value: forecastProvider),
              ChangeNotifierProvider.value(value: userProvider),
              ChangeNotifierProvider.value(value: dateProvider),
              ChangeNotifierProvider.value(value: yearProvider),
            ],
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                useMaterial3: true,
              ),
              home: Scaffold(
                appBar: AppBar(actions: const [MotionActionButtons()]),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final aiButton = find.widgetWithText(TextButton, 'AI');
        final reportButton = find.byTooltip('Monthly Report');
        expect(aiButton, findsOneWidget);
        expect(reportButton, findsOneWidget);
        expect(
          tester.getCenter(aiButton).dx,
          lessThan(tester.getCenter(reportButton).dx),
        );
        expect(find.bySemanticsLabel('New AI forecast available'), findsOne);

        await tester.tap(aiButton);
        await tester.pumpAndSettle();

        expect(find.text('AI Forecast'), findsOneWidget);
        expect(find.text("Today's Outlook"), findsOneWidget);
        expect(find.text('What Changed'), findsOneWidget);
        expect(find.text('Best Next Move'), findsOneWidget);
        expect(find.text('Recommended Focus'), findsOneWidget);
        final refreshIndicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );
        expect(refreshIndicator.color, const Color(0xFF00B0F0));
        expect(
          refreshIndicator.backgroundColor,
          brightness == Brightness.dark
              ? const Color(0xFF1B202E)
              : const Color(0xFFF5F5FF),
        );
        expect(refreshIndicator.elevation, 1);
        expect(refreshIndicator.strokeWidth, 2.4);
        await tester.scrollUntilVisible(
          find.text('Why This Forecast'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Why This Forecast'), findsOneWidget);
        expect(find.textContaining('Est. time remaining:'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _ForecastWidgetExperienceProvider extends ExperiencePointTableProvider {
  @override
  Future<List<ExperiencePoints>> retrieveExperiencePointHistory({
    required String currentUser,
    required String firstDate,
    required String lastDate,
  }) async {
    final date = MotionDateUtils.parseStoredDate(lastDate)!;
    return List.generate(90, (index) {
      final historyDate = date.subtract(Duration(days: 90 - index));
      return ExperiencePoints(
        date: MotionDateUtils.formatDbDate(historyDate),
        educationXP: 10,
        workXP: 4,
        skillsXP: 12,
        sdXP: 4,
        sleepXP: 15,
        accountabilityBonusXP: 3,
        currentLoggedInUser: currentUser,
      );
    });
  }

  @override
  Future<double> retrieveYearExperiencePointsEfficiencyScore({
    required String currentUser,
    required String currentYear,
  }) async {
    return 45;
  }

  @override
  Future<Map<String, int>> retrieveDailyExperiencePointBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    return const {
      'Education': 8,
      'Work': 0,
      'Skills': 9,
      'Self Development': 0,
      'Sleep': 15,
      'Tracking Bonus': 3,
    };
  }

  @override
  Future<Map<String, double>> retrieveDailyMainCategoryTimeBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    return const {
      'Education': 96,
      'Work': 0,
      'Skills': 108,
      'Self Development': 0,
      'Sleep': 360,
      'Tracking Bonus': 564,
    };
  }

  @override
  Future<int> retrieveYearExperiencePointsBeforeDate({
    required String currentUser,
    required String year,
    required String beforeDate,
  }) async {
    return 14000;
  }

  @override
  Future<int> retrieveYearExperiencePointDaysBeforeDate({
    required String currentUser,
    required String year,
    required String beforeDate,
  }) async {
    return 220;
  }

  @override
  Future<double> retrieveAverageDailyExperiencePoints({
    required String currentUser,
    required String firstDate,
    required String lastDate,
  }) async {
    return 55;
  }

  @override
  Future<int> retrieveDailyExperiencePoints({
    required currentUser,
    required String selectedDate,
  }) async {
    return 35;
  }
}
