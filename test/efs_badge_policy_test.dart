import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';

void main() {
  group('EfsBadgePolicy', () {
    test('assigns badges for the expected EFS ranges', () {
      expect(
        EfsBadgePolicy.badgeForScore(0).level,
        EfsBadgeLevel.timeNovice,
      );
      expect(
        EfsBadgePolicy.badgeForScore(19.99).level,
        EfsBadgeLevel.timeNovice,
      );
      expect(
        EfsBadgePolicy.badgeForScore(20).level,
        EfsBadgeLevel.focusedBeginner,
      );
      expect(
        EfsBadgePolicy.badgeForScore(39.99).level,
        EfsBadgeLevel.focusedBeginner,
      );
      expect(
        EfsBadgePolicy.badgeForScore(40).level,
        EfsBadgeLevel.timePro,
      );
      expect(
        EfsBadgePolicy.badgeForScore(59.99).level,
        EfsBadgeLevel.timePro,
      );
      expect(
        EfsBadgePolicy.badgeForScore(60).level,
        EfsBadgeLevel.timeMaster,
      );
      expect(
        EfsBadgePolicy.badgeForScore(79.99).level,
        EfsBadgeLevel.timeMaster,
      );
      expect(
        EfsBadgePolicy.badgeForScore(80).level,
        EfsBadgeLevel.timeWizard,
      );
    });

    test('keeps out-of-range scores inside the supported badge set', () {
      expect(
        EfsBadgePolicy.badgeForScore(-1).level,
        EfsBadgeLevel.timeNovice,
      );
      expect(
        EfsBadgePolicy.badgeForScore(105).level,
        EfsBadgeLevel.timeWizard,
      );
    });

    test('splits daily XP targets across XP-earning categories', () {
      final targets = EfsBadgePolicy.dailyXpTargets(72);

      expect(
        targets.map((target) => target.label),
        [
          'Education',
          'Work',
          'Skills',
          'Self Development',
          'Sleep',
          'Tracking Bonus',
        ],
      );
      expect(
        targets.fold<int>(0, (total, target) => total + target.xp),
        72,
      );
    });

    test('caps daily XP targets at the maximum possible daily XP', () {
      final targets =
          EfsBadgePolicy.dailyXpTargets(MotionXpPolicy.maxDailyXp + 50);

      expect(
        targets.fold<int>(0, (total, target) => total + target.xp),
        MotionXpPolicy.maxDailyXp,
      );
    });

    test('keeps the daily badge pace stable within the same badge band', () {
      final firstCalculation = EfsBadgePolicy.nextBadgeProgress(
        currentScore: 30,
        currentYearXp: 690,
        trackedDays: 20,
        recentAverageDailyXp: 75,
        today: DateTime(2026, 12, 22),
      );
      final afterEarningXpToday = EfsBadgePolicy.nextBadgeProgress(
        currentScore: 35,
        currentYearXp: 690,
        trackedDays: 20,
        recentAverageDailyXp: 75,
        today: DateTime(2026, 12, 22),
      );

      expect(firstCalculation.daysRemaining, 10);
      expect(firstCalculation.averageDailyXp, 69);
      expect(afterEarningXpToday.averageDailyXp, 69);
      expect(
        firstCalculation.paceDifficulty,
        BadgePaceDifficulty.comfortable,
      );
    });

    test('does not expose an impossible pace as a daily target', () {
      final progress = EfsBadgePolicy.nextBadgeProgress(
        currentScore: 60,
        currentYearXp: 6900,
        trackedDays: 100,
        recentAverageDailyXp: 70,
        today: DateTime(2026, 12, 31),
      );

      expect(progress.averageDailyXp, greaterThan(MotionXpPolicy.maxDailyXp));
      expect(progress.isAttainableThisYear, isFalse);
      expect(
        progress.paceDifficulty,
        BadgePaceDifficulty.notAttainable,
      );
      expect(EfsBadgePolicy.actionableDailyTarget(progress), 0);
    });

    test('uses a sustainable maintenance target for the top badge', () {
      final progress = EfsBadgePolicy.nextBadgeProgress(
        currentScore: 84,
        currentYearXp: 5000,
        trackedDays: 60,
        recentAverageDailyXp: 90,
        today: DateTime(2026, 8, 10),
      );

      expect(progress.isTopBadge, isTrue);
      expect(progress.targetScore, 80);
      expect(progress.averageDailyXp, 92);
      expect(progress.paceDifficulty, BadgePaceDifficulty.maintenance);
      expect(EfsBadgePolicy.actionableDailyTarget(progress), 92);
    });
  });
}
