import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';

void main() {
  group('TrackerDatabaseSchema', () {
    test('uses version 16 after adding tracked-time limits', () {
      expect(TrackerDatabaseSchema.version, 16);
    });

    test('defines the active timer session table', () {
      expect(
        TrackerDatabaseSchema.activeTimerSessionTable,
        'active_timer_session',
      );
    });

    test(
        'includes trigger coverage for subcategory inserts, updates, and deletes',
        () {
      expect(
        TrackerDatabaseSchema.triggerNames,
        containsAll(<String>[
          'validate_subcategory_time_insert',
          'validate_subcategory_daily_total_insert',
          'validate_subcategory_time_update',
          'validate_subcategory_daily_total_update',
          'update_experience_points',
          'update_experience_points_after_update',
          'update_experience_points_after_delete',
          'update_main_category',
          'update_main_category_after_update',
          'update_main_category_after_delete',
        ]),
      );
    });

    test('includes indexes for common user and date queries', () {
      expect(
        TrackerDatabaseSchema.indexNames,
        containsAll(<String>[
          'idx_main_category_user_date',
          'idx_experience_points_user_date',
          'idx_subcategory_user_date',
          'idx_subcategory_user_date_main_category',
          'idx_subcategory_user_date_subcategory',
        ]),
      );
    });
  });
}
