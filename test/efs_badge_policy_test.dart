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
        EfsBadgePolicy.badgeForScore(24.99).level,
        EfsBadgeLevel.timeNovice,
      );
      expect(
        EfsBadgePolicy.badgeForScore(25).level,
        EfsBadgeLevel.focusedBeginner,
      );
      expect(
        EfsBadgePolicy.badgeForScore(49.99).level,
        EfsBadgeLevel.focusedBeginner,
      );
      expect(
        EfsBadgePolicy.badgeForScore(50).level,
        EfsBadgeLevel.timePro,
      );
      expect(
        EfsBadgePolicy.badgeForScore(74.99).level,
        EfsBadgeLevel.timePro,
      );
      expect(
        EfsBadgePolicy.badgeForScore(75).level,
        EfsBadgeLevel.timeMaster,
      );
      expect(
        EfsBadgePolicy.badgeForScore(99.99).level,
        EfsBadgeLevel.timeMaster,
      );
      expect(
        EfsBadgePolicy.badgeForScore(100).level,
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
  });
}
