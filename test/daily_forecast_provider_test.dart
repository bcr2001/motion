import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/motion_providers/ai_pvd/daily_forecast_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unread state persists until a meaningful forecast change', () async {
    SharedPreferences.setMockInitialValues({});
    final xpProvider = _ForecastExperienceProvider();
    final provider = DailyForecastProvider(xpProvider: xpProvider);
    addTearDown(provider.dispose);
    addTearDown(xpProvider.dispose);

    await provider.refresh(
      currentUser: 'user-1',
      currentDate: '2026-08-10',
      currentYear: '2026',
      experienceRevision: 0,
    );

    expect(
      provider.isUnreadFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isTrue,
    );
    expect(
      provider.changeFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isNotNull,
    );

    await provider.markSeen(
      currentUser: 'user-1',
      currentDate: '2026-08-10',
    );
    expect(
      provider.isUnreadFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isFalse,
    );
    expect(
      provider.changeFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isNotNull,
    );
    provider.clearDisplayedChange(
      currentUser: 'user-1',
      currentDate: '2026-08-10',
    );

    await provider.refresh(
      currentUser: 'user-1',
      currentDate: '2026-08-10',
      currentYear: '2026',
      experienceRevision: 0,
      force: true,
    );
    expect(
      provider.isUnreadFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isFalse,
    );

    xpProvider.todayXp = 80;
    xpProvider.todayBreakdown = const {
      'Education': 20,
      'Work': 10,
      'Skills': 20,
      'Self Development': 10,
      'Sleep': 15,
      'Tracking Bonus': 5,
    };
    await provider.refresh(
      currentUser: 'user-1',
      currentDate: '2026-08-10',
      currentYear: '2026',
      experienceRevision: 1,
    );

    expect(
      provider.isUnreadFor(
        currentUser: 'user-1',
        currentDate: '2026-08-10',
      ),
      isTrue,
    );
  });
}

class _ForecastExperienceProvider extends ExperiencePointTableProvider {
  int todayXp = 35;
  Map<String, int> todayBreakdown = const {
    'Education': 8,
    'Work': 0,
    'Skills': 9,
    'Self Development': 0,
    'Sleep': 15,
    'Tracking Bonus': 3,
  };

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
    return todayBreakdown;
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
    return todayXp;
  }
}
