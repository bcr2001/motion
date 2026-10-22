import 'package:flutter/foundation.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class VideoEditingMigrationResult {
  const VideoEditingMigrationResult({
    required this.completed,
    required this.migratedRows,
    required this.migratedMinutes,
    required this.affectedDates,
    required this.removedAssignments,
    required this.canonicalSubcategoryName,
  });

  final bool completed;
  final int migratedRows;
  final double migratedMinutes;
  final int affectedDates;
  final int removedAssignments;
  final String canonicalSubcategoryName;

  bool get changed => migratedRows > 0 || removedAssignments > 0;
}

/// Temporary, user-scoped migration for consolidating historical Video Editing
/// records into the existing YouTube Channel assignment.
///
/// Remove this file and its bootstrap call after the migration is confirmed on
/// the target device.
class TempVideoEditingToYouTubeMigration {
  TempVideoEditingToYouTubeMigration({
    TrackerDatabaseHelper? trackerDatabase,
    required Future<Database> Function() assignerDatabase,
    Future<SharedPreferences> Function()? preferences,
  })  : _trackerDatabase = trackerDatabase ?? TrackerDatabaseHelper(),
        _assignerDatabase = assignerDatabase,
        _preferences = preferences ?? SharedPreferences.getInstance;

  static const targetUserId = 'hhANBj74wiclvfuDLGfuDlFZgJ62';
  static const sourceSubcategory = 'Video Editing';
  static const targetSubcategory = 'YouTube Channel';
  static const targetMainCategory = MotionCategories.work;
  static const _completionKeyPrefix = 'tempMigration.videoEditingToYouTube.v1';

  final TrackerDatabaseHelper _trackerDatabase;
  final Future<Database> Function() _assignerDatabase;
  final Future<SharedPreferences> Function() _preferences;
  bool _isRunning = false;

  Future<VideoEditingMigrationResult?> runIfNeeded(String? currentUser) async {
    if (currentUser == null || currentUser != targetUserId || _isRunning) {
      return null;
    }
    final user = currentUser;
    _isRunning = true;
    try {
      final preferences = await _preferences();
      final completionKey = '$_completionKeyPrefix.$user';
      if (preferences.getBool(completionKey) ?? false) {
        return const VideoEditingMigrationResult(
          completed: true,
          migratedRows: 0,
          migratedMinutes: 0,
          affectedDates: 0,
          removedAssignments: 0,
          canonicalSubcategoryName: targetSubcategory,
        );
      }

      final assignerDb = await _assignerDatabase();
      final targetAssignments = await assignerDb.query(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
            'LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?) AND '
            'LOWER(TRIM(${MotionDbColumns.mainCategoryName})) = LOWER(?)',
        whereArgs: [user, targetSubcategory, targetMainCategory],
        orderBy: '${MotionDbColumns.isActive} DESC, ${MotionDbColumns.id} ASC',
      );
      if (targetAssignments.isEmpty) {
        throw StateError(
          'The YouTube Channel assignment under Work was not found. '
          'No Video Editing data was changed.',
        );
      }

      final targetAssignment = targetAssignments.first;
      final canonicalSubcategory =
          targetAssignment[MotionDbColumns.subcategoryName].toString();
      final canonicalMainCategory =
          targetAssignment[MotionDbColumns.mainCategoryName].toString();
      final trackerDb = await _trackerDatabase.database;

      final trackerResult = await trackerDb.transaction((txn) async {
        final sourceSummary = await txn.rawQuery('''
          SELECT COUNT(*) AS rowCount,
                 COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS totalMinutes,
                 COUNT(DISTINCT ${MotionDbColumns.date}) AS dateCount
          FROM ${MotionDbTables.subcategory}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
            AND LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)
        ''', [user, sourceSubcategory]);
        final sourceRow = sourceSummary.first;
        final sourceCount = (sourceRow['rowCount'] as num?)?.toInt() ?? 0;
        final sourceMinutes =
            (sourceRow['totalMinutes'] as num?)?.toDouble() ?? 0;
        final affectedDates = (sourceRow['dateCount'] as num?)?.toInt() ?? 0;

        final targetBefore = await _subcategoryTotal(
          txn,
          currentUser: user,
          subcategoryName: canonicalSubcategory,
        );
        final updatedRows = await txn.update(
          MotionDbTables.subcategory,
          {
            MotionDbColumns.subcategoryName: canonicalSubcategory,
            MotionDbColumns.mainCategoryName: canonicalMainCategory,
          },
          where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
              'LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)',
          whereArgs: [user, sourceSubcategory],
        );
        final targetAfter = await _subcategoryTotal(
          txn,
          currentUser: user,
          subcategoryName: canonicalSubcategory,
        );
        final remainingSource = Sqflite.firstIntValue(await txn.rawQuery('''
              SELECT COUNT(*)
              FROM ${MotionDbTables.subcategory}
              WHERE ${MotionDbColumns.currentLoggedInUser} = ?
                AND LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)
            ''', [user, sourceSubcategory])) ?? 0;

        if (updatedRows != sourceCount ||
            remainingSource != 0 ||
            (targetAfter - targetBefore - sourceMinutes).abs() > 0.001) {
          throw StateError(
            'Video Editing migration verification failed. No tracking rows '
            'were changed.',
          );
        }

        return (
          rows: updatedRows,
          minutes: sourceMinutes,
          dates: affectedDates,
        );
      });

      final removedAssignments = await assignerDb.transaction((txn) async {
        final sourceAssignments = await txn.query(
          MotionDbTables.assigner,
          where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
              'LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)',
          whereArgs: [user, sourceSubcategory],
          orderBy: '${MotionDbColumns.isStreakActive} DESC, '
              '${MotionDbColumns.id} ASC',
        );

        if (sourceAssignments.isNotEmpty &&
            (targetAssignment[MotionDbColumns.isStreakActive] as num?)
                    ?.toInt() !=
                1) {
          final streakSource = sourceAssignments.firstWhere(
            (row) =>
                (row[MotionDbColumns.isStreakActive] as num?)?.toInt() == 1,
            orElse: () => const <String, Object?>{},
          );
          if (streakSource.isNotEmpty) {
            await txn.update(
              MotionDbTables.assigner,
              {
                MotionDbColumns.isStreakActive: 1,
                MotionDbColumns.streakType:
                    streakSource[MotionDbColumns.streakType],
                MotionDbColumns.streakTargetMinutes:
                    streakSource[MotionDbColumns.streakTargetMinutes],
                MotionDbColumns.streakStartDate:
                    streakSource[MotionDbColumns.streakStartDate],
              },
              where: '${MotionDbColumns.id} = ?',
              whereArgs: [targetAssignment[MotionDbColumns.id]],
            );
          }
        }

        return txn.delete(
          MotionDbTables.assigner,
          where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
              'LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)',
          whereArgs: [user, sourceSubcategory],
        );
      });

      await preferences.setBool(completionKey, true);
      final result = VideoEditingMigrationResult(
        completed: true,
        migratedRows: trackerResult.rows,
        migratedMinutes: trackerResult.minutes,
        affectedDates: trackerResult.dates,
        removedAssignments: removedAssignments,
        canonicalSubcategoryName: canonicalSubcategory,
      );
      debugPrint(
        'VIDEO EDITING MIGRATION COMPLETE: ${result.migratedRows} row(s), '
        '${result.migratedMinutes.toStringAsFixed(2)} minute(s), '
        '${result.affectedDates} date(s), '
        '${result.removedAssignments} assignment(s) removed.',
      );
      return result;
    } finally {
      _isRunning = false;
    }
  }

  Future<double> _subcategoryTotal(
    DatabaseExecutor db, {
    required String currentUser,
    required String subcategoryName,
  }) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND LOWER(TRIM(${MotionDbColumns.subcategoryName})) = LOWER(?)
    ''', [currentUser, subcategoryName]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}
