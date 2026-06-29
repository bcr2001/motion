import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/tracking_data_revisions.dart';

void main() {
  group('tracking provider refresh coordination', () {
    late TrackingDataRevisions revisions;
    late MainCategoryTrackerProvider mainProvider;
    late SubcategoryTrackerDatabaseProvider subcategoryProvider;
    late ExperiencePointTableProvider experienceProvider;
    late int mainNotifications;
    late int subcategoryNotifications;
    late int experienceNotifications;

    setUp(() {
      revisions = TrackingDataRevisions();
      mainProvider = MainCategoryTrackerProvider(revisions: revisions);
      subcategoryProvider =
          SubcategoryTrackerDatabaseProvider(revisions: revisions);
      experienceProvider =
          ExperiencePointTableProvider(revisions: revisions);
      mainNotifications = 0;
      subcategoryNotifications = 0;
      experienceNotifications = 0;
      mainProvider.addListener(() => mainNotifications++);
      subcategoryProvider.addListener(() => subcategoryNotifications++);
      experienceProvider.addListener(() => experienceNotifications++);
    });

    tearDown(() {
      mainProvider.dispose();
      subcategoryProvider.dispose();
      experienceProvider.dispose();
      revisions.dispose();
    });

    test('subcategory changes refresh dependent provider domains once', () {
      final subcategory = Subcategories(
        date: '2026-06-23',
        mainCategoryName: 'Skills',
        subcategoryName: 'Chess',
        timeSpent: 60,
        currentLoggedInUser: 'user-1',
      );

      revisions.markSubcategoryChanged(subcategory);

      expect(subcategoryNotifications, 1);
      expect(mainNotifications, 1);
      expect(experienceNotifications, 1);
      expect(
        subcategoryProvider.refreshKeyForSubcategory(
          currentUser: 'user-1',
          mainCategoryName: 'Skills',
          subcategoryName: 'Chess',
        ),
        1,
      );
      expect(
        subcategoryProvider.refreshKeyForDate(
          currentUser: 'user-1',
          date: '2026-06-23',
        ),
        1,
      );
    });

    test('experience-only refresh does not rebuild tracking providers', () {
      experienceProvider.refreshExperiencePointViews();

      expect(experienceNotifications, 1);
      expect(mainNotifications, 0);
      expect(subcategoryNotifications, 0);
    });

    test('main-category changes do not rebuild subcategory provider', () {
      revisions.markMainCategoryChanged();

      expect(mainNotifications, 1);
      expect(experienceNotifications, 1);
      expect(subcategoryNotifications, 0);
    });
  });
}
