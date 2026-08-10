import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/mc_csv/motion_backup_restore.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Motion backup restore', () {
    late Directory tempDirectory;
    late Database trackerDb;
    late Database assignerDb;
    late MotionCsvDataTransfer transfer;
    late MotionBackupRestoreService restoreService;

    setUp(() async {
      tempDirectory = Directory.systemTemp.createTempSync('motion_restore_');
      trackerDb = await databaseFactoryFfi.openDatabase(
        '${tempDirectory.path}${Platform.pathSeparator}tracker.db',
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (db, version) => TrackerDatabaseSchema.create(db),
        ),
      );
      assignerDb = await databaseFactoryFfi.openDatabase(
        '${tempDirectory.path}${Platform.pathSeparator}assigner.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) => _createAssignerTable(db),
        ),
      );
      transfer = MotionCsvDataTransfer(
        trackerDatabase: () async => trackerDb,
        assignerDatabase: () async => assignerDb,
      );
      restoreService = MotionBackupRestoreService(
        trackerDatabase: () async => trackerDb,
        assignerDatabase: () async => assignerDb,
      );
    });

    tearDown(() async {
      await trackerDb.close();
      await assignerDb.close();
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('restores a generated backup and rebuilds daily totals and XP',
        () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      await _seedOtherUserData(trackerDb, assignerDb);
      final files = await transfer.backupFiles(currentUser: 'user-1');

      await _replaceWithTemporaryData(trackerDb, assignerDb, user: 'user-1');
      final backup = restoreService.validateBackup(
        files: files,
        currentUser: 'user-1',
      );
      final result = await restoreService.restoreBackup(
        backup: backup,
        currentUser: 'user-1',
      );

      expect(result.trackingRows, 3);
      expect(result.dailyTotalRows, 1);
      expect(result.experiencePointRows, 1);
      expect(result.assignedRows, 2);

      final trackingRows = await trackerDb.query(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: ['user-1'],
      );
      expect(trackingRows, hasLength(3));
      expect(
        trackingRows.map((row) => row[MotionDbColumns.subcategoryName]),
        containsAll(['Study', 'Chess', 'Sleep']),
      );

      final dailyTotal = (await trackerDb.query(
        MotionDbTables.mainCategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: ['user-1'],
      ))
          .single;
      expect(dailyTotal[MotionDbColumns.education], 60.0);
      expect(dailyTotal[MotionDbColumns.skills], 30.0);
      expect(dailyTotal[MotionDbColumns.sleep], 480.0);

      final xp = (await trackerDb.query(
        MotionDbTables.experiencePoints,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: ['user-1'],
      ))
          .single;
      expect(xp[MotionDbColumns.educationXp], 5);
      expect(xp[MotionDbColumns.skillsXp], 2);
      expect(xp[MotionDbColumns.sleepXp], 25);
      expect(xp[MotionDbColumns.accountabilityBonusXp], 1);

      final assignments = await assignerDb.query(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: ['user-1'],
      );
      expect(assignments, hasLength(2));
      expect(
        assignments.firstWhere((row) =>
            row[MotionDbColumns.subcategoryName] ==
            'Chess')[MotionDbColumns.streakType],
        'target_time',
      );
      final restoredChess = assignments.firstWhere(
        (row) => row[MotionDbColumns.subcategoryName] == 'Chess',
      );
      expect(restoredChess[MotionDbColumns.dateCreated], '2026-06-04');
      expect(restoredChess[MotionDbColumns.streakStartDate], '2026-06-04');

      expect(
        await _rowCount(trackerDb, MotionDbTables.subcategory, 'user-2'),
        1,
      );
      expect(
        await _rowCount(assignerDb, MotionDbTables.assigner, 'user-2'),
        1,
      );
    });

    test('rejects an invalid numeric value before changing the database',
        () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      final files = await transfer.backupFiles(currentUser: 'user-1');
      final invalidFiles = files
          .map(
            (file) => file.fileName == 'subcategory.csv'
                ? MotionCsvBackupFile(
                    fileName: file.fileName,
                    content: file.content
                        .replaceFirst(',60.0,user-1', ',abc,user-1'),
                  )
                : file,
          )
          .toList();

      expect(
        () => restoreService.validateBackup(
          files: invalidFiles,
          currentUser: 'user-1',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid timeSpent'),
          ),
        ),
      );
      expect(
        await _rowCount(trackerDb, MotionDbTables.subcategory, 'user-1'),
        3,
      );
    });

    test('rejects an incomplete backup set', () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      final files = await transfer.backupFiles(currentUser: 'user-1');

      expect(
        () => restoreService.validateBackup(
          files: files.take(2).toList(),
          currentUser: 'user-1',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('exactly three files'),
          ),
        ),
      );
    });

    test('accepts Motion backup files renamed by Android Downloads', () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      final files = await transfer.backupFiles(currentUser: 'user-1');
      final renamedFiles = files
          .map(
            (file) => MotionCsvBackupFile(
              fileName: file.fileName.replaceFirst('.csv', ' (1).csv'),
              content: file.content,
            ),
          )
          .toList();

      final backup = restoreService.validateBackup(
        files: renamedFiles,
        currentUser: 'user-1',
      );

      expect(backup.preview.trackingRows, 3);
      expect(backup.preview.assignedRows, 2);
    });

    test('rejects a backup created by another Motion account', () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      final files = await transfer.backupFiles(currentUser: 'user-1');

      expect(
        () => restoreService.validateBackup(
          files: files,
          currentUser: 'user-2',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('different Motion account'),
          ),
        ),
      );
    });

    test('rejects backup days that exceed 24 tracked hours', () async {
      await _seedBackupData(trackerDb, assignerDb, user: 'user-1');
      final files = await transfer.backupFiles(currentUser: 'user-1');
      final invalidFiles = files
          .map(
            (file) => file.fileName == 'subcategory.csv'
                ? MotionCsvBackupFile(
                    fileName: file.fileName,
                    content: file.content
                        .replaceFirst(',480.0,user-1', ',1400.0,user-1'),
                  )
                : file,
          )
          .toList();

      expect(
        () => restoreService.validateBackup(
          files: invalidFiles,
          currentUser: 'user-1',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('exceeds 24 tracked hours'),
          ),
        ),
      );
    });
  });
}

Future<void> _createAssignerTable(Database db) {
  return db.execute('''
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

Future<void> _seedBackupData(
  Database trackerDb,
  Database assignerDb, {
  required String user,
}) async {
  await trackerDb.insert(MotionDbTables.mainCategory, {
    MotionDbColumns.date: '2026-08-01',
    MotionDbColumns.currentLoggedInUser: user,
  });
  await trackerDb.insert(MotionDbTables.experiencePoints, {
    MotionDbColumns.date: '2026-08-01',
    MotionDbColumns.currentLoggedInUser: user,
  });
  for (final row in [
    {
      MotionDbColumns.mainCategoryName: MotionCategories.education,
      MotionDbColumns.subcategoryName: 'Study',
      MotionDbColumns.timeSpent: 60.0,
    },
    {
      MotionDbColumns.mainCategoryName: MotionCategories.skills,
      MotionDbColumns.subcategoryName: 'Chess',
      MotionDbColumns.timeSpent: 30.0,
    },
    {
      MotionDbColumns.mainCategoryName: MotionCategories.sleep,
      MotionDbColumns.subcategoryName: 'Sleep',
      MotionDbColumns.timeSpent: 480.0,
    },
  ]) {
    await trackerDb.insert(MotionDbTables.subcategory, {
      MotionDbColumns.date: '2026-08-01',
      ...row,
      MotionDbColumns.currentLoggedInUser: user,
    });
  }

  await assignerDb.insert(MotionDbTables.assigner, {
    MotionDbColumns.currentLoggedInUser: user,
    MotionDbColumns.subcategoryName: 'Study',
    MotionDbColumns.mainCategoryName: MotionCategories.education,
    MotionDbColumns.isActive: 1,
    MotionDbColumns.isArchive: 0,
    MotionDbColumns.dateCreated: '2026-01-01',
    MotionDbColumns.isStreakActive: 0,
    MotionDbColumns.streakType: '',
    MotionDbColumns.streakTargetMinutes: 0.0,
    MotionDbColumns.streakStartDate: '',
  });
  await assignerDb.insert(MotionDbTables.assigner, {
    MotionDbColumns.currentLoggedInUser: user,
    MotionDbColumns.subcategoryName: 'Chess',
    MotionDbColumns.mainCategoryName: MotionCategories.skills,
    MotionDbColumns.isActive: 1,
    MotionDbColumns.isArchive: 0,
    MotionDbColumns.dateCreated: '6/4/2026',
    MotionDbColumns.isStreakActive: 1,
    MotionDbColumns.streakType: 'target_time',
    MotionDbColumns.streakTargetMinutes: 30.0,
    MotionDbColumns.streakStartDate: '6/4/2026',
  });
}

Future<void> _seedOtherUserData(Database trackerDb, Database assignerDb) async {
  await trackerDb.insert(MotionDbTables.mainCategory, {
    MotionDbColumns.date: '2026-08-02',
    MotionDbColumns.currentLoggedInUser: 'user-2',
  });
  await trackerDb.insert(MotionDbTables.experiencePoints, {
    MotionDbColumns.date: '2026-08-02',
    MotionDbColumns.currentLoggedInUser: 'user-2',
  });
  await trackerDb.insert(MotionDbTables.subcategory, {
    MotionDbColumns.date: '2026-08-02',
    MotionDbColumns.mainCategoryName: MotionCategories.work,
    MotionDbColumns.subcategoryName: 'Other Work',
    MotionDbColumns.timeSpent: 12.0,
    MotionDbColumns.currentLoggedInUser: 'user-2',
  });
  await assignerDb.insert(MotionDbTables.assigner, {
    MotionDbColumns.currentLoggedInUser: 'user-2',
    MotionDbColumns.subcategoryName: 'Other Work',
    MotionDbColumns.mainCategoryName: MotionCategories.work,
    MotionDbColumns.isActive: 1,
    MotionDbColumns.isArchive: 0,
    MotionDbColumns.dateCreated: '2026-08-02',
    MotionDbColumns.isStreakActive: 0,
    MotionDbColumns.streakType: '',
    MotionDbColumns.streakTargetMinutes: 0.0,
    MotionDbColumns.streakStartDate: '',
  });
}

Future<void> _replaceWithTemporaryData(
  Database trackerDb,
  Database assignerDb, {
  required String user,
}) async {
  await trackerDb.transaction((txn) async {
    await txn.delete(
      MotionDbTables.subcategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [user],
    );
    await txn.delete(
      MotionDbTables.experiencePoints,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [user],
    );
    await txn.delete(
      MotionDbTables.mainCategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [user],
    );
    await txn.insert(MotionDbTables.mainCategory, {
      MotionDbColumns.date: '2026-08-03',
      MotionDbColumns.currentLoggedInUser: user,
    });
    await txn.insert(MotionDbTables.experiencePoints, {
      MotionDbColumns.date: '2026-08-03',
      MotionDbColumns.currentLoggedInUser: user,
    });
    await txn.insert(MotionDbTables.subcategory, {
      MotionDbColumns.date: '2026-08-03',
      MotionDbColumns.mainCategoryName: MotionCategories.entertainment,
      MotionDbColumns.subcategoryName: 'Temporary',
      MotionDbColumns.timeSpent: 10.0,
      MotionDbColumns.currentLoggedInUser: user,
    });
  });
  await assignerDb.delete(
    MotionDbTables.assigner,
    where: '${MotionDbColumns.currentLoggedInUser} = ?',
    whereArgs: [user],
  );
  await assignerDb.insert(MotionDbTables.assigner, {
    MotionDbColumns.currentLoggedInUser: user,
    MotionDbColumns.subcategoryName: 'Temporary',
    MotionDbColumns.mainCategoryName: MotionCategories.entertainment,
    MotionDbColumns.isActive: 1,
    MotionDbColumns.isArchive: 0,
    MotionDbColumns.dateCreated: '2026-08-03',
    MotionDbColumns.isStreakActive: 0,
    MotionDbColumns.streakType: '',
    MotionDbColumns.streakTargetMinutes: 0.0,
    MotionDbColumns.streakStartDate: '',
  });
}

Future<int> _rowCount(Database db, String table, String user) async {
  return Sqflite.firstIntValue(await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM $table
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        ''',
        [user],
      )) ??
      0;
}
