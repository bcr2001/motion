import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/motion_ai/personalized_daily_forecast.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

void main() {
  group('PersonalizedDailyForecastPolicy', () {
    final forecastDate = DateTime(2026, 8, 10);

    test('builds a bounded personalized forecast from sufficient history', () {
      final forecast = PersonalizedDailyForecastPolicy.forecast(
        date: forecastDate,
        history: _historyBefore(forecastDate, days: 90),
        todayBreakdown: const {
          'Education': 8,
          'Work': 0,
          'Skills': 7,
          'Self Development': 0,
          'Sleep': 15,
          'Tracking Bonus': 2,
        },
        todayTrackedMinutes: const {
          'Education': 96,
          'Skills': 84,
          'Sleep': 360,
        },
        earnedXp: 32,
        targetXp: 58,
      );

      expect(forecast.hasEnoughHistory, isTrue);
      expect(forecast.lowerXp, greaterThanOrEqualTo(forecast.earnedXp));
      expect(forecast.upperXp, lessThanOrEqualTo(115));
      expect(forecast.lowerXp, lessThanOrEqualTo(forecast.upperXp));
      expect(forecast.targetProbability, isNotNull);
      expect(forecast.focus, isNotEmpty);
      expect(forecast.focus.length, lessThanOrEqualTo(3));
      expect(forecast.bestNextMove, isNotNull);
      expect(forecast.bestNextMove!.minutesRequired, greaterThan(0));
      expect(
        forecast.focus.where((item) => item.targetMinutes > 0),
        isNotEmpty,
      );
      expect(forecast.factors, hasLength(3));
    });

    test('does not manufacture confidence from a short history', () {
      final forecast = PersonalizedDailyForecastPolicy.forecast(
        date: forecastDate,
        history: _historyBefore(forecastDate, days: 8),
        todayBreakdown: const {'Skills': 5},
        earnedXp: 5,
        targetXp: 60,
      );

      expect(forecast.hasEnoughHistory, isFalse);
      expect(forecast.status, DailyForecastStatus.learning);
      expect(forecast.predictedXp, 5);
      expect(forecast.targetProbability, isNull);
    });

    test('never forecasts below XP already earned', () {
      final forecast = PersonalizedDailyForecastPolicy.forecast(
        date: forecastDate,
        history: _historyBefore(forecastDate, days: 90),
        todayBreakdown: const {
          'Education': 20,
          'Work': 20,
          'Skills': 20,
          'Self Development': 10,
          'Sleep': 15,
          'Tracking Bonus': 5,
        },
        earnedXp: 90,
        targetXp: 80,
      );

      expect(forecast.predictedXp, greaterThanOrEqualTo(90));
      expect(forecast.lowerXp, 90);
      expect(forecast.status, DailyForecastStatus.targetAchieved);
      expect(forecast.targetProbability, 1);
    });
  });

  group('DailyForecastAttentionPolicy', () {
    const seen = DailyForecastAttentionSnapshot(
      date: '2026-08-10',
      predictedXp: 60,
      targetXp: 65,
      targetProbability: 0.55,
      status: DailyForecastStatus.withinReach,
      primaryFocus: 'Skills',
    );

    test('ignores small forecast movements', () {
      const current = DailyForecastAttentionSnapshot(
        date: '2026-08-10',
        predictedXp: 64,
        targetXp: 65,
        targetProbability: 0.64,
        status: DailyForecastStatus.withinReach,
        primaryFocus: 'Skills',
      );

      expect(
        DailyForecastAttentionPolicy.hasMeaningfulChange(
          lastSeen: seen,
          current: current,
        ),
        isFalse,
      );
    });

    test('flags status, priority, and threshold changes', () {
      const changedStatus = DailyForecastAttentionSnapshot(
        date: '2026-08-10',
        predictedXp: 60,
        targetXp: 65,
        targetProbability: 0.72,
        status: DailyForecastStatus.onTrack,
        primaryFocus: 'Skills',
      );
      const changedPriority = DailyForecastAttentionSnapshot(
        date: '2026-08-10',
        predictedXp: 60,
        targetXp: 65,
        targetProbability: 0.55,
        status: DailyForecastStatus.withinReach,
        primaryFocus: 'Education',
      );
      const changedPrediction = DailyForecastAttentionSnapshot(
        date: '2026-08-10',
        predictedXp: 65,
        targetXp: 65,
        targetProbability: 0.55,
        status: DailyForecastStatus.withinReach,
        primaryFocus: 'Skills',
      );

      for (final current in [
        changedStatus,
        changedPriority,
        changedPrediction,
      ]) {
        expect(
          DailyForecastAttentionPolicy.hasMeaningfulChange(
            lastSeen: seen,
            current: current,
          ),
          isTrue,
        );
      }
    });

    test('flags every new daily forecast once', () {
      const current = DailyForecastAttentionSnapshot(
        date: '2026-08-11',
        predictedXp: 60,
        targetXp: 65,
        targetProbability: 0.55,
        status: DailyForecastStatus.withinReach,
        primaryFocus: 'Skills',
      );

      expect(
        DailyForecastAttentionPolicy.hasMeaningfulChange(
          lastSeen: seen,
          current: current,
        ),
        isTrue,
      );
    });

    test('describes meaningful forecast improvements', () {
      const current = DailyForecastAttentionSnapshot(
        date: '2026-08-10',
        predictedXp: 68,
        lowerXp: 62,
        upperXp: 74,
        targetXp: 65,
        targetProbability: 0.76,
        status: DailyForecastStatus.onTrack,
        primaryFocus: 'Education',
      );

      final change = DailyForecastChange.between(
        lastSeen: seen,
        current: current,
      );

      expect(change, isNotNull);
      expect(change!.tone, DailyForecastChangeTone.positive);
      expect(change.title, 'Your outlook improved');
      expect(
        change.details.any((detail) => detail.contains('Target likelihood')),
        isTrue,
      );
    });
  });
}

List<ExperiencePoints> _historyBefore(DateTime date, {required int days}) {
  return List.generate(days, (index) {
    final historyDate = date.subtract(Duration(days: days - index));
    final weekdayAdjustment = historyDate.weekday.isEven ? 4 : 0;
    return ExperiencePoints(
      date: MotionDateUtils.formatDbDate(historyDate),
      educationXP: 10 + weekdayAdjustment,
      workXP: 4,
      skillsXP: 12,
      sdXP: 4,
      sleepXP: 15,
      accountabilityBonusXP: 3,
      currentLoggedInUser: 'user-1',
    );
  });
}
