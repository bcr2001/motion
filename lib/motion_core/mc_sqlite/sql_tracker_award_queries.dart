part of 'sql_tracker_db.dart';

extension TrackerAwardQueries on TrackerDatabaseHelper {
  Future<Map<int, String>> getAwardEarnedDates({
    required String currentUser,
    required List<int> requiredHours,
  }) async {
    if (requiredHours.isEmpty) return {};

    try {
      final db = await database;
      final thresholds = requiredHours.toSet().toList()..sort();
      final rows = await db.rawQuery("""
        SELECT ${MotionDbColumns.date},
               COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        GROUP BY ${MotionDbColumns.date}
        ORDER BY ${MotionDbColumns.date} ASC
        """, [currentUser]);

      final earnedDates = <int, String>{};
      var cumulativeMinutes = 0.0;
      var thresholdIndex = 0;

      for (final row in rows) {
        final date = row[MotionDbColumns.date]?.toString();
        if (date == null || date.isEmpty) continue;

        cumulativeMinutes += TrackerDatabaseHelper._readDouble(row['total']);

        while (thresholdIndex < thresholds.length &&
            cumulativeMinutes >= thresholds[thresholdIndex] * 60) {
          earnedDates[thresholds[thresholdIndex]] = date;
          thresholdIndex++;
        }

        if (thresholdIndex >= thresholds.length) break;
      }

      return earnedDates;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getAwardEarnedDates", e, stackTrace);
    }
  }
}
