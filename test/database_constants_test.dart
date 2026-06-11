import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

void main() {
  group('database constants', () {
    test('table names match the persisted SQLite tables', () {
      expect(MotionDbTables.mainCategory, 'main_category');
      expect(MotionDbTables.subcategory, 'subcategory');
      expect(MotionDbTables.experiencePoints, 'experience_points');
      expect(MotionDbTables.assigner, 'to_assign');
    });

    test('category names match persisted category values', () {
      expect(MotionCategories.education, 'Education');
      expect(MotionCategories.work, 'Work');
      expect(MotionCategories.skills, 'Skills');
      expect(MotionCategories.entertainment, 'Entertainment');
      expect(MotionCategories.selfDevelopment, 'Self Development');
      expect(MotionCategories.sleep, 'Sleep');
    });

    test('XP column names match the persisted SQLite columns', () {
      expect(MotionDbColumns.accountabilityBonusXp, 'accountabilityBonusXP');
    });
  });
}
