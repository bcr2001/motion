import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';

void main() {
  group('MotionXpPolicy', () {
    test('defines the maximum daily XP used to normalize EFS', () {
      expect(MotionXpPolicy.maxDailyXp, 115);
    });

    test('awards Work XP at one point per 12 minutes up to 25 XP', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 120), 10);
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 300), 25);
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 600), 25);
    });

    test('caps learning and growth categories at 20 XP', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.education, 120), 10);
      expect(MotionXpPolicy.categoryXp(MotionCategories.skills, 240), 20);
      expect(
        MotionXpPolicy.categoryXp(MotionCategories.selfDevelopment, 600),
        20,
      );
    });

    test('does not award Entertainment XP', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.entertainment, 600), 0);
    });

    test('awards Sleep XP by healthy duration range', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 299), 0);
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 330), 8);
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 390), 15);
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 480), 25);
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 570), 15);
      expect(MotionXpPolicy.categoryXp(MotionCategories.sleep, 660), 5);
    });

    test('awards accountability bonus XP for well-accounted days', () {
      expect(MotionXpPolicy.accountabilityBonusXp(479), 0);
      expect(MotionXpPolicy.accountabilityBonusXp(480), 1);
      expect(MotionXpPolicy.accountabilityBonusXp(600), 2);
      expect(MotionXpPolicy.accountabilityBonusXp(720), 3);
      expect(MotionXpPolicy.accountabilityBonusXp(840), 4);
      expect(MotionXpPolicy.accountabilityBonusXp(960), 5);
    });
  });
}
