import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

void main() {
  group('database model mappings', () {
    test('MainCategory maps to SQLite column names', () {
      final category = MainCategory(
        date: '2026-06-04',
        education: 10,
        work: 20,
        skills: 30,
        entertainment: 40,
        selfDevelopment: 50,
        sleep: 60,
        currentLoggedInUser: 'user-1',
      );

      final map = category.toMap();

      expect(map[MotionDbColumns.date], '2026-06-04');
      expect(map[MotionDbColumns.education], 10);
      expect(map[MotionDbColumns.work], 20);
      expect(map[MotionDbColumns.skills], 30);
      expect(map[MotionDbColumns.entertainment], 40);
      expect(map[MotionDbColumns.selfDevelopment], 50);
      expect(map[MotionDbColumns.sleep], 60);
      expect(map[MotionDbColumns.currentLoggedInUser], 'user-1');
      expect(MainCategory.fromMap(map).toMap(), map);
    });

    test('Subcategories maps to SQLite column names', () {
      final subcategory = Subcategories(
        id: 7,
        date: '2026-06-04',
        mainCategoryName: MotionCategories.skills,
        subcategoryName: 'Coding',
        timeSpent: 90,
        currentLoggedInUser: 'user-1',
      );

      final map = subcategory.toMap();
      final withId = {MotionDbColumns.id: subcategory.id, ...map};

      expect(map[MotionDbColumns.date], '2026-06-04');
      expect(map[MotionDbColumns.mainCategoryName], MotionCategories.skills);
      expect(map[MotionDbColumns.subcategoryName], 'Coding');
      expect(map[MotionDbColumns.timeSpent], 90);
      expect(map[MotionDbColumns.currentLoggedInUser], 'user-1');
      expect(Subcategories.fromMap(withId).id, 7);
      expect(Subcategories.fromMap(withId).toMap(), map);
    });

    test('ExperiencePoints maps to SQLite column names', () {
      final xp = ExperiencePoints(
        date: '2026-06-04',
        educationXP: 5,
        workXP: 10,
        skillsXP: 15,
        sdXP: 20,
        sleepXP: 25,
        accountabilityBonusXP: 5,
        currentLoggedInUser: 'user-1',
      );

      final map = xp.toMap();

      expect(map[MotionDbColumns.educationXp], 5);
      expect(map[MotionDbColumns.workXp], 10);
      expect(map[MotionDbColumns.skillsXp], 15);
      expect(map[MotionDbColumns.selfDevelopmentXp], 20);
      expect(map[MotionDbColumns.sleepXp], 25);
      expect(map[MotionDbColumns.accountabilityBonusXp], 5);
      expect(ExperiencePoints.fromMap(map).toMap(), map);
    });

    test('Assigner maps to SQLite column names', () {
      final assigner = Assigner(
        id: 3,
        currentLoggedInUser: 'user-1',
        subcategoryName: 'Coding',
        mainCategoryName: MotionCategories.skills,
        dateCreated: '2026-06-04',
        isActive: 1,
        isArchive: 0,
        isStreakActive: 1,
        streakType: 'target_time',
        streakTargetMinutes: 45,
        streakStartDate: '2026-06-12',
      );

      final map = assigner.toMap();
      final withId = {MotionDbColumns.id: assigner.id, ...map};

      expect(map[MotionDbColumns.currentLoggedInUser], 'user-1');
      expect(map[MotionDbColumns.subcategoryName], 'Coding');
      expect(map[MotionDbColumns.mainCategoryName], MotionCategories.skills);
      expect(map[MotionDbColumns.dateCreated], '2026-06-04');
      expect(map[MotionDbColumns.isActive], 1);
      expect(map[MotionDbColumns.isArchive], 0);
      expect(map[MotionDbColumns.isStreakActive], 1);
      expect(map[MotionDbColumns.streakType], 'target_time');
      expect(map[MotionDbColumns.streakTargetMinutes], 45);
      expect(map[MotionDbColumns.streakStartDate], '2026-06-12');
      expect(Assigner.fromAssignerMap(withId).toMap(), map);
    });
  });
}
