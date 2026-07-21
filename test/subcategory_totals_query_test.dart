import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('all-time subcategory totals', () {
    late Database database;
    late TrackerDatabaseHelper databaseHelper;

    setUpAll(sqfliteFfiInit);

    setUp(() async {
      database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (database, version) =>
              TrackerDatabaseSchema.create(database),
        ),
      );
      databaseHelper = TrackerDatabaseHelper.forDatabase(database);
    });

    tearDown(() => database.close());

    test('returns the latest main category with each aggregated total',
        () async {
      Future<void> insert({
        required String date,
        required String mainCategory,
        required String subcategory,
        required double minutes,
      }) async {
        await databaseHelper.insertSubcategory(
          Subcategories(
            date: date,
            mainCategoryName: mainCategory,
            subcategoryName: subcategory,
            timeSpent: minutes,
            currentLoggedInUser: 'user-1',
          ),
        );
      }

      await insert(
        date: '2026-01-01',
        mainCategory: 'Skills',
        subcategory: 'AI-Assisted Development',
        minutes: 60,
      );
      await insert(
        date: '2026-02-01',
        mainCategory: 'Work',
        subcategory: 'AI-Assisted Development',
        minutes: 30,
      );
      await insert(
        date: '2026-03-01',
        mainCategory: 'Self Development',
        subcategory: 'Reading',
        minutes: 120,
      );

      final totals = await databaseHelper.getAllSubcategoryTotals(
        currentUser: 'user-1',
      );

      expect(totals.map((item) => item['subcategoryName']), [
        'Reading',
        'AI-Assisted Development',
      ]);
      expect(totals[1]['mainCategoryName'], 'Work');
      expect(totals[1]['total'], 90.0);
      expect(totals[1]['average'], 45.0);
    });
  });
}
