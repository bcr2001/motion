import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/mc_sqlite/tracking_time_policy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tracked-time limits', () {
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

    Subcategories timeBlock(double minutes, {int? id}) => Subcategories(
          id: id,
          date: '2026-07-19',
          mainCategoryName: MotionCategories.skills,
          subcategoryName: 'Chess',
          timeSpent: minutes,
          currentLoggedInUser: 'user-1',
        );

    test('allows a date to reach exactly 24 hours', () async {
      await databaseHelper.insertSubcategory(timeBlock(1000));
      await databaseHelper.insertSubcategory(timeBlock(440));

      final rows = await database.query(MotionDbTables.subcategory);
      expect(rows, hasLength(2));
    });

    test('rejects a single block longer than 24 hours', () async {
      await expectLater(
        databaseHelper.insertSubcategory(timeBlock(1441)),
        throwsA(isA<TimeBlockLimitExceeded>()),
      );
      expect(await database.query(MotionDbTables.subcategory), isEmpty);
    });

    test('rejects a block that takes the date beyond 24 hours', () async {
      await databaseHelper.insertSubcategory(timeBlock(1400));

      await expectLater(
        databaseHelper.insertSubcategory(timeBlock(41)),
        throwsA(
          isA<DailyTimeLimitExceeded>()
              .having((error) => error.remainingMinutes, 'remaining', 40),
        ),
      );
      expect(await database.query(MotionDbTables.subcategory), hasLength(1));
    });

    test('validates updates without counting the edited row twice', () async {
      await databaseHelper.insertSubcategory(timeBlock(1000));
      final editedId = await databaseHelper.insertSubcategory(timeBlock(400));

      await expectLater(
        databaseHelper.updateSubcategory(timeBlock(500, id: editedId)),
        throwsA(isA<DailyTimeLimitExceeded>()),
      );

      final editedRow = await database.query(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.id} = ?',
        whereArgs: [editedId],
      );
      expect(editedRow.single[MotionDbColumns.timeSpent], 400.0);
    });

    test('database triggers stop direct writes from bypassing the rule',
        () async {
      await databaseHelper.insertSubcategory(timeBlock(1440));

      await expectLater(
        database.insert(
          MotionDbTables.subcategory,
          timeBlock(1).toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await database.query(MotionDbTables.subcategory), hasLength(1));
    });
  });
}
