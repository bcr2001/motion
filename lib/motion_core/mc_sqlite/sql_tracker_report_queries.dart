part of 'sql_tracker_db.dart';

extension TrackerReportQueries on TrackerDatabaseHelper {
  Future<Map<String, dynamic>> getMonthlyReportSnapshot({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    try {
      final db = await database;

      final totals = await db.rawQuery('''
        SELECT
          COUNT(DISTINCT ${MotionDbColumns.date}) AS trackedDays,
          COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS accountedMinutes,
          COALESCE(
            (COUNT(DISTINCT ${MotionDbColumns.date}) * 1440) -
            SUM(${MotionDbColumns.timeSpent}),
            0
          ) AS unaccountedMinutes
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
          AND ${MotionDbColumns.timeSpent} > 0
      ''', [currentUser, firstDay, lastDay]);

      final xpTotals = await db.rawQuery('''
        SELECT
          (${TrackerDatabaseHelper._totalXpExpression}) AS totalXp,
          COUNT(DISTINCT ${MotionDbColumns.date}) AS xpDays,
          ROUND(
            COALESCE((${TrackerDatabaseHelper._totalXpExpression}), 0) * 100.0 /
            NULLIF(COUNT(DISTINCT ${MotionDbColumns.date}) * ${MotionXpPolicy.maxDailyXp}, 0),
            2
          ) AS efficiencyScore
        FROM ${MotionDbTables.experiencePoints}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
      ''', [currentUser, firstDay, lastDay]);

      final bestDay = await db.rawQuery('''
        SELECT ${MotionDbColumns.date}, (${TrackerDatabaseHelper._totalXpExpression}) AS totalXp
        FROM ${MotionDbTables.experiencePoints}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
        GROUP BY ${MotionDbColumns.date}
        ORDER BY totalXp DESC, ${MotionDbColumns.date} DESC
        LIMIT 1
      ''', [currentUser, firstDay, lastDay]);

      final lowestDay = await db.rawQuery('''
        SELECT ${MotionDbColumns.date}, (${TrackerDatabaseHelper._totalXpExpression}) AS totalXp
        FROM ${MotionDbTables.experiencePoints}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
        GROUP BY ${MotionDbColumns.date}
        ORDER BY totalXp ASC, ${MotionDbColumns.date} ASC
        LIMIT 1
      ''', [currentUser, firstDay, lastDay]);

      return {
        'trackedDays': totals.first['trackedDays'] ?? 0,
        'accountedMinutes': totals.first['accountedMinutes'] ?? 0,
        'unaccountedMinutes': totals.first['unaccountedMinutes'] ?? 0,
        'totalXp': xpTotals.first['totalXp'] ?? 0,
        'xpDays': xpTotals.first['xpDays'] ?? 0,
        'efficiencyScore': xpTotals.first['efficiencyScore'] ?? 0.0,
        'bestDay': bestDay.isEmpty ? null : bestDay.first[MotionDbColumns.date],
        'bestDayXp': bestDay.isEmpty ? 0 : bestDay.first['totalXp'],
        'lowestDay':
            lowestDay.isEmpty ? null : lowestDay.first[MotionDbColumns.date],
        'lowestDayXp': lowestDay.isEmpty ? 0 : lowestDay.first['totalXp'],
      };
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getMonthlyReportSnapshot", e, stackTrace);
    }

    return const {};
  }

  Future<List<Map<String, dynamic>>> getMonthlyDailyXpTrend({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    try {
      final db = await database;

      final rows = await db.rawQuery('''
        SELECT
          ${MotionDbColumns.date},
          ${MotionDbColumns.mainCategoryName},
          COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS totalTimeSpent
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
          AND ${MotionDbColumns.timeSpent} > 0
        GROUP BY ${MotionDbColumns.date}, ${MotionDbColumns.mainCategoryName}
        ORDER BY ${MotionDbColumns.date}
      ''', [currentUser, firstDay, lastDay]);

      final xpByDate = <String, int>{};
      final trackedByDate = <String, int>{};

      for (final row in rows) {
        final date = row[MotionDbColumns.date]?.toString();
        final categoryName = row[MotionDbColumns.mainCategoryName]?.toString();
        if (date == null || categoryName == null) continue;

        final totalMinutes =
            TrackerDatabaseHelper._readDouble(row['totalTimeSpent']).floor();
        trackedByDate[date] = (trackedByDate[date] ?? 0) + totalMinutes;
        xpByDate[date] = (xpByDate[date] ?? 0) +
            MotionXpPolicy.categoryXp(categoryName, totalMinutes);
      }

      for (final entry in trackedByDate.entries) {
        xpByDate[entry.key] = (xpByDate[entry.key] ?? 0) +
            MotionXpPolicy.accountabilityBonusXp(entry.value);
      }

      final sortedDates = xpByDate.keys.toList()..sort();
      return [
        for (final date in sortedDates)
          {
            MotionDbColumns.date: date,
            'totalXp': xpByDate[date] ?? 0,
          }
      ];
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getMonthlyDailyXpTrend", e, stackTrace);
    }

    return const [];
  }

  Future<List<Map<String, dynamic>>> getTopSubcategoriesForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
    int limit = 5,
  }) async {
    try {
      final db = await database;

      return await db.rawQuery('''
        SELECT
          ${MotionDbColumns.subcategoryName},
          ${MotionDbColumns.mainCategoryName},
          COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS totalTimeSpent
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
        GROUP BY ${MotionDbColumns.subcategoryName}, ${MotionDbColumns.mainCategoryName}
        HAVING totalTimeSpent > 0
        ORDER BY totalTimeSpent DESC
        LIMIT ?
      ''', [currentUser, firstDay, lastDay, limit]);
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getTopSubcategoriesForPeriod", e, stackTrace);
    }

    return const [];
  }
}
