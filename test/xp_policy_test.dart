import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';

void main() {
  group('MotionXpPolicy', () {
    test('awards Work XP at one point per 15 minutes up to 25 XP', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 120), 8);
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 375), 25);
      expect(MotionXpPolicy.categoryXp(MotionCategories.work, 600), 25);
    });

    test('caps learning and growth categories at 20 XP', () {
      expect(MotionXpPolicy.categoryXp(MotionCategories.education, 120), 8);
      expect(MotionXpPolicy.categoryXp(MotionCategories.skills, 375), 20);
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
  });
}
