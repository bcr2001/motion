import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_migrations/temp_video_editing_to_youtube_migration.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Video Editing to YouTube Channel migration', () {
    late Database trackerDatabase;
    late Database assignerDatabase;
    late TrackerDatabaseHelper trackerHelper;

    setUpAll(sqfliteFfiInit);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      trackerDatabase = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          singleInstance: false,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (database, version) =>
              TrackerDatabaseSchema.create(database),
        ),
      );
      assignerDatabase = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (database, version) => _createAssignerTable(database),
        ),
      );
      trackerHelper = TrackerDatabaseHelper.forDatabase(trackerDatabase);
    });

    tearDown(() async {
      await trackerDatabase.close();
      await assignerDatabase.close();
    });

    test('moves rows, totals, XP, and streak settings without losing minutes',
        () async {
      const user = TempVideoEditingToYouTubeMigration.targetUserId;
      await _insertAssignment(
        assignerDatabase,
        user: user,
        subcategory: TempVideoEditingToYouTubeMigration.targetSubcategory,
        category: MotionCategories.work,
      );
      await _insertAssignment(
        assignerDatabase,
        user: user,
        subcategory: TempVideoEditingToYouTubeMigration.sourceSubcategory,
        category: MotionCategories.skills,
        streakActive: 1,
        streakType: 'target_time',
        streakTargetMinutes: 45,
        streakStartDate: '2026-01-01',
      );

      await _insertTime(
        trackerHelper,
        user: user,
        date: '2026-01-01',
        category: MotionCategories.skills,
        subcategory: TempVideoEditingToYouTubeMigration.sourceSubcategory,
        minutes: 60,
      );
      await _insertTime(
        trackerHelper,
        user: user,
        date: '2026-01-02',
        category: MotionCategories.skills,
        subcategory: TempVideoEditingToYouTubeMigration.sourceSubcategory,
        minutes: 120,
      );
      await _insertTime(
        trackerHelper,
        user: user,
        date: '2026-01-01',
        category: MotionCategories.work,
        subcategory: TempVideoEditingToYouTubeMigration.targetSubcategory,
        minutes: 30,
      );

      final migration = TempVideoEditingToYouTubeMigration(
        trackerDatabase: trackerHelper,
        assignerDatabase: () async => assignerDatabase,
      );
      final result = await migration.runIfNeeded(user);

      expect(result, isNotNull);
      expect(result!.completed, isTrue);
      expect(result.migratedRows, 2);
      expect(result.migratedMinutes, 180);
      expect(result.affectedDates, 2);
      expect(result.removedAssignments, 1);

      final sourceRows = await trackerDatabase.query(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
            '${MotionDbColumns.subcategoryName} = ?',
        whereArgs: [
          user,
          TempVideoEditingToYouTubeMigration.sourceSubcategory,
        ],
      );
      expect(sourceRows, isEmpty);

      final targetRows = await trackerDatabase.query(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
            '${MotionDbColumns.subcategoryName} = ?',
        whereArgs: [
          user,
          TempVideoEditingToYouTubeMigration.targetSubcategory,
        ],
      );
      expect(targetRows, hasLength(3));
      expect(
        targetRows.fold<double>(
          0,
          (total, row) =>
              total + (row[MotionDbColumns.timeSpent] as num).toDouble(),
        ),
        210,
      );
      expect(
        targetRows.map((row) => row[MotionDbColumns.mainCategoryName]).toSet(),
        {MotionCategories.work},
      );

      final firstDayMain = await _dailyRow(
        trackerDatabase,
        MotionDbTables.mainCategory,
        user: user,
        date: '2026-01-01',
      );
      expect(firstDayMain[MotionDbColumns.skills], 0);
      expect(firstDayMain[MotionDbColumns.work], 90);

      final secondDayMain = await _dailyRow(
        trackerDatabase,
        MotionDbTables.mainCategory,
        user: user,
        date: '2026-01-02',
      );
      expect(secondDayMain[MotionDbColumns.skills], 0);
      expect(secondDayMain[MotionDbColumns.work], 120);

      final firstDayXp = await _dailyRow(
        trackerDatabase,
        MotionDbTables.experiencePoints,
        user: user,
        date: '2026-01-01',
      );
      expect(firstDayXp[MotionDbColumns.skillsXp], 0);
      expect(firstDayXp[MotionDbColumns.workXp], 7);

      final secondDayXp = await _dailyRow(
        trackerDatabase,
        MotionDbTables.experiencePoints,
        user: user,
        date: '2026-01-02',
      );
      expect(secondDayXp[MotionDbColumns.skillsXp], 0);
      expect(secondDayXp[MotionDbColumns.workXp], 10);

      final assignments = await assignerDatabase.query(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [user],
      );
      expect(assignments, hasLength(1));
      expect(
        assignments.single[MotionDbColumns.subcategoryName],
        TempVideoEditingToYouTubeMigration.targetSubcategory,
      );
      expect(assignments.single[MotionDbColumns.isStreakActive], 1);
      expect(assignments.single[MotionDbColumns.streakType], 'target_time');
      expect(assignments.single[MotionDbColumns.streakTargetMinutes], 45);
      expect(
        assignments.single[MotionDbColumns.streakStartDate],
        '2026-01-01',
      );

      final rerun = await migration.runIfNeeded(user);
      expect(rerun, isNotNull);
      expect(rerun!.changed, isFalse);
      expect(
        await trackerDatabase.query(MotionDbTables.subcategory),
        hasLength(3),
      );
    });

    test('does not alter tracking data when the target assignment is missing',
        () async {
      const user = TempVideoEditingToYouTubeMigration.targetUserId;
      await _insertAssignment(
        assignerDatabase,
        user: user,
        subcategory: TempVideoEditingToYouTubeMigration.sourceSubcategory,
        category: MotionCategories.skills,
      );
      await _insertTime(
        trackerHelper,
        user: user,
        date: '2026-01-01',
        category: MotionCategories.skills,
        subcategory: TempVideoEditingToYouTubeMigration.sourceSubcategory,
        minutes: 60,
      );

      final migration = TempVideoEditingToYouTubeMigration(
        trackerDatabase: trackerHelper,
        assignerDatabase: () async => assignerDatabase,
      );

      await expectLater(
        migration.runIfNeeded(user),
        throwsA(isA<StateError>()),
      );
      final rows = await trackerDatabase.query(MotionDbTables.subcategory);
      expect(rows, hasLength(1));
      expect(
        rows.single[MotionDbColumns.subcategoryName],
        TempVideoEditingToYouTubeMigration.sourceSubcategory,
      );
      expect(
        rows.single[MotionDbColumns.mainCategoryName],
        MotionCategories.skills,
      );
    });
  });
}

Future<void> _createAssignerTable(Database database) {
  return database.execute('''
    CREATE TABLE ${MotionDbTables.assigner}(
      ${MotionDbColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ${MotionDbColumns.currentLoggedInUser} TEXT,
      ${MotionDbColumns.subcategoryName} TEXT,
      ${MotionDbColumns.mainCategoryName} TEXT,
      ${MotionDbColumns.isActive} INTEGER,
      ${MotionDbColumns.isArchive} INTEGER DEFAULT 0,
      ${MotionDbColumns.dateCreated} TEXT,
      ${MotionDbColumns.isStreakActive} INTEGER DEFAULT 0,
      ${MotionDbColumns.streakType} TEXT DEFAULT '',
      ${MotionDbColumns.streakTargetMinutes} REAL DEFAULT 0,
      ${MotionDbColumns.streakStartDate} TEXT DEFAULT ''
    )
  ''');
}

Future<void> _insertAssignment(
  Database database, {
  required String user,
  required String subcategory,
  required String category,
  int streakActive = 0,
  String streakType = '',
  double streakTargetMinutes = 0,
  String streakStartDate = '',
}) {
  return database.insert(MotionDbTables.assigner, {
    MotionDbColumns.currentLoggedInUser: user,
    MotionDbColumns.subcategoryName: subcategory,
    MotionDbColumns.mainCategoryName: category,
    MotionDbColumns.isActive: 1,
    MotionDbColumns.isArchive: 0,
    MotionDbColumns.dateCreated: '2026-01-01',
    MotionDbColumns.isStreakActive: streakActive,
    MotionDbColumns.streakType: streakType,
    MotionDbColumns.streakTargetMinutes: streakTargetMinutes,
    MotionDbColumns.streakStartDate: streakStartDate,
  }).then((_) {});
}

Future<void> _insertTime(
  TrackerDatabaseHelper database, {
  required String user,
  required String date,
  required String category,
  required String subcategory,
  required double minutes,
}) {
  return database
      .insertSubcategory(Subcategories(
        date: date,
        mainCategoryName: category,
        subcategoryName: subcategory,
        timeSpent: minutes,
        currentLoggedInUser: user,
      ))
      .then((_) {});
}

Future<Map<String, Object?>> _dailyRow(
  Database database,
  String table, {
  required String user,
  required String date,
}) async {
  final rows = await database.query(
    table,
    where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
        '${MotionDbColumns.date} = ?',
    whereArgs: [user, date],
  );
  return rows.single;
}
