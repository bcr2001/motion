import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';

void main() {
  group('TrackerDatabaseSchema', () {
    test(
        'includes trigger coverage for subcategory inserts, updates, and deletes',
        () {
      expect(
        TrackerDatabaseSchema.triggerNames,
        containsAll(<String>[
          'update_experience_points',
          'update_experience_points_after_update',
          'update_experience_points_after_delete',
          'update_main_category',
          'update_main_category_after_update',
          'update_main_category_after_delete',
        ]),
      );
    });
  });
}
