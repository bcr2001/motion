import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/current_user_guard.dart';

void main() {
  group('current user guard', () {
    test('trims and returns a non-empty user id', () {
      expect(requireCurrentUser(' uid-123 '), 'uid-123');
    });

    test('throws for an empty user id', () {
      expect(() => requireCurrentUser('   '), throwsArgumentError);
    });

    test('validates model user ids before writes', () {
      expect(
        requireMainCategoryUser(
          MainCategory(date: '2026-06-04', currentLoggedInUser: 'uid-123'),
        ),
        isA<MainCategory>(),
      );
      expect(
        requireSubcategoryUser(
          Subcategories(
            date: '2026-06-04',
            mainCategoryName: 'Education',
            subcategoryName: 'Math',
            currentLoggedInUser: 'uid-123',
          ),
        ),
        isA<Subcategories>(),
      );
      expect(
        requireExperienceUser(
          ExperiencePoints(
            date: '2026-06-04',
            currentLoggedInUser: 'uid-123',
          ),
        ),
        isA<ExperiencePoints>(),
      );
      expect(
        requireAssignerUser(
          Assigner(
            currentLoggedInUser: 'uid-123',
            subcategoryName: 'Math',
            mainCategoryName: 'Education',
            dateCreated: '2026-06-04',
          ),
        ),
        isA<Assigner>(),
      );
    });
  });
}
