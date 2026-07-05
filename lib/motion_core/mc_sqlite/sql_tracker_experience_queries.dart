part of 'sql_tracker_db.dart';

extension TrackerExperienceQueries on TrackerDatabaseHelper {
  // Comprehensive CRUD Operations for the ExperiencePoints Table

  // insert new rows into the experience_points table
  Future<void> insertExperiencePoint(ExperiencePoints experience) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await _ensureMainCategoryRow(
          txn,
          date: experience.date,
          currentUser: experience.currentLoggedInUser,
        );
        await _upsertExperiencePoint(txn, experience);
      });
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get  all data from the experience_points table.
  Future<List<ExperiencePoints>> getAllExperiencePoints(
      {required String date}) async {
    final db = await database;
    final yearRange = SqlDateRange.year(date);
    final result = await db.rawQuery('''
      SELECT *
      FROM experience_points
      WHERE date BETWEEN ? AND ?;
      ''', yearRange.args);

    return result.map((map) => ExperiencePoints.fromMap(map)).toList();
  }

  /// Calculates the average daily efficiency score for the specified user.
  /// Aggregates experience points across categories from `experience_points`
  /// table.
  /// Returns the average score or 0.0 in case of no data or errors.
  ///
  /// Param:
  ///   - `currentUser`: User ID to calculate the score for.
  /// (entire)
  Future<double> entireExperiencePointsEfficiencyScore(
      {required String currentUser}) async {
    try {
      final db = await database;

      final resultEPES = await db.rawQuery('''
          SELECT ROUND(((${TrackerDatabaseHelper._totalXpExpression}) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2) AS efficiencyScore
          FROM experience_points
          WHERE currentLoggedInUser = ?
        ''', [currentUser]);

      if (resultEPES.isNotEmpty) {
        // first row and column
        final totalEPES = resultEPES.first['efficiencyScore'];
        if (totalEPES is double) {
          return totalEPES;
        } else {
          return 0.0; // Handle the case where the result is not a double
        }
      } else {
        return 0.0; // Return 0.0 if no matching records are found
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // (year)
  Future<double> entireYearExperiencePointsEfficiencyScore(
      {required String currentUser, required String currentYear}) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(currentYear);

      final resultEPES = await db.rawQuery('''
          SELECT ROUND(
            ((${TrackerDatabaseHelper._totalXpExpression}) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2
          ) AS efficiencyScore
          FROM experience_points
          WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      ''', [currentUser, ...yearRange.args]);

      if (resultEPES.isNotEmpty) {
        // first row and column
        final totalEPES = resultEPES.first['efficiencyScore'];
        if (totalEPES is double) {
          return totalEPES;
        } else {
          return 0.0; // Handle the case where the result is not a double
        }
      } else {
        return 0.0; // Return 0.0 if no matching records are found
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  /// Calculates the average monthly efficiency score for a user over a
  /// specified date range.
  /// The score is computed as the sum of experience points across categories
  /// (educationXP, workXP, skillsXP, sdXP, sleepXP, accountabilityBonusXP),
  /// divided by the count of distinct days with data within the month.
  /// This ensures an accurate average, considering only days where data is
  /// present.
  ///
  /// Params:
  ///   - `currentUser`: User ID for whom the score is calculated.
  ///   - `firstDayOfMonth`: The start date of the month.
  ///   - `lastDayOfMonth`: The end date of the month.
  /// Returns a double representing the monthly average efficiency score, or
  /// 0.0 if no data is found or in case of an error.
  Future<double> monthlyEfficiencyScore(
      {required String currentUser,
      required String firstDayOfMonth,
      required String lastDayOfMonth}) async {
    try {
      final db = await database;

      final resultMES = await db.rawQuery('''
      SELECT ROUND(((${TrackerDatabaseHelper._totalXpExpression}) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2) AS efficiencyScore
      FROM experience_points
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
    ''', [currentUser, firstDayOfMonth, lastDayOfMonth]);

      if (resultMES.isNotEmpty) {
        // first row and column
        final totalMES = resultMES.first['efficiencyScore'];
        if (totalMES is double) {
          return totalMES;
        } else {
          return 0.0; // Handle the case where the result is not a double
        }
      } else {
        return 0.0; // Return 0.0 if no matching records are found
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // Gets the all time total XP points
  // or XP points for the current year
  Future<int> getTotalXP(
      {required String currentUser,
      required bool isEntire,
      String? year}) async {
    try {
      final db = await database;
      final yearRange = year == null ? null : SqlDateRange.year(year);

      final resultGTXP = isEntire ? await db.rawQuery("""
        SELECT (${TrackerDatabaseHelper._totalXpExpression}) AS entireTotalXP
        FROM experience_points
        WHERE currentLoggedInUser = ?
        """, [currentUser]) : await db.rawQuery("""
        SELECT (${TrackerDatabaseHelper._totalXpExpression}) AS entireTotalXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
          """, [currentUser, ...yearRange!.args]);

      if (resultGTXP.isNotEmpty) {
        // first row and column
        final totalGTXP = resultGTXP.first['entireTotalXP'];
        if (totalGTXP is int) {
          return totalGTXP;
        } else {
          return 0; // Handle the case where the result is not a int
        }
      } else {
        return 0; // Return 0 if no matching records are found
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  Future<int> getYearExperiencePointDays({
    required String currentUser,
    required String year,
  }) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(year);

      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT date) AS trackedDays
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      ''', [currentUser, ...yearRange.args]);

      if (result.isEmpty) return 0;

      final trackedDays = result.first['trackedDays'];
      if (trackedDays is int) return trackedDays;
      return int.tryParse(trackedDays?.toString() ?? '') ?? 0;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getYearExperiencePointDays", e, stackTrace);
    }

    return 0;
  }

  // Gets the efficiency score for the selected date
  // Gets the total experience points for the selected date
  Future<int> dailyExperiencePoints(
      {required String currentUser, required String selectedDate}) async {
    try {
      final db = await database;

      final resultDES = await db.rawQuery('''
      SELECT (${TrackerDatabaseHelper._totalXpExpression}) AS totalXP
      FROM experience_points
      WHERE currentLoggedInUser = ? AND date = ?
    ''', [currentUser, selectedDate]);

      if (resultDES.isNotEmpty) {
        final totalXP = resultDES.first['totalXP'];
        final storedXp = totalXP is num
            ? totalXP.toInt()
            : int.tryParse(totalXP?.toString() ?? '') ?? 0;

        if (storedXp > 0) {
          return storedXp;
        }
      }

      return await _calculateDailyExperiencePointsFromSubcategories(
        db,
        currentUser: currentUser,
        selectedDate: selectedDate,
      );
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.dailyExperiencePoints", e, stackTrace);
    }

    return 0;
  }

  Future<int> _calculateDailyExperiencePointsFromSubcategories(
    DatabaseExecutor db, {
    required String currentUser,
    required String selectedDate,
  }) async {
    final result = await db.rawQuery('''
      SELECT
        ${MotionDbColumns.mainCategoryName},
        COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS totalTimeSpent
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.date} = ?
        AND ${MotionDbColumns.timeSpent} > 0
      GROUP BY ${MotionDbColumns.mainCategoryName}
    ''', [currentUser, selectedDate]);

    var totalTrackedMinutes = 0;
    var totalXp = 0;

    for (final row in result) {
      final categoryName = row[MotionDbColumns.mainCategoryName]?.toString();
      final totalMinutes = TrackerDatabaseHelper._readDouble(row['totalTimeSpent']).floor();
      totalTrackedMinutes += totalMinutes;

      if (categoryName == null) continue;
      totalXp += MotionXpPolicy.categoryXp(categoryName, totalMinutes);
    }

    totalXp += MotionXpPolicy.accountabilityBonusXp(totalTrackedMinutes);
    return totalXp;
  }

  Future<Map<String, int>> dailyExperiencePointBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    try {
      final db = await database;

      final result = await db.query(
        MotionDbTables.experiencePoints,
        columns: const [
          MotionDbColumns.educationXp,
          MotionDbColumns.workXp,
          MotionDbColumns.skillsXp,
          MotionDbColumns.selfDevelopmentXp,
          MotionDbColumns.sleepXp,
          MotionDbColumns.accountabilityBonusXp,
        ],
        where:
            '${MotionDbColumns.currentLoggedInUser} = ? AND ${MotionDbColumns.date} = ?',
        whereArgs: [currentUser, selectedDate],
        limit: 1,
      );

      if (result.isEmpty) {
        return const {
          'Education': 0,
          'Work': 0,
          'Skills': 0,
          'Self Development': 0,
          'Sleep': 0,
          'Tracking Bonus': 0,
        };
      }

      final row = result.first;
      int readXp(String column) {
        final value = row[column];
        return value is int ? value : int.tryParse('$value') ?? 0;
      }

      return {
        'Education': readXp(MotionDbColumns.educationXp),
        'Work': readXp(MotionDbColumns.workXp),
        'Skills': readXp(MotionDbColumns.skillsXp),
        'Self Development': readXp(MotionDbColumns.selfDevelopmentXp),
        'Sleep': readXp(MotionDbColumns.sleepXp),
        'Tracking Bonus': readXp(MotionDbColumns.accountabilityBonusXp),
      };
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.dailyExperiencePointBreakdown", e, stackTrace);
    }

    return const {
      'Education': 0,
      'Work': 0,
      'Skills': 0,
      'Self Development': 0,
      'Sleep': 0,
      'Tracking Bonus': 0,
    };
  }

  Future<Map<String, double>> dailyMainCategoryTimeBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    try {
      final db = await database;

      final result = await db.rawQuery('''
        SELECT
          ${MotionDbColumns.mainCategoryName},
          COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} = ?
        GROUP BY ${MotionDbColumns.mainCategoryName}
      ''', [currentUser, selectedDate]);

      final breakdown = <String, double>{
        'Education': 0,
        'Work': 0,
        'Skills': 0,
        'Self Development': 0,
        'Sleep': 0,
        'Tracking Bonus': 0,
      };

      var totalTracked = 0.0;
      for (final row in result) {
        final category = row[MotionDbColumns.mainCategoryName]?.toString();
        final totalValue = row['total'];
        final total = totalValue is num
            ? totalValue.toDouble()
            : double.tryParse('$totalValue') ?? 0.0;

        totalTracked += total;
        if (category != null && breakdown.containsKey(category)) {
          breakdown[category] = total;
        }
      }

      breakdown['Tracking Bonus'] = totalTracked;
      return breakdown;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.dailyMainCategoryTimeBreakdown",
          e,
          stackTrace);
    }

    return const {
      'Education': 0,
      'Work': 0,
      'Skills': 0,
      'Self Development': 0,
      'Sleep': 0,
      'Tracking Bonus': 0,
    };
  }

  // this function get the most and least productive months
  Future<List<Map<String, dynamic>>> getMostAndLeastProductiveMonths(
      {required bool getMostProductiveMonth,
      required String currentUser,
      required String year}) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(year);

      final resultMALPM = getMostProductiveMonth ? await db.rawQuery("""
          SELECT CASE
                    WHEN month_num = 1 THEN 'January'
                    WHEN month_num = 2 THEN 'February'
                    WHEN month_num = 3 THEN 'March'
                    WHEN month_num = 4 THEN 'April'
                    WHEN month_num = 5 THEN 'May'
                    WHEN month_num = 6 THEN 'June'
                    WHEN month_num = 7 THEN 'July'
                    WHEN month_num = 8 THEN 'August'
                    WHEN month_num = 9 THEN 'September'
                    WHEN month_num = 10 THEN 'October'
                    WHEN month_num = 11 THEN 'November'
                    WHEN month_num = 12 THEN 'December'
                    ELSE 'TBD'
                END AS month,
                COALESCE(MAX(totalMostXP), 0) AS most_productive
          FROM (
              SELECT CAST(strftime('%m', date) AS INTEGER) AS month_num,
                    (${TrackerDatabaseHelper._totalXpExpression}) AS totalMostXP
              FROM experience_points
              WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
              GROUP BY month_num
          ) AS totalMostXP
        """, [currentUser, ...yearRange.args]) : await db.rawQuery("""
        SELECT CASE
                  WHEN month_num = 1 THEN 'January'
                  WHEN month_num = 2 THEN 'February'
                  WHEN month_num = 3 THEN 'March'
                  WHEN month_num = 4 THEN 'April'
                  WHEN month_num = 5 THEN 'May'
                  WHEN month_num = 6 THEN 'June'
                  WHEN month_num = 7 THEN 'July'
                  WHEN month_num = 8 THEN 'August'
                  WHEN month_num = 9 THEN 'September'
                  WHEN month_num = 10 THEN 'October'
                  WHEN month_num = 11 THEN 'November'
                  WHEN month_num = 12 THEN 'December'
                  ELSE 'TBD'
              END AS month,
              COALESCE(MIN(totalLeastXP), 0) AS totalLeastXP
        FROM (
            SELECT CAST(strftime('%m', date) AS INTEGER) AS month_num,
                  (${TrackerDatabaseHelper._totalXpExpression}) AS totalLeastXP
            FROM experience_points
            WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
            GROUP BY month_num
        ) AS totalLeastXP
          """, [currentUser, ...yearRange.args]);
      return resultMALPM;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the most and least productive days
  Future<List<Map<String, dynamic>>> getMostAndLeastProductiveDays(
      {required String currentUser,
      required String firstDay,
      required String lastDay,
      required bool getMostProductiveDay}) async {
    try {
      final db = await database;

      // the most and least productive days result
      final resultMALPD = getMostProductiveDay ? await db.rawQuery("""
      SELECT COALESCE(date, 'TBD') AS date, COALESCE(MAX(totalMostXP),0) AS most_productive
      FROM (
        SELECT date, (${TrackerDatabaseHelper._totalXpExpression}) AS totalMostXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date
      ) AS totalMostXP
        """, [currentUser, firstDay, lastDay]) : await db.rawQuery("""
      SELECT COALESCE(date, 'TBD') AS date, COALESCE(MIN(totalLeastXP),0) AS least_productive
      FROM (
        SELECT date, (${TrackerDatabaseHelper._totalXpExpression}) AS totalLeastXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date
      ) AS totalLeastXP
        """, [currentUser, firstDay, lastDay]);

      return resultMALPD;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  /// Fetches *all* experience_points rows for [currentUser].
  Future<List<ExperiencePoints>> getAllExperiencePointsForUser({
    required String currentUser,
  }) async {
    final db = await database;
    // Query every column in the table, filtered by the user
    final result = await db.query(
      MotionDbTables.experiencePoints,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
    );

    // Map each row to your model
    return result.map((row) => ExperiencePoints.fromMap(row)).toList();
  }

}
