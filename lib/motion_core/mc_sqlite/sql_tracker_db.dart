import 'package:flutter/foundation.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/database_error.dart';
import 'package:motion/motion_core/mc_sqlite/sql_date_range.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// tracker database that store two tables
// subcategory table and main category table
// subcategory table tracks subcategories
// main category table tracks the aggregated subcategories
class TrackerDatabaseHelper {
  static final DateTime _firstTrackingDate = DateTime(2021, 7, 1);
  static const String _totalXpExpression = '''
    COALESCE(SUM(${MotionDbColumns.educationXp}), 0) +
    COALESCE(SUM(${MotionDbColumns.workXp}), 0) +
    COALESCE(SUM(${MotionDbColumns.skillsXp}), 0) +
    COALESCE(SUM(${MotionDbColumns.selfDevelopmentXp}), 0) +
    COALESCE(SUM(${MotionDbColumns.sleepXp}), 0) +
    COALESCE(SUM(${MotionDbColumns.accountabilityBonusXp}), 0)
  ''';

  // Singleton instance
  static final TrackerDatabaseHelper _instance =
      TrackerDatabaseHelper._privateConstructor();

  // Database instance
  static Database? _database;

  TrackerDatabaseHelper._privateConstructor();

  factory TrackerDatabaseHelper() {
    return _instance;
  }

  // Initialize and/or return the database instance
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tracker.db');

    return await openDatabase(
      path,
      version: TrackerDatabaseSchema.version,
      onConfigure: TrackerDatabaseSchema.configure,
      onCreate: _createDatabase,
      onUpgrade: _onUpgradeDatabase,
      onOpen: TrackerDatabaseSchema.ensureSchema,
    );
  }

  Future<void> _onUpgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    logger.i("Database _onUpgradeDatabase function called");
    await TrackerDatabaseSchema.migrate(db, oldVersion, newVersion);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await TrackerDatabaseSchema.create(db);
  }

  Future<void> _ensureDailyRows(
    DatabaseExecutor db, {
    required String date,
    required String currentUser,
  }) async {
    await _ensureMainCategoryRow(db, date: date, currentUser: currentUser);
    await _ensureExperiencePointRow(db, date: date, currentUser: currentUser);
  }

  Future<void> _ensureMainCategoryRow(
    DatabaseExecutor db, {
    required String date,
    required String currentUser,
  }) async {
    await db.insert(
      MotionDbTables.mainCategory,
      MainCategory(date: date, currentLoggedInUser: currentUser).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _ensureExperiencePointRow(
    DatabaseExecutor db, {
    required String date,
    required String currentUser,
  }) async {
    await db.insert(
      MotionDbTables.experiencePoints,
      ExperiencePoints(date: date, currentLoggedInUser: currentUser).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _upsertMainCategory(
    DatabaseExecutor db,
    MainCategory mainCategory,
  ) async {
    final values = mainCategory.toMap();

    await db.insert(
      MotionDbTables.mainCategory,
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.update(
      MotionDbTables.mainCategory,
      values,
      where:
          '${MotionDbColumns.date} = ? AND ${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [mainCategory.date, mainCategory.currentLoggedInUser],
    );
  }

  Future<void> _upsertExperiencePoint(
    DatabaseExecutor db,
    ExperiencePoints experience,
  ) async {
    final values = experience.toMap();

    await db.insert(
      MotionDbTables.experiencePoints,
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.update(
      MotionDbTables.experiencePoints,
      values,
      where:
          '${MotionDbColumns.date} = ? AND ${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [experience.date, experience.currentLoggedInUser],
    );
  }

// CRUD operations for MainCategory

  // insert new rows into the main category table
  Future<void> insertMainCategory(MainCategory mainCategory) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await _upsertMainCategory(txn, mainCategory);
        await _ensureExperiencePointRow(
          txn,
          date: mainCategory.date,
          currentUser: mainCategory.currentLoggedInUser,
        );
      });
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get an left join table of main category table time spent
  // totals for a particular date and experience point earned from each
  // main category
  Future<List<Map<String, dynamic>>> getMCTotalAndXPEarned(
      {required String currentUser, required String targetDate}) async {
    try {
      final db = await database;

      final resultLJOMXP = await db.rawQuery('''
        SELECT
            mainCategoryName,
            totalTimeSpent,
            CASE
                WHEN mainCategoryName = 'Work' THEN
                    CAST(CASE
                        WHEN CAST(totalTimeSpent / 12 AS INTEGER) > 25 THEN 25
                        ELSE CAST(totalTimeSpent / 12 AS INTEGER)
                    END AS TEXT)
                WHEN mainCategoryName IN ('Education', 'Skills', 'Self Development') THEN
                    CAST(CASE
                        WHEN CAST(totalTimeSpent / 12 AS INTEGER) > 20 THEN 20
                        ELSE CAST(totalTimeSpent / 12 AS INTEGER)
                    END AS TEXT)
                WHEN mainCategoryName = 'Sleep' THEN
                    CASE
                        WHEN totalTimeSpent < 300 THEN '0'
                        WHEN totalTimeSpent < 360 THEN '8'
                        WHEN totalTimeSpent < 420 THEN '15'
                        WHEN totalTimeSpent <= 540 THEN '25'
                        WHEN totalTimeSpent <= 600 THEN '15'
                        ELSE '5'
                    END
                WHEN mainCategoryName = 'Entertainment' THEN
                    'N/A'
                ELSE '0'
            END AS xp_earned
        FROM
            (
                SELECT
                    mainCategoryName,
                    SUM(timeSpent) AS totalTimeSpent
                FROM
                    subcategory
                WHERE
                    currentLoggedInUser = ? AND date = ?
                GROUP BY
                    mainCategoryName
                ORDER BY totalTimeSpent DESC
            );

        ''', [currentUser, targetDate]);

      return resultLJOMXP;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the totals for all 5 main categories
  Future<List<Map<String, dynamic>>> getAllMainCategoryTotals(
      {required String currentUser}) async {
    try {
      final db = await database;

      final resultAMCT = await db.rawQuery("""
          SELECT
              CAST(ROUND(COALESCE(SUM(education)/60, 0), 2) AS VARCHAR) AS "educationHours",
              CAST(ROUND(COALESCE(SUM(education)/1440, 0), 2) AS VARCHAR) AS "educationDays",
              CAST(ROUND(COALESCE(AVG(education)/60, 0), 2) AS VARCHAR) AS "educationAverage",
              CAST(ROUND(COALESCE(SUM(work)/60, 0), 2) AS VARCHAR) AS "workHours",
              CAST(ROUND(COALESCE(SUM(work)/1440, 0), 2) AS VARCHAR) AS "workDays",
              CAST(ROUND(COALESCE(AVG(work)/60, 0), 2) AS VARCHAR) AS "workAverage",
              CAST(ROUND(COALESCE(SUM(skills)/60, 0), 2) AS VARCHAR) AS "skillHours",
              CAST(ROUND(COALESCE(SUM(skills)/1440, 0), 2) AS VARCHAR) AS "skillDays",
              CAST(ROUND(COALESCE(AVG(skills)/60, 0), 2) AS VARCHAR) AS "skillAverage",
              CAST(ROUND(COALESCE(SUM(entertainment)/60, 0), 2) AS VARCHAR) AS "entertainmentHours",
              CAST(ROUND(COALESCE(SUM(entertainment)/1440, 0), 2) AS VARCHAR) AS "entertainmentDays",
              CAST(ROUND(COALESCE(AVG(entertainment)/60, 0), 2) AS VARCHAR) AS "entertainmentAverage",
              CAST(ROUND(COALESCE(SUM(selfDevelopment)/60, 0), 2) AS VARCHAR) AS "pgHours",
              CAST(ROUND(COALESCE(SUM(selfDevelopment)/1440, 0), 2) AS VARCHAR) AS "pgDays",
              CAST(ROUND(COALESCE(AVG(selfDevelopment)/60, 0), 2) AS VARCHAR) AS "pgAverage",
              CAST(ROUND(COALESCE(SUM(sleep)/60, 0), 2) AS VARCHAR) AS "sleepHours",
              CAST(ROUND(COALESCE(SUM(sleep)/1440, 0), 2) AS VARCHAR) AS "sleepDays",
              CAST(ROUND(COALESCE(AVG(sleep)/60, 0), 2) AS VARCHAR) AS "sleepAverage"
          FROM main_category
          WHERE currentLoggedInUser = ?
          """, [currentUser]);
      return resultAMCT;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // count the number of days in the main_category table
  Future<int> getNumberOfDays(
      {required String currentUser,
      bool getAllDays = true,
      String currentYear = ""}) async {
    try {
      final today = _dateOnly(DateTime.now());
      if (getAllDays) {
        return _inclusiveDaysBetween(_firstTrackingDate, today);
      }

      final currentYearInt = int.tryParse(currentYear);
      if (currentYearInt == today.year) {
        return _inclusiveDaysBetween(DateTime(today.year), today);
      }

      final db = await database;
      final yearRange = SqlDateRange.year(currentYear);

      // number of days
      final resultGNOD = await db.rawQuery('''
        SELECT COUNT(DISTINCT date) AS NumberOfDays
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      ''', [currentUser, ...yearRange.args]);

      // check if the result is empty
      if (resultGNOD.isNotEmpty) {
        final numberOfDays = resultGNOD.first["NumberOfDays"];

        if (numberOfDays is int) {
          return numberOfDays;
        }
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }

    return 0; // Return 0 if there is no result.
  }

  // count the number of days in the main_category table for the current year
  Future<int> getNumberOfDaysInYear(
      {required String currentUser, required String currentYear}) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(currentYear);

      // number of days
      final resultGNODY = await db.rawQuery('''
      SELECT COUNT(DISTINCT date) AS NumberOfDays
      FROM main_category
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
    ''', [currentUser, ...yearRange.args]);

      // check if the result is empty
      if (resultGNODY.isNotEmpty) {
        final numberOfDays = resultGNODY.first["NumberOfDays"];

        if (numberOfDays is int) {
          return numberOfDays;
        }
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }

    return 0; // Return 0 if there is no result.
  }

  // gets all the entries added to the main category table
  Future<List<MainCategory>> getAllMainCategories() async {
    try {
      final db = await database;

      final allMainCats = await db.rawQuery('''
      SELECT *
      FROM main_category;
      ''');

      return allMainCats.map((map) => MainCategory.fromMap(map)).toList();
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
    return [];
  }

  // gets the entire total for the timeSpent column of the main_category table
  Future<double> getEntireTotalMainCategoryTable(
      String currentUser, bool isUnaccounted) async {
    try {
      final db = await database;

      // if the isUnaccounted = true then the results
      // will be for the entire unaccounted time
      // if it's false the accounted time

      final resultETMCT = isUnaccounted ? await db.rawQuery('''
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) +
        COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0))
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ?
        ''', [currentUser]) : await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
        + COALESCE(SUM(sleep), 0) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ?
        ''', [currentUser]);

      if (resultETMCT.isNotEmpty) {
        final totalETMCT = resultETMCT.first["EntireTotalResult"];
        if (totalETMCT is double) {
          return totalETMCT;
        } else {
          logger.i("No data so a 0.0 is being returned");
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper.getEntireTotalMainCategoryTable",
          e, stackTrace);
    }
  }

  // gets the entire total for the timeSpent column of the main_category table
  // for the current year
  Future<double> getEntireYearTotalMainCategoryTable(
      String currentUser, bool isUnaccounted, String currentYear) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(currentYear);

      final query = isUnaccounted
          ? '''
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) +
        COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0))
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        '''
          : '''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
        + COALESCE(SUM(sleep), 0) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        ''';

      final resultETMCT = await db.rawQuery(query, [currentUser, ...yearRange.args]);

      if (resultETMCT.isNotEmpty) {
        final totalETMCT = resultETMCT.first["EntireTotalResult"];
        if (totalETMCT is double) {
          return totalETMCT;
        } else {
          logger.i("No data so a 0.0 is being returned");
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the accounted and unaccounted totals broken down by year
  Future<List<Map<String, dynamic>>> getAccountedAndUnaccountedBrokenByYears(
      {required String currentUser}) async {
    try {
      final db = await database;

      // this query returns a table of accounted and unaccounte
      // totals grouped by the year
      final resultAAUBBY = await db.rawQuery('''
        SELECT  (COALESCE(SUM(education), 0.0) + COALESCE(SUM(work), 0.0) + COALESCE(SUM(skills), 0.0)
                + COALESCE(SUM(entertainment), 0.0) + COALESCE(SUM(selfDevelopment), 0.0)
                + COALESCE(SUM(sleep), 0.0))/60 AS Accounted,
                (((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0.0) + COALESCE(SUM(work), 0.0) + COALESCE(SUM(skills), 0.0) + COALESCE(SUM(entertainment), 0.0)
                + COALESCE(SUM(selfDevelopment), 0.0) + COALESCE(SUM(sleep), 0.0)))/60
                AS Unaccounted,
                strftime('%Y', date) AS Year
        FROM main_category
        WHERE currentLoggedInUser = ?
        GROUP BY Year
        ''', [currentUser]);

      return resultAAUBBY;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
    return [];
  }

  // gets the accounted and unaccounted totals for each month during a
  // particular year
  Future<List<Map<String, dynamic>>> getMonthDistibutionOfAccountedUnaccounted(
      {required String currentUser, required String year}) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(year);

      final resultMDAUA = await db.rawQuery('''
          SELECT  strftime('%m', date) AS Month,
                (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
              + COALESCE(SUM(entertainment), 0) +
              COALESCE(SUM(selfDevelopment), 0)
              + COALESCE(SUM(sleep), 0))/60 AS Accounted,
              (((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0) +
                COALESCE(SUM(entertainment), 0)
          + COALESCE(SUM(selfDevelopment), 0) +
          COALESCE(SUM(sleep), 0)))/60 AS Unaccounted
      FROM main_category
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY Month
        ''', [currentUser, ...yearRange.args]);

      return resultMDAUA;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the monthly entire main category total
  Future<double> getEntireMonthlyTotalMainCategoryTable(
    String currentUser,
    String firstDay,
    String lastDay,
    bool isUnaccounted,
  ) async {
    try {
      final db = await database;

      final resultEMTMC = isUnaccounted ? await db.rawQuery('''
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0)
        + COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0))
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
            ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
        + COALESCE(SUM(sleep), 0) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
            ''', [currentUser, firstDay, lastDay]);

      if (resultEMTMC.isNotEmpty) {
        final totalEMTMC = resultEMTMC.first["EntireTotalResult"];
        if (totalEMTMC is double) {
          return totalEMTMC;
        } else {
          logger.i("No data available : $totalEMTMC");
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get accounted time and unaccounted time for everyday
  // for a particular week
  Future<List<Map<String, dynamic>>> getAWeekOfAccountedAndAccountedData(
      {required String currentUser,
      required String firstDatePeriod,
      required String lastDatePeriod}) async {
    try {
      final db = await database;

      final resultAWAAD = await db.rawQuery('''
        SELECT
            date,
            (COALESCE(education, 0) + COALESCE(work, 0) + COALESCE(skills, 0) +
            COALESCE(entertainment, 0) + COALESCE(selfDevelopment, 0) +
            COALESCE(sleep, 0))/60 AS Accounted,
            24 - (COALESCE(education, 0) + COALESCE(work, 0) + COALESCE(skills, 0) +
            COALESCE(entertainment, 0) + COALESCE(selfDevelopment, 0) +
            COALESCE(sleep, 0))/60 AS Unaccounted
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        ORDER BY date;
        ''', [currentUser, firstDatePeriod, lastDatePeriod]);

      return resultAWAAD;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get a table for both accounted and unaccounted values
  Future<List<Map<String, dynamic>>> getMonthAccountUnaccountTable(
      String currentUser, firstDay, lastDay) async {
    try {
      final db = await database;

      final resultMAT = await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
        + COALESCE(SUM(sleep), 0) AS Accounted, ((COUNT(date) * 24)*60)
         - (COALESCE(SUM(education), 0) + COALESCE(SUM(work), 0) + COALESCE(SUM(skills), 0)
         + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
         + COALESCE(SUM(sleep), 0)) AS Unaccounted
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        ''', [currentUser, firstDay, lastDay]);

      return resultMAT;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the most and least tracked main category
  Future<List<Map<String, dynamic>>> getMostAndLeastTrackedMainCategory(
      {required String firstDay,
      required String lastDay,
      required String currentUser,
      required bool isMost}) async {
    try {
      final db = await database;

      // if isMost is true then the result returned will be
      // for the most tracked main category if isMost is false
      // then the least tracked main category is returned
      final resultMLTMC = isMost ? await db.rawQuery('''
      SELECT mainCategoryName AS result_tracked_category, COALESCE(SUM(timeSpent), 0)
      AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? AND
      mainCategoryName != 'Sleep'
      GROUP BY mainCategoryName
      ORDER BY time_spent DESC
      LIMIT 1
      ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
      SELECT mainCategoryName AS result_tracked_category, COALESCE(SUM(timeSpent), 0)
      AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY mainCategoryName
      ORDER BY time_spent ASC
      LIMIT 1
          ''', [currentUser, firstDay, lastDay]);

      return resultMLTMC;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the total time time spent for the main category
  // during a specified period of time
  Future<List<Map<String, dynamic>>> getMainTotalTimeSpentSpecificDates(
      {required String currentUser,
      required String firstDay,
      required String lastDay}) async {
    try {
      final db = await database;

      // returns a list of Map objects for the main categories
      // together with their totals for the specified dates.
      final resultMTTSSD = await db.rawQuery('''
        SELECT mainCategoryName, COALESCE(SUM(timeSpent)/60, 0) AS totalTimeSpent
        FROM subcategory
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY mainCategoryName
        ''', [currentUser, firstDay, lastDay]);

      return resultMTTSSD;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getMainTotalTimeSpentSpecificDates",
          e,
          stackTrace);
    }
  }

  // get the entire total time spent for the main category
  Future<List<Map<String, dynamic>>> getEntireMainTotalTimeSpent(
      {required String currentUser}) async {
    try {
      final db = await database;

      // returns a list of Map objects for the main categories
      // together with their totals
      final resultEMTTS = await db.rawQuery('''
        SELECT mainCategoryName, COALESCE(SUM(timeSpent)/60, 0) AS totalTimeSpent
        FROM subcategory
        WHERE currentLoggedInUser = ?
        GROUP BY mainCategoryName
        ''', [currentUser]);

      return resultEMTTS;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getEntireMainTotalTimeSpent", e, stackTrace);
    }
  }

  // get yearly totals for all the main categories
  Future<List<Map<String, dynamic>>> getYearlyTotalsForAllMainCatgories(
      {required String currentUser, required String year}) async {
    try {
      final db = await database;
      final yearRange = SqlDateRange.year(year);

      final resultYTFAMC = await db.rawQuery('''
        SELECT
          strftime('%m', date) AS Month,
          ROUND(COALESCE(SUM(education) / 60.0, 0), 2) AS education,
          ROUND(COALESCE(SUM(work) / 60.0, 0), 2) AS work,
          ROUND(COALESCE(SUM(skills) / 60.0, 0), 2) AS skills,
          ROUND(COALESCE(SUM(entertainment) / 60.0, 0), 2) AS entertainment,
          ROUND(COALESCE(SUM(selfDevelopment) / 60.0, 0), 2) AS selfDevelopment,
          ROUND(COALESCE(SUM(sleep) / 60.0, 0), 2) AS sleep
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY Month;
        ''', [currentUser, ...yearRange.args]);

      return resultYTFAMC;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the daily accounted and intensity score for all main categories
  Future<List<Map<String, dynamic>>> getDailyAccountedAndIntensities(
      {required String currentUser,
      String year = "",
      bool getEntireIntensity = true}) async {
    try {
      final db = await database;
      final yearRange = year.isEmpty ? null : SqlDateRange.year(year);

      final resultDAAI = getEntireIntensity ? await db.rawQuery('''
            SELECT date,
                  ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) AS accounted,
                  CASE
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 0 THEN 0
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 5 THEN 5
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 10 THEN 10
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 15 THEN 15
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 20 THEN 20
                      ELSE 25
                  END AS intensity
            FROM subcategory
            WHERE currentLoggedInUser = ?
            GROUP BY date

        ''', [currentUser]) : await db.rawQuery('''
            SELECT date,
                  ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) AS accounted,
                  CASE
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 0 THEN 0
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 5 THEN 5
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 10 THEN 10
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 15 THEN 15
                      WHEN ROUND(COALESCE(SUM(timeSpent), 0) / 60, 2) <= 20 THEN 20
                      ELSE 25
                  END AS intensity
            FROM subcategory
            WHERE currentLoggedInUser = ?
              AND date BETWEEN ? AND ?
            GROUP BY date

        ''', [currentUser, ...yearRange!.args]);

      return resultDAAI;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // updates existing main categories rows
  Future<void> updateMainCategory(MainCategory mainCategory) async {
    try {
      final db = await database;
      await db.update(MotionDbTables.mainCategory, mainCategory.toMap(),
          where: '${MotionDbColumns.date} = ?', whereArgs: [mainCategory.date]);
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // delete rows in the main category table
  Future<void> deleteMainCategory(String date) async {
    try {
      final db = await database;
      await db.delete(MotionDbTables.mainCategory,
          where: '${MotionDbColumns.date} = ?', whereArgs: [date]);
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the top 3 main category excluding the sleep category

  // Future<void> updateCurrentUser() async {
  //   final db = await database;

  //   await db.rawQuery(
  //     '''
  //     UPDATE main_category
  //     SET currentLoggedInUser = 'hhANBj74wiclvfuDLGfuDlFZgJ62'
  //     '''
  //   );
  // }

// CRUD OPERATION FOR SUBCATEGORY TABLE

  // insert new rows into the subcategory category table
  Future<int> insertSubcategory(Subcategories subcategory) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        await _ensureDailyRows(
          txn,
          date: subcategory.date,
          currentUser: subcategory.currentLoggedInUser,
        );
        return txn.insert(
          MotionDbTables.subcategory,
          subcategory.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      });
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get all data in the subcategories table
  Future<List<Subcategories>> getAllSubcategories() async {
    try {
      final db = await database;

      final allSubs = await db.query(MotionDbTables.subcategory);

      return allSubs.map((map) => Subcategories.fromMap(map)).toList();
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // gets all the subcategory totals
  Future<List<Map<String, dynamic>>> getAllSubcategoryTotals(
      {required String currentUser}) async {
    try {
      final db = await database;

      final allSubTotals = await db.rawQuery("""
        SELECT subcategoryName, COALESCE(SUM(timeSpent), 0) AS total,
        COALESCE(AVG(timeSpent), 0) AS average
        FROM subcategory
        WHERE currentLoggedInUser = ?
        GROUP BY subcategoryName
        ORDER BY total DESC
        """, [currentUser]);

      return allSubTotals;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // gets all the subcategories depending on the current date
  Future<List<Subcategories>> getCurrentDateSubcategory(
      String currentDate, String currentUser, String subcategoryName) async {
    try {
      final db = await database;

      final specificSubcategories = await db.query(MotionDbTables.subcategory,
          where:
              "${MotionDbColumns.date} = ? AND ${MotionDbColumns.currentLoggedInUser} = ? AND ${MotionDbColumns.subcategoryName} = ?",
          whereArgs: [currentDate, currentUser, subcategoryName]);

      return specificSubcategories
          .map((map) => Subcategories.fromMap(map))
          .toList();
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // calculate and return the total time spent on
  // all the categories for a particular date
  Future<double> getTotalTimeForCurrentDate(
      String currentDate, String currentUser) async {
    try {
      final db = await database;

      final result = await db.rawQuery('''
    SELECT COALESCE(SUM(timeSpent), 0) as total
    FROM subcategory
    WHERE date = ? AND currentLoggedInUser = ?;
    ''', [currentDate, currentUser]);

      if (result.isNotEmpty) {
        final total = result.first["total"];
        if (total is double) {
          return total;
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

  Future<Map<String, double>> getSubcategoryTotalsForDate({
    required String currentDate,
    required String currentUser,
  }) async {
    try {
      final db = await database;

      final result = await db.rawQuery('''
        SELECT ${MotionDbColumns.subcategoryName},
               COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
        FROM ${MotionDbTables.subcategory}
        WHERE ${MotionDbColumns.date} = ?
          AND ${MotionDbColumns.currentLoggedInUser} = ?
        GROUP BY ${MotionDbColumns.subcategoryName}
      ''', [currentDate, currentUser]);

      return {
        for (final row in result)
          row[MotionDbColumns.subcategoryName].toString():
              _readDouble(row['total']),
      };
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getSubcategoryTotalsForDate", e, stackTrace);
    }

    return {};
  }

  // gets the total time spent on all subcategories for an entire month
  Future<double> getMonthTotalTimeSpent(
      String currentUser, String startingDate, String endingDate) async {
    try {
      final db = await database;

      final resultMTTS = await db.rawQuery('''
      SELECT COALESCE(SUM(timeSpent), 0) as total
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?;
    ''', [currentUser, startingDate, endingDate]);

      if (resultMTTS.isNotEmpty) {
        final totalMTTS = resultMTTS.first["total"];
        if (totalMTTS is double) {
          return totalMTTS;
        }
      }
      return 0.0; // Return a default value if no data or invalid data is found.
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getMonthTotalTimeSpent", e, stackTrace);
    }
  }

  /// Returns a list of maps containing category names, total time spent, average time per day,
  /// and for subcategories, the streak of consecutive days with nonzero timeSpent.
  ///
  /// This revised function calculates:
  ///  1. Daily totals (per day and subcategory) for the given date range.
  ///  2. Totals and averages per subcategory.
  ///  3. For streaks, it fetches relevant dates and calculates the streak in Dart logic
  ///     by iterating backwards from the most recent date.
  /// Retrieves total and average time spent on subcategories or main categories for a user.
  /// If isSubcategory is true, it also calculates the streak for each subcategory.
  ///
  /// - currentUser: The ID of the user.
  /// - startingDate, endingDate: The date range for fetching data.
  /// - isSubcategory: If true, fetches data for subcategories; otherwise, fetches for main categories.
  ///
  /// Returns a list of maps containing category names, total time spent, average time per day,
  /// and for subcategories, the streak of consecutive days with nonzero timeSpent.
  /// Retrieves the total and average time spent for each category (main or subcategory)
  /// within a given date range for the specified user.
  ///
  /// - `currentUser`: The ID of the currently logged-in user.
  /// - `startingDate`: The start date for filtering records.
  /// - `endingDate`: The end date for filtering records.
  /// - `isSubcategory`: If true, retrieves data for subcategories; otherwise, retrieves for main categories.
  ///
  /// Returns a list of maps containing category names, total time spent, and average time spent.
  Future<List<Map<String, dynamic>>> getMonthTotalAndAverage(String currentUser,
      String startingDate, String endingDate, bool isSubcategory) async {
    final db = await database;

    try {
      final resultMTA = isSubcategory ? await db.rawQuery('''
      SELECT subcategoryName, COALESCE(SUM(timeSpent), 0) AS total,
      COALESCE(AVG(timeSpent), 0) AS average
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? AND timeSpent > 0
      GROUP BY subcategoryName
      ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate]) : await db.rawQuery('''
      SELECT mainCategoryName, COALESCE(SUM(dailyTotal),0) AS total,
      COALESCE(AVG(dailyTotal), 0) AS average
      FROM (
        SELECT date, mainCategoryName, COALESCE(SUM(timeSpent), 0) AS dailyTotal
        FROM subcategory
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? AND timeSpent > 0
        GROUP BY date, mainCategoryName
      )
      GROUP BY mainCategoryName
      ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate]);

      return resultMTA;
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.getMonthTotalAndAverage", e, stackTrace);
    }
  }

  /// Calculates the user's tracking streak through the latest tracked day.
  ///
  /// A streak is a run of consecutive calendar days where the user logged at
  /// least one subcategory with timeSpent greater than zero. The streak is
  /// counted backward from the latest tracked day in the database, which keeps
  /// delayed CSV imports from making the streak appear as zero.
  Future<int> getUserStreak({required String currentUser}) async {
    final db = await database;

    final List<Map<String, dynamic>> records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date}
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
      GROUP BY ${MotionDbColumns.date}
      HAVING COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) > 0
      ORDER BY ${MotionDbColumns.date} DESC
    ''', [currentUser]);

    if (records.isEmpty) return 0;

    final trackedDates = records
        .map((record) => _parseStoredDate(record[MotionDbColumns.date]))
        .whereType<DateTime>()
        .toSet()
        .toList();
    trackedDates.sort((a, b) => b.compareTo(a));

    if (trackedDates.isEmpty) return 0;

    final latestTrackedDate = trackedDates.first;
    var streak = 1;
    var expectedPreviousDate =
        latestTrackedDate.subtract(const Duration(days: 1));

    for (final trackedDate in trackedDates.skip(1)) {
      if (trackedDate == expectedPreviousDate) {
        streak++;
        expectedPreviousDate =
            expectedPreviousDate.subtract(const Duration(days: 1));
      } else if (trackedDate.isBefore(expectedPreviousDate)) {
        break;
      }
    }

    return streak;
  }

  Future<SubcategoryStreakStatus> getSubcategoryStreakStatus({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
  }) async {
    final db = await database;

    final firstTrackedDate = await _getFirstTrackedDateForSubcategory(
      db,
      currentUser: currentUser,
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );
    final savedStartDate = _parseStoredDate(startDate);
    final currentDay =
        _dateOnly(_parseStoredDate(currentDate) ?? DateTime.now());
    final effectiveStartDay = _earliestDate(
      firstTrackedDate,
      savedStartDate,
    ) ?? currentDay;
    final effectiveStartDate = _formatIsoDate(effectiveStartDay);

    final records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date},
             COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.subcategoryName} = ?
        AND ${MotionDbColumns.mainCategoryName} = ?
        AND ${MotionDbColumns.date} BETWEEN ? AND ?
      GROUP BY ${MotionDbColumns.date}
      ORDER BY ${MotionDbColumns.date} ASC
    ''', [
      currentUser,
      subcategoryName,
      mainCategoryName,
      effectiveStartDate,
      currentDate,
    ]);

    final dailyTotals = <DateTime, double>{};
    for (final record in records) {
      final date = _parseStoredDate(record[MotionDbColumns.date]);
      if (date == null) continue;
      dailyTotals[_dateOnly(date)] = _readDouble(record["total"]);
    }

    final today = currentDay;
    final firstDay = effectiveStartDay;

    bool metTarget(DateTime date) {
      final total = dailyTotals[date] ?? 0.0;
      if (streakType == SubcategoryStreakType.targetTime) {
        return total >= targetMinutes;
      }
      return total > 0;
    }

    var bestStreak = 0;
    var runningStreak = 0;
    var metDays = 0;
    DateTime? runningStartDate;
    DateTime? bestStartDate;
    DateTime? bestEndDate;
    for (var date = firstDay;
        !date.isAfter(today);
        date = date.add(const Duration(days: 1))) {
      if (metTarget(date)) {
        metDays++;
        runningStartDate ??= date;
        runningStreak++;
        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
          bestStartDate = runningStartDate;
          bestEndDate = date;
        }
      } else {
        runningStreak = 0;
        runningStartDate = null;
      }
    }

    final todayMinutes = dailyTotals[today] ?? 0.0;
    final hasMetToday = metTarget(today);

    var currentStreak = 0;
    DateTime? currentStreakStartDate;
    if (hasMetToday) {
      currentStreak = 1;
      currentStreakStartDate = today;
      var expectedDate = today.subtract(const Duration(days: 1));
      while (!expectedDate.isBefore(firstDay) && metTarget(expectedDate)) {
        currentStreak++;
        currentStreakStartDate = expectedDate;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      }
    } else {
      var expectedDate = today.subtract(const Duration(days: 1));
      while (!expectedDate.isBefore(firstDay) && metTarget(expectedDate)) {
        currentStreak++;
        currentStreakStartDate = expectedDate;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      }
    }

    final todayStatus = hasMetToday
        ? SubcategoryStreakTodayStatus.metToday
        : currentStreak > 0 || firstDay == today
            ? SubcategoryStreakTodayStatus.atRisk
            : SubcategoryStreakTodayStatus.missed;

    return SubcategoryStreakStatus(
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
      streakType: streakType,
      targetMinutes: targetMinutes,
      startDate: effectiveStartDate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      currentStreakStartDate: currentStreakStartDate == null
          ? ''
          : _formatIsoDate(currentStreakStartDate!),
      bestStreakStartDate:
          bestStartDate == null ? '' : _formatIsoDate(bestStartDate!),
      bestStreakEndDate:
          bestEndDate == null ? '' : _formatIsoDate(bestEndDate!),
      metDays: metDays,
      totalDays: _inclusiveDaysBetween(firstDay, today),
      todayMinutes: todayMinutes,
      todayStatus: todayStatus,
    );
  }

  Future<String?> getFirstTrackedDateForSubcategory({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
  }) async {
    final db = await database;
    final firstTrackedDate = await _getFirstTrackedDateForSubcategory(
      db,
      currentUser: currentUser,
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );

    return firstTrackedDate == null ? null : _formatIsoDate(firstTrackedDate);
  }

  Future<List<SubcategoryStreakHistoryPoint>> getSubcategoryStreakHistory({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
    required SubcategoryStreakHistoryRange range,
  }) async {
    final db = await database;
    final firstTrackedDate = await _getFirstTrackedDateForSubcategory(
      db,
      currentUser: currentUser,
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );
    final savedStartDate = _parseStoredDate(startDate);
    final currentDay =
        _dateOnly(_parseStoredDate(currentDate) ?? DateTime.now());
    final effectiveStartDay = _earliestDate(
      firstTrackedDate,
      savedStartDate,
    ) ?? currentDay;
    final effectiveStartDate = _formatIsoDate(effectiveStartDay);

    final records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date},
             COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.subcategoryName} = ?
        AND ${MotionDbColumns.mainCategoryName} = ?
        AND ${MotionDbColumns.date} BETWEEN ? AND ?
      GROUP BY ${MotionDbColumns.date}
      ORDER BY ${MotionDbColumns.date} ASC
    ''', [
      currentUser,
      subcategoryName,
      mainCategoryName,
      effectiveStartDate,
      currentDate,
    ]);

    final dailyTotals = <DateTime, double>{};
    for (final record in records) {
      final date = _parseStoredDate(record[MotionDbColumns.date]);
      if (date == null) continue;
      dailyTotals[_dateOnly(date)] = (record["total"] as num?)?.toDouble() ?? 0;
    }

    bool metTarget(DateTime date) {
      final total = dailyTotals[date] ?? 0.0;
      if (streakType == SubcategoryStreakType.targetTime) {
        return total >= targetMinutes;
      }
      return total > 0;
    }

    return _streakHistoryBuckets(
      range: range,
      firstDay: effectiveStartDay,
      today: currentDay,
    ).map((bucket) {
      var runningStreak = 0;
      var bestStreak = 0;
      final bucketStart = bucket.start.isBefore(effectiveStartDay)
          ? effectiveStartDay
          : bucket.start;
      final bucketEnd =
          bucket.end.isAfter(currentDay) ? currentDay : bucket.end;

      if (!bucketEnd.isBefore(bucketStart)) {
        for (var date = bucketStart;
            !date.isAfter(bucketEnd);
            date = date.add(const Duration(days: 1))) {
          if (metTarget(date)) {
            runningStreak++;
            if (runningStreak > bestStreak) bestStreak = runningStreak;
          } else {
            runningStreak = 0;
          }
        }
      }

      return SubcategoryStreakHistoryPoint(
        label: bucket.label,
        bestStreak: bestStreak,
      );
    }).toList();
  }

  Future<List<SubcategoryBestStreakRun>> getSubcategoryBestStreakRuns({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
    int limit = 9,
  }) async {
    final db = await database;
    final firstTrackedDate = await _getFirstTrackedDateForSubcategory(
      db,
      currentUser: currentUser,
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );
    final savedStartDate = _parseStoredDate(startDate);
    final currentDay =
        _dateOnly(_parseStoredDate(currentDate) ?? DateTime.now());
    final effectiveStartDay = _earliestDate(
      firstTrackedDate,
      savedStartDate,
    ) ?? currentDay;
    final effectiveStartDate = _formatIsoDate(effectiveStartDay);

    final records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date},
             COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.subcategoryName} = ?
        AND ${MotionDbColumns.mainCategoryName} = ?
        AND ${MotionDbColumns.date} BETWEEN ? AND ?
      GROUP BY ${MotionDbColumns.date}
      ORDER BY ${MotionDbColumns.date} ASC
    ''', [
      currentUser,
      subcategoryName,
      mainCategoryName,
      effectiveStartDate,
      currentDate,
    ]);

    final dailyTotals = <DateTime, double>{};
    for (final record in records) {
      final date = _parseStoredDate(record[MotionDbColumns.date]);
      if (date == null) continue;
      dailyTotals[_dateOnly(date)] = _readDouble(record["total"]);
    }

    bool metTarget(DateTime date) {
      final total = dailyTotals[date] ?? 0.0;
      if (streakType == SubcategoryStreakType.targetTime) {
        return total >= targetMinutes;
      }
      return total > 0;
    }

    final runs = <SubcategoryBestStreakRun>[];
    DateTime? runStart;
    DateTime? runEnd;
    var runningLength = 0;

    void closeRun() {
      if (runStart == null || runEnd == null || runningLength <= 0) return;
      runs.add(SubcategoryBestStreakRun(
        startDate: _formatIsoDate(runStart!),
        endDate: _formatIsoDate(runEnd!),
        streakLength: runningLength,
      ));
      runStart = null;
      runEnd = null;
      runningLength = 0;
    }

    for (var date = effectiveStartDay;
        !date.isAfter(currentDay);
        date = date.add(const Duration(days: 1))) {
      if (metTarget(date)) {
        runStart ??= date;
        runEnd = date;
        runningLength++;
      } else {
        closeRun();
      }
    }
    closeRun();

    runs.sort((a, b) {
      final streakComparison = b.streakLength.compareTo(a.streakLength);
      if (streakComparison != 0) return streakComparison;
      return b.endDate.compareTo(a.endDate);
    });
    return runs.take(limit).toList();
  }

  Future<List<SubcategoryStreakDay>> getSubcategoryStreakDays({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
  }) async {
    final db = await database;
    final firstTrackedDate = await _getFirstTrackedDateForSubcategory(
      db,
      currentUser: currentUser,
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );
    final savedStartDate = _parseStoredDate(startDate);
    final currentDay =
        _dateOnly(_parseStoredDate(currentDate) ?? DateTime.now());
    final effectiveStartDay = _earliestDate(
      firstTrackedDate,
      savedStartDate,
    ) ?? currentDay;
    final effectiveStartDate = _formatIsoDate(effectiveStartDay);

    final records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date},
             COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.subcategoryName} = ?
        AND ${MotionDbColumns.mainCategoryName} = ?
        AND ${MotionDbColumns.date} BETWEEN ? AND ?
      GROUP BY ${MotionDbColumns.date}
      ORDER BY ${MotionDbColumns.date} ASC
    ''', [
      currentUser,
      subcategoryName,
      mainCategoryName,
      effectiveStartDate,
      currentDate,
    ]);

    final dailyTotals = <DateTime, double>{};
    for (final record in records) {
      final date = _parseStoredDate(record[MotionDbColumns.date]);
      if (date == null) continue;
      dailyTotals[_dateOnly(date)] = _readDouble(record["total"]);
    }

    bool metTarget(DateTime date) {
      final total = dailyTotals[date] ?? 0.0;
      if (streakType == SubcategoryStreakType.targetTime) {
        return total >= targetMinutes;
      }
      return total > 0;
    }

    return [
      for (var date = effectiveStartDay;
          !date.isAfter(currentDay);
          date = date.add(const Duration(days: 1)))
        SubcategoryStreakDay(
          date: _formatIsoDate(date),
          metTarget: metTarget(date),
          minutesTracked: dailyTotals[date] ?? 0.0,
        ),
    ];
  }

  Future<DateTime?> _getFirstTrackedDateForSubcategory(
    DatabaseExecutor db, {
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
  }) async {
    final records = await db.rawQuery('''
      SELECT ${MotionDbColumns.date}
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
        AND ${MotionDbColumns.subcategoryName} = ?
        AND ${MotionDbColumns.mainCategoryName} = ?
        AND ${MotionDbColumns.timeSpent} > 0
    ''', [
      currentUser,
      subcategoryName,
      mainCategoryName,
    ]);

    final dates = records
        .map((record) => _parseStoredDate(record[MotionDbColumns.date]))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  List<_StreakHistoryBucket> _streakHistoryBuckets({
    required SubcategoryStreakHistoryRange range,
    required DateTime firstDay,
    required DateTime today,
  }) {
    switch (range) {
      case SubcategoryStreakHistoryRange.week:
        return _weeklyStreakHistoryBuckets(today);
      case SubcategoryStreakHistoryRange.month:
        return _monthlyStreakHistoryBuckets(today);
      case SubcategoryStreakHistoryRange.year:
        return _yearlyStreakHistoryBuckets(firstDay, today);
    }
  }

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
          ($_totalXpExpression) AS totalXp,
          COUNT(DISTINCT ${MotionDbColumns.date}) AS xpDays,
          ROUND(
            COALESCE(($_totalXpExpression), 0) * 100.0 /
            NULLIF(COUNT(DISTINCT ${MotionDbColumns.date}) * ${MotionXpPolicy.maxDailyXp}, 0),
            2
          ) AS efficiencyScore
        FROM ${MotionDbTables.experiencePoints}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
      ''', [currentUser, firstDay, lastDay]);

      final bestDay = await db.rawQuery('''
        SELECT ${MotionDbColumns.date}, ($_totalXpExpression) AS totalXp
        FROM ${MotionDbTables.experiencePoints}
        WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          AND ${MotionDbColumns.date} BETWEEN ? AND ?
        GROUP BY ${MotionDbColumns.date}
        ORDER BY totalXp DESC, ${MotionDbColumns.date} DESC
        LIMIT 1
      ''', [currentUser, firstDay, lastDay]);

      final lowestDay = await db.rawQuery('''
        SELECT ${MotionDbColumns.date}, ($_totalXpExpression) AS totalXp
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

        final totalMinutes = _readDouble(row['totalTimeSpent']).floor();
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

  List<_StreakHistoryBucket> _weeklyStreakHistoryBuckets(DateTime today) {
    final yearStart = DateTime(today.year, 1, 1);
    final weekCount = today.difference(yearStart).inDays ~/ 7 + 1;

    return List.generate(weekCount, (index) {
      final start = yearStart.add(Duration(days: index * 7));
      final end = start.add(const Duration(days: 6));
      return _StreakHistoryBucket(
        label: 'W${index + 1}',
        start: _dateOnly(start),
        end: _dateOnly(end),
      );
    });
  }

  List<_StreakHistoryBucket> _monthlyStreakHistoryBuckets(DateTime today) {
    return List.generate(today.month, (index) {
      final month = index + 1;
      final start = DateTime(today.year, month, 1);
      final end = DateTime(today.year, month + 1, 0);
      return _StreakHistoryBucket(
        label: _shortMonthName(month),
        start: start,
        end: end,
      );
    });
  }

  List<_StreakHistoryBucket> _yearlyStreakHistoryBuckets(
    DateTime firstDay,
    DateTime today,
  ) {
    final startYear = firstDay.year;
    final endYear = today.year;

    return List.generate(endYear - startYear + 1, (index) {
      final year = startYear + index;
      return _StreakHistoryBucket(
        label: year.toString(),
        start: DateTime(year, 1, 1),
        end: DateTime(year, 12, 31),
      );
    });
  }

  static String _shortMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return monthNames[month - 1];
  }

  static DateTime? _earliestDate(DateTime? first, DateTime? second) {
    if (first == null) return second == null ? null : _dateOnly(second);
    if (second == null) return _dateOnly(first);

    final firstDate = _dateOnly(first);
    final secondDate = _dateOnly(second);
    return firstDate.isBefore(secondDate) ? firstDate : secondDate;
  }

  static String _formatIsoDate(DateTime date) {
    final normalized = _dateOnly(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime? _parseStoredDate(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;

    final isoDate = DateTime.tryParse(text);
    if (isoDate != null) return _dateOnly(isoDate);

    final slashParts = text.split('/');
    if (slashParts.length != 3) return null;

    final first = int.tryParse(slashParts[0]);
    final second = int.tryParse(slashParts[1]);
    final year = int.tryParse(slashParts[2]);
    if (first == null || second == null || year == null) return null;

    final month = first > 12 ? second : first;
    final day = first > 12 ? first : second;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    return DateTime(year, month, day);
  }

  static int _inclusiveDaysBetween(DateTime startDate, DateTime endDate) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  static double _readDouble(Object? value) {
    final parsed = value;
    if (parsed is int) return parsed.toDouble();
    if (parsed is double) return parsed;
    return double.tryParse(parsed?.toString() ?? '') ?? 0.0;
  }

  // calculates and returns the total time spent on a particular subcategory
  Future<double> getTotalTimeSpentPerSubcategory(
      String currentDate, String currentUser, String subcategoryName) async {
    try {
      final db = await database;

      // returns total based on the current date, user, and subcategory name
      final result = await db.rawQuery('''
    SELECT COALESCE(SUM(timeSpent),0) as total_time_spent
    FROM subcategory
    WHERE date = ? AND currentLoggedInUser = ? AND subcategoryName = ?
  ''', [currentDate, currentUser, subcategoryName]);

      if (result.isNotEmpty) {
        // first row and column
        final total = result.first['total_time_spent'];
        if (total is double) {
          return total;
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

  // get the least and most tracked subcategory
  // the subcategory name and total time spent
  // during the defined period of time
  Future<List<Map<String, dynamic>>> getMostAndLeastTrackedSubcategory(
      {required String firstDay,
      required String lastDay,
      required String currentUser,
      required bool isMost}) async {
    try {
      final db = await database;

      //currentUserget
      final resultMLTS = isMost ? await db.rawQuery('''
      SELECT subcategoryName AS result_tracked_category,
      COALESCE(SUM(timeSpent), 0) AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      AND mainCategoryName != 'Sleep'
      GROUP BY result_tracked_category
      ORDER BY time_spent DESC
      LIMIT 1;
      ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
      SELECT subcategoryName AS result_tracked_category,
      COALESCE(SUM(timeSpent), 0) AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      AND mainCategoryName != 'Sleep'
      GROUP BY result_tracked_category
      ORDER BY time_spent ASC
      LIMIT 1;
        ''', [currentUser, firstDay, lastDay]);

      return resultMLTS;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // get the subcetegory totals for a specific date
  Future<List<Map<String, dynamic>>> getSubcategoryTotalsForSpecificDate(
      {required String selectedDate, required String currentUser}) async {
    try {
      final db = await database;

      final resultSTFSD = await db.rawQuery('''
      SELECT date, subcategoryName, ROUND(COALESCE(SUM(timeSpent), 0),2) AS totalTimeSpent
      FROM subcategory
      WHERE date = ? AND currentLoggedInUser = ?
      GROUP BY subcategoryName
      ORDER BY totalTimeSpent DESC
      ''', [selectedDate, currentUser]);

      return resultSTFSD;
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // updates existing subcategory categories rows
  Future<void> updateSubcategory(Subcategories subcategory) async {
    try {
      final db = await database;
      await db.update(MotionDbTables.subcategory, subcategory.toMap(),
          where: '${MotionDbColumns.id} = ?', whereArgs: [subcategory.id]);

      logger.i("Update successfull");
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

  // deletes subcategory rows
  Future<void> deleteSubcategory(int id) async {
    try {
      final db = await database;
      await db.delete(MotionDbTables.subcategory,
          where: '${MotionDbColumns.id} = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      logDatabaseError("TrackerDatabaseHelper", e, stackTrace);
    }
  }

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
          SELECT ROUND((($_totalXpExpression) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2) AS efficiencyScore
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
            (($_totalXpExpression) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2
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
      SELECT ROUND((($_totalXpExpression) / COUNT(DISTINCT date)) * 100.0 / ${MotionXpPolicy.maxDailyXp}, 2) AS efficiencyScore
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
        SELECT ($_totalXpExpression) AS entireTotalXP
        FROM experience_points
        WHERE currentLoggedInUser = ?
        """, [currentUser]) : await db.rawQuery("""
        SELECT ($_totalXpExpression) AS entireTotalXP
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
      SELECT ($_totalXpExpression) AS totalXP
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
      final totalMinutes = _readDouble(row['totalTimeSpent']).floor();
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
                    ($_totalXpExpression) AS totalMostXP
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
                  ($_totalXpExpression) AS totalLeastXP
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
        SELECT date, ($_totalXpExpression) AS totalMostXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date
      ) AS totalMostXP
        """, [currentUser, firstDay, lastDay]) : await db.rawQuery("""
      SELECT COALESCE(date, 'TBD') AS date, COALESCE(MIN(totalLeastXP),0) AS least_productive
      FROM (
        SELECT date, ($_totalXpExpression) AS totalLeastXP
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

  /// Back-fills experience_points for every date the user already has in main_category.
  ///
  /// 1) Inserts a zeroed row for each date (if it doesn’t exist).
  /// 2) Runs the same UPDATE logic your trigger uses to compute XP from subcategory.
  Future<void> backfillXpForExistingUser() async {
    final db = await database;
    const currentUser = 'hhANBj74wiclvfuDLGfuDlFZgJ62';

    // 1) Insert any missing (date,user) rows with zero XP
    await db.execute('''
      INSERT OR IGNORE INTO experience_points
        (date, currentLoggedInUser, educationXP, workXP, skillsXP, sdXP, sleepXP, accountabilityBonusXP)
      SELECT date, currentLoggedInUser, 0, 0, 0, 0, 0, 0
        FROM main_category
      WHERE currentLoggedInUser = ?;
    ''', [currentUser]);

    // 2) Recompute XP per row exactly as your trigger does
    await db.execute('''
      UPDATE experience_points
        SET
          educationXP = (
            SELECT CASE
              WHEN CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER) > 20 THEN 20
              ELSE CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER)
            END
            FROM subcategory
            WHERE mainCategoryName   = 'Education'
              AND date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          ),
          workXP = (
            SELECT CASE
              WHEN CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER) > 25 THEN 25
              ELSE CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER)
            END
            FROM subcategory
            WHERE mainCategoryName   = 'Work'
              AND date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          ),
          skillsXP = (
            SELECT CASE
              WHEN CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER) > 20 THEN 20
              ELSE CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER)
            END
            FROM subcategory
            WHERE mainCategoryName   = 'Skills'
              AND date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          ),
          sdXP = (
            SELECT CASE
              WHEN CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER) > 20 THEN 20
              ELSE CAST(COALESCE(SUM(timeSpent), 0) / 12 AS INTEGER)
            END
            FROM subcategory
            WHERE mainCategoryName   = 'Self Development'
              AND date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          ),
          sleepXP = (
            SELECT CASE
              WHEN COALESCE(SUM(timeSpent),0) < 300 THEN 0
              WHEN COALESCE(SUM(timeSpent),0) < 360 THEN 8
              WHEN COALESCE(SUM(timeSpent),0) < 420 THEN 15
              WHEN COALESCE(SUM(timeSpent),0) <= 540 THEN 25
              WHEN COALESCE(SUM(timeSpent),0) <= 600 THEN 15
              ELSE 5
            END
            FROM subcategory
            WHERE mainCategoryName   = 'Sleep'
              AND date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          ),
          accountabilityBonusXP = (
            SELECT CASE
              WHEN COALESCE(SUM(timeSpent),0) < 480 THEN 0
              WHEN COALESCE(SUM(timeSpent),0) < 600 THEN 1
              WHEN COALESCE(SUM(timeSpent),0) < 720 THEN 2
              WHEN COALESCE(SUM(timeSpent),0) < 840 THEN 3
              WHEN COALESCE(SUM(timeSpent),0) < 960 THEN 4
              ELSE 5
            END
            FROM subcategory
            WHERE date               = experience_points.date
              AND currentLoggedInUser= experience_points.currentLoggedInUser
          )
      WHERE currentLoggedInUser = ?;
    ''', [currentUser]);

    logger.i('🔄 Back-filled experience_points for all existing dates.');
  }

  Future<void> deleteSubcategoriesByDate(String date) async {
    final db = await database;

    try {
      await db.delete(
        MotionDbTables.subcategory,
        where: "${MotionDbColumns.date} = ?",
        whereArgs: [date],
      );
      debugPrint("✅ Subcategories with date $date deleted successfully");
    } catch (e, stackTrace) {
      logDatabaseError(
          "TrackerDatabaseHelper.deleteSubcategoriesByDate", e, stackTrace);
    }
  }

  // Delete the entire database
  // Future<void> deleteDb() async {
  //   try {
  //     final dbPath = await getDatabasesPath();
  //     final path = join(dbPath, "tracker.db");

  //     await deleteDatabase(path);
  //     _database = null; // Reset the database instance

  //     logger.i("Database has been deleted");
  //   } catch (e) {
  //     logger.e("Error: $e");
  //   }
  // }
}

class _StreakHistoryBucket {
  final String label;
  final DateTime start;
  final DateTime end;

  const _StreakHistoryBucket({
    required this.label,
    required this.start,
    required this.end,
  });
}
