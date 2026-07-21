part of 'sql_tracker_db.dart';

extension TrackerTimerQueries on TrackerDatabaseHelper {
  Future<ActivityTimerSession?> getActiveTimerSession({
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.activeTimerSession,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        limit: 1,
      );
      return rows.isEmpty ? null : ActivityTimerSession.fromMap(rows.first);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getActiveTimerSession',
        error,
        stackTrace,
      );
    }
  }

  Future<void> saveActiveTimerSession(ActivityTimerSession session) async {
    try {
      final db = await database;
      await db.insert(
        MotionDbTables.activeTimerSession,
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.saveActiveTimerSession',
        error,
        stackTrace,
      );
    }
  }

  Future<void> deleteActiveTimerSession({required String currentUser}) async {
    try {
      final db = await database;
      await db.delete(
        MotionDbTables.activeTimerSession,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.deleteActiveTimerSession',
        error,
        stackTrace,
      );
    }
  }

  Future<List<int>> completeActiveTimerSession({
    required String currentUser,
    required List<Subcategories> entries,
  }) async {
    try {
      final db = await database;
      return db.transaction((transaction) async {
        final pendingByDate = <String, double>{};
        for (final entry in entries) {
          TrackingTimePolicy.validateBlock(entry.timeSpent);
          pendingByDate.update(
            entry.date,
            (minutes) => minutes + entry.timeSpent,
            ifAbsent: () => entry.timeSpent,
          );
        }
        for (final pending in pendingByDate.entries) {
          final existingMinutes = await _trackedMinutesForDate(
            transaction,
            date: pending.key,
            currentUser: currentUser,
          );
          TrackingTimePolicy.validateDailyTotal(
            existingMinutes: existingMinutes,
            additionalMinutes: pending.value,
            date: pending.key,
          );
        }

        final insertedIds = <int>[];
        for (final entry in entries) {
          await _ensureDailyRows(
            transaction,
            date: entry.date,
            currentUser: entry.currentLoggedInUser,
          );
          insertedIds.add(await transaction.insert(
            MotionDbTables.subcategory,
            entry.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          ));
        }
        await transaction.delete(
          MotionDbTables.activeTimerSession,
          where: '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [currentUser],
        );
        return insertedIds;
      });
    } on TrackingTimeLimitException {
      rethrow;
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.completeActiveTimerSession',
        error,
        stackTrace,
      );
    }
  }
}
