import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/tracking_data_revisions.dart';
import 'package:motion/motion_core/motion_rewards/daily_xp_target_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('daily XP target status', () {
    late Database database;
    late TrackingDataRevisions revisions;
    late ExperiencePointTableProvider provider;

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
      revisions = TrackingDataRevisions();
      provider = ExperiencePointTableProvider(
        revisions: revisions,
        databaseHelper: TrackerDatabaseHelper.forDatabase(database),
      );

      await _insertXp(database, date: '2026-12-20', xp: 34);
      await _insertXp(database, date: '2026-12-21', xp: 35);
      await _insertXp(database, date: '2026-12-22', xp: 20);
    });

    tearDown(() async {
      provider.dispose();
      revisions.dispose();
      await database.close();
    });

    test('today earnings do not move today target', () async {
      final initial = await loadDailyXpTargetStatus(
        xpProvider: provider,
        currentUser: 'user-1',
        currentYear: '2026',
        currentDate: '2026-12-22',
        currentScore: 25,
      );

      await database.update(
        MotionDbTables.experiencePoints,
        {MotionDbColumns.educationXp: 40},
        where:
            '${MotionDbColumns.currentLoggedInUser} = ? AND ${MotionDbColumns.date} = ?',
        whereArgs: ['user-1', '2026-12-22'],
      );

      final afterMoreXp = await loadDailyXpTargetStatus(
        xpProvider: provider,
        currentUser: 'user-1',
        currentYear: '2026',
        currentDate: '2026-12-22',
        currentScore: 35,
      );

      expect(initial.targetXp, 49);
      expect(afterMoreXp.targetXp, 49);
      expect(initial.earnedXp, 20);
      expect(afterMoreXp.earnedXp, 40);
      expect(initial.progress.recentAverageDailyXp, 34.5);
      expect(afterMoreXp.progress.recentAverageDailyXp, 34.5);
    });

    test('recent pace counts missed calendar days after tracking begins',
        () async {
      await database.delete(
        MotionDbTables.experiencePoints,
        where:
            '${MotionDbColumns.currentLoggedInUser} = ? AND ${MotionDbColumns.date} = ?',
        whereArgs: ['user-1', '2026-12-21'],
      );

      final status = await loadDailyXpTargetStatus(
        xpProvider: provider,
        currentUser: 'user-1',
        currentYear: '2026',
        currentDate: '2026-12-22',
        currentScore: 25,
      );

      expect(status.progress.recentAverageDailyXp, 17);
    });
  });
}

Future<void> _insertXp(
  Database database, {
  required String date,
  required int xp,
}) async {
  await database.insert(MotionDbTables.mainCategory, {
    MotionDbColumns.date: date,
    MotionDbColumns.currentLoggedInUser: 'user-1',
  });
  await database.insert(MotionDbTables.experiencePoints, {
    MotionDbColumns.date: date,
    MotionDbColumns.educationXp: xp,
    MotionDbColumns.currentLoggedInUser: 'user-1',
  });
}
