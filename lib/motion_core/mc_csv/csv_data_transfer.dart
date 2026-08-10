import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MotionDeletedDataSummary {
  const MotionDeletedDataSummary({
    required this.subcategoryRows,
    required this.mainCategoryRows,
    required this.experiencePointRows,
    required this.assignerRows,
    required this.activeTimerRows,
  });

  final int subcategoryRows;
  final int mainCategoryRows;
  final int experiencePointRows;
  final int assignerRows;
  final int activeTimerRows;

  int get totalRows =>
      subcategoryRows +
      mainCategoryRows +
      experiencePointRows +
      assignerRows +
      activeTimerRows;
}

class MotionDataSummary {
  const MotionDataSummary({
    required this.subcategoryRows,
    required this.mainCategoryRows,
    required this.experiencePointRows,
    required this.assignerRows,
    required this.activeTimerRows,
    required this.firstTrackedDate,
    required this.lastTrackedDate,
  });

  final int subcategoryRows;
  final int mainCategoryRows;
  final int experiencePointRows;
  final int assignerRows;
  final int activeTimerRows;
  final String? firstTrackedDate;
  final String? lastTrackedDate;

  int get totalRows =>
      subcategoryRows +
      mainCategoryRows +
      experiencePointRows +
      assignerRows +
      activeTimerRows;

  bool get hasExportableData => subcategoryRows > 0 || assignerRows > 0;
}

class MotionCsvBackupFile {
  const MotionCsvBackupFile({
    required this.fileName,
    required this.content,
  });

  final String fileName;
  final String content;
}

class MotionCsvDataTransfer {
  MotionCsvDataTransfer({
    TrackerDatabaseHelper? trackerDb,
    AssignerDatabaseHelper? assignerDb,
    Future<Database> Function()? trackerDatabase,
    Future<Database> Function()? assignerDatabase,
  })  : _trackerDatabase = trackerDatabase ??
            (() => (trackerDb ?? TrackerDatabaseHelper()).database),
        _assignerDatabase = assignerDatabase ??
            (() => (assignerDb ?? AssignerDatabaseHelper()).database);

  final Future<Database> Function() _trackerDatabase;
  final Future<Database> Function() _assignerDatabase;
  static const MethodChannel _downloadsChannel =
      MethodChannel('motion/downloads');

  Future<String> exportAllToDownloads({required String currentUser}) async {
    await _ensureHasExportableData(currentUser);

    if (Platform.isAndroid) {
      return _exportAllToAndroidDownloads(currentUser: currentUser);
    }

    final downloadsDirectory = await _downloadsDirectory();
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: downloadsDirectory,
    );
  }

  Future<String> exportBackupToDownloads({required String currentUser}) async {
    await _ensureHasExportableData(currentUser);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final prefix = 'motion_backup_${timestamp}_';

    if (Platform.isAndroid) {
      return _exportAllToAndroidDownloads(
        currentUser: currentUser,
        fileNamePrefix: prefix,
      );
    }

    final downloadsDirectory = await _downloadsDirectory();
    final backupDirectory = Directory(
      p.join(downloadsDirectory.path, 'motion_backup_$timestamp'),
    );
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: backupDirectory,
    );
  }

  Future<List<MotionCsvBackupFile>> backupFiles({
    required String currentUser,
  }) async {
    await _ensureHasExportableData(currentUser);

    return [
      MotionCsvBackupFile(
        fileName: 'main_category.csv',
        content:
            await _csvContentFromRows(await _mainCategoryRows(currentUser)),
      ),
      MotionCsvBackupFile(
        fileName: 'subcategory.csv',
        content: await _csvContentFromRows(await _subcategoryRows(currentUser)),
      ),
      MotionCsvBackupFile(
        fileName: 'to_assign.csv',
        content: await _csvContentFromRows(await _assignerRows(currentUser)),
      ),
    ];
  }

  Future<String> _exportAllToAndroidDownloads({
    required String currentUser,
    String fileNamePrefix = '',
  }) async {
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}main_category.csv',
      rows: await _mainCategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}subcategory.csv',
      rows: await _subcategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}to_assign.csv',
      rows: await _assignerRows(currentUser),
    );

    return 'Downloads';
  }

  Future<String> exportAllToDirectory({
    required String currentUser,
    required String directoryPath,
  }) async {
    await _ensureHasExportableData(currentUser);

    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: Directory(directoryPath),
    );
  }

  Future<String> _exportAllToDirectory({
    required String currentUser,
    required Directory directory,
  }) async {
    await directory.create(recursive: true);

    await _writeCsvFile(
      directory: directory,
      fileName: 'main_category.csv',
      rows: await _mainCategoryRows(currentUser),
    );
    await _writeCsvFile(
      directory: directory,
      fileName: 'subcategory.csv',
      rows: await _subcategoryRows(currentUser),
    );
    await _writeCsvFile(
      directory: directory,
      fileName: 'to_assign.csv',
      rows: await _assignerRows(currentUser),
    );

    return directory.path;
  }

  Future<MotionDeletedDataSummary> deleteAllDataForUser({
    required String currentUser,
  }) async {
    final trackerDb = await _trackerDatabase();
    final assignerDb = await _assignerDatabase();
    var subcategoryRows = 0;
    var mainCategoryRows = 0;
    var experiencePointRows = 0;
    var activeTimerRows = 0;

    await trackerDb.transaction((txn) async {
      activeTimerRows = await txn.delete(
        MotionDbTables.activeTimerSession,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      subcategoryRows = await txn.delete(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      experiencePointRows = await txn.delete(
        MotionDbTables.experiencePoints,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      mainCategoryRows = await txn.delete(
        MotionDbTables.mainCategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
    });

    final assignerRows = await assignerDb.delete(
      MotionDbTables.assigner,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
    );

    return MotionDeletedDataSummary(
      subcategoryRows: subcategoryRows,
      mainCategoryRows: mainCategoryRows,
      experiencePointRows: experiencePointRows,
      assignerRows: assignerRows,
      activeTimerRows: activeTimerRows,
    );
  }

  Future<List<List<dynamic>>> _mainCategoryRows(String currentUser) async {
    final db = await _trackerDatabase();
    final rows = await db.query(
      MotionDbTables.mainCategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy: MotionDbColumns.date,
    );

    return [
      [
        MotionDbColumns.date,
        MotionDbColumns.education,
        MotionDbColumns.work,
        MotionDbColumns.skills,
        MotionDbColumns.entertainment,
        MotionDbColumns.selfDevelopment,
        MotionDbColumns.sleep,
        MotionDbColumns.currentLoggedInUser,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.date],
            row[MotionDbColumns.education],
            row[MotionDbColumns.work],
            row[MotionDbColumns.skills],
            row[MotionDbColumns.entertainment],
            row[MotionDbColumns.selfDevelopment],
            row[MotionDbColumns.sleep],
            row[MotionDbColumns.currentLoggedInUser],
          ]),
    ];
  }

  Future<List<List<dynamic>>> _subcategoryRows(String currentUser) async {
    final db = await _trackerDatabase();
    final rows = await db.query(
      MotionDbTables.subcategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy:
          '${MotionDbColumns.date}, ${MotionDbColumns.mainCategoryName}, ${MotionDbColumns.subcategoryName}',
    );

    return [
      [
        MotionDbColumns.date,
        MotionDbColumns.mainCategoryName,
        MotionDbColumns.subcategoryName,
        MotionDbColumns.timeSpent,
        MotionDbColumns.currentLoggedInUser,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.date],
            row[MotionDbColumns.mainCategoryName],
            row[MotionDbColumns.subcategoryName],
            row[MotionDbColumns.timeSpent],
            row[MotionDbColumns.currentLoggedInUser],
          ]),
    ];
  }

  Future<List<List<dynamic>>> _assignerRows(String currentUser) async {
    final db = await _assignerDatabase();
    final rows = await db.query(
      MotionDbTables.assigner,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy:
          '${MotionDbColumns.mainCategoryName}, ${MotionDbColumns.subcategoryName}',
    );

    return [
      [
        MotionDbColumns.currentLoggedInUser,
        MotionDbColumns.subcategoryName,
        MotionDbColumns.mainCategoryName,
        MotionDbColumns.isActive,
        MotionDbColumns.isArchive,
        MotionDbColumns.dateCreated,
        MotionDbColumns.isStreakActive,
        MotionDbColumns.streakType,
        MotionDbColumns.streakTargetMinutes,
        MotionDbColumns.streakStartDate,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.currentLoggedInUser],
            row[MotionDbColumns.subcategoryName],
            row[MotionDbColumns.mainCategoryName],
            row[MotionDbColumns.isActive],
            row[MotionDbColumns.isArchive],
            row[MotionDbColumns.dateCreated],
            row[MotionDbColumns.isStreakActive],
            row[MotionDbColumns.streakType],
            row[MotionDbColumns.streakTargetMinutes],
            row[MotionDbColumns.streakStartDate],
          ]),
    ];
  }

  Future<void> _writeCsvFile({
    required Directory directory,
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = await _csvContentFromRows(rows);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(csv);
  }

  Future<void> _writeAndroidCsvFile({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = await _csvContentFromRows(rows);
    await _downloadsChannel.invokeMethod<String>('saveCsv', {
      'fileName': fileName,
      'content': csv,
    });
  }

  Future<String> _csvContentFromRows(List<List<dynamic>> rows) async {
    return const ListToCsvConverter().convert(rows);
  }

  Future<Directory> _downloadsDirectory() async {
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        await downloadsDirectory.create(recursive: true);
        return downloadsDirectory;
      }
    } catch (_) {
      // Some Android devices do not expose Downloads through path_provider.
    }

    final androidDownloads = Directory('/storage/emulated/0/Download');
    if (await androidDownloads.exists()) return androidDownloads;

    throw const FileSystemException('Downloads directory is unavailable.');
  }

  Future<void> _ensureHasExportableData(String currentUser) async {
    final summary = await dataSummaryForUser(currentUser: currentUser);

    if (!summary.hasExportableData) {
      throw StateError('There is no Motion data to export yet.');
    }
  }

  Future<MotionDataSummary> dataSummaryForUser({
    required String currentUser,
  }) async {
    final trackerDb = await _trackerDatabase();
    final assignerDb = await _assignerDatabase();

    final subcategoryCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.subcategory}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final mainCategoryCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.mainCategory}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final experiencePointCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.experiencePoints}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final activeTimerCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.activeTimerSession}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final assignerCount = Sqflite.firstIntValue(await assignerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.assigner}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final dateRange = await trackerDb.rawQuery(
      '''
      SELECT
        MIN(${MotionDbColumns.date}) AS firstDate,
        MAX(${MotionDbColumns.date}) AS lastDate
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
      ''',
      [currentUser],
    );

    return MotionDataSummary(
      subcategoryRows: subcategoryCount,
      mainCategoryRows: mainCategoryCount,
      experiencePointRows: experiencePointCount,
      assignerRows: assignerCount,
      activeTimerRows: activeTimerCount,
      firstTrackedDate: dateRange.first['firstDate']?.toString(),
      lastTrackedDate: dateRange.first['lastDate']?.toString(),
    );
  }
}
