import 'package:flutter_test/flutter_test.dart';
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
  });
}
