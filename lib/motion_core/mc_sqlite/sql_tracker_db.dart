import 'dart:async';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// tracker database that store two tables
// subcategory table and main category table
// subcategory table tracks subcategories
// main category table tracks the aggregated subcategories
class TrackerDatabaseHelper {
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

    return await openDatabase(path,
        version: 9, onCreate: _createDatabase, onUpgrade: _onUpgradeDatabase);
  }

  void _onUpgradeDatabase(Database db, int oldVersion, int newVersion) async {
    logger.i("Database _onUpgradeDatabase function called");
    if (oldVersion < 9) {
      //   await db.execute('DROP TABLE IF EXISTS experience_points');
      //   // Upgrade the database schema here
      //   await db.execute('''
      //   CREATE TABLE experience_points(
      //     date TEXT,
      //     educationXP INTEGER,
      //     skillsXP INTEGER,
      //     sdXP INTEGER,
      //     sleepXP INTEGER,
      //     currentLoggedInUser TEXT,
      //     PRIMARY KEY (date, currentLoggedInUser),
      //     FOREIGN KEY (date, currentLoggedInUser)
      //     REFERENCES main_category(date, currentLoggedInUser)
      //   )
      // ''');

      // Trigger: update_experience_points_after_insert
      // Purpose: Updates the experience_points table after a new entry is
      //          inserted into the subcategory table.
      // Functionality:
      // -- 1. Triggered after an INSERT operation on the subcategory table.
      // -- 2. For each main category(Education, Skills, Personal Growth, Sleep)
      //       it sums the timeSpent from the subcategory table.
      // -- 3. Applies a CASE statement for each category to determine the
      //       appropriate experience points based on the total timeSpent.
      // -- 4. Updates the experience_points table with the calculated
      //       experience points for each category.
      // -- 5. Ensures the update is for the specific date and user matching
      //       the new entry in the subcategory table.
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS update_experience_points
        AFTER INSERT ON subcategory
        BEGIN
          UPDATE experience_points
          SET 
            educationXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) < 60 THEN 5
                  WHEN SUM(timeSpent) < 120 THEN 10
                  WHEN SUM(timeSpent) < 180 THEN 15
                  WHEN SUM(timeSpent) < 240 THEN 20
                  WHEN SUM(timeSpent) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Education' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),

            skillsXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) >= 15 AND SUM(timeSpent) < 60 THEN 5
                  WHEN SUM(timeSpent) >= 60 AND SUM(timeSpent) < 120 THEN 10
                  WHEN SUM(timeSpent) >= 120 AND SUM(timeSpent) < 180 THEN 15
                  WHEN SUM(timeSpent) >= 180 AND SUM(timeSpent) < 240 THEN 20
                  WHEN SUM(timeSpent) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),


            sdXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) >= 15 AND SUM(timeSpent) < 60 THEN 10
                  WHEN SUM(timeSpent) >= 60 AND SUM(timeSpent) < 120 THEN 15
                  WHEN SUM(timeSpent) >= 120 AND SUM(timeSpent) < 180 THEN 20
                  WHEN SUM(timeSpent) >= 180 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Self Development' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),


            sleepXP = (SELECT 
                CASE
                    WHEN SUM(timeSpent) < 300 THEN 0
                    WHEN SUM(timeSpent) >= 300 AND SUM(timeSpent) < 360 THEN 5
                    WHEN SUM(timeSpent) >= 360 AND SUM(timeSpent) < 420 THEN 10
                    WHEN SUM(timeSpent) >= 420 AND SUM(timeSpent) < 480 THEN 20
                    WHEN SUM(timeSpent) >= 480 THEN 25
                    ELSE 0 
                END
              FROM subcategory 
              WHERE mainCategoryName = 'Sleep' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser)
            WHERE date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser;
          END;  
        ''');

      // trigger to update the experience point table if a deletion is made in the subcategory table
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS update_experience_points_after_delete
        AFTER DELETE ON subcategory
        BEGIN
          UPDATE experience_points
          SET 
            educationXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) < 60 THEN 5
                  WHEN SUM(timeSpent) < 120 THEN 10
                  WHEN SUM(timeSpent) < 180 THEN 15
                  WHEN SUM(timeSpent) < 240 THEN 20
                  WHEN SUM(timeSpent) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Education' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            skillsXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) >= 15 AND SUM(timeSpent) < 60 THEN 5
                  WHEN SUM(timeSpent) >= 60 AND SUM(timeSpent) < 120 THEN 10
                  WHEN SUM(timeSpent) >= 120 AND SUM(timeSpent) < 180 THEN 15
                  WHEN SUM(timeSpent) >= 180 AND SUM(timeSpent) < 240 THEN 20
                  WHEN SUM(timeSpent) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            sdXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 15 THEN 0
                  WHEN SUM(timeSpent) >= 15 AND SUM(timeSpent) < 60 THEN 10
                  WHEN SUM(timeSpent) >= 60 AND SUM(timeSpent) < 120 THEN 15
                  WHEN SUM(timeSpent) >= 120 AND SUM(timeSpent) < 180 THEN 20
                  WHEN SUM(timeSpent) >= 180 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Self Development' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            sleepXP = (SELECT 
              CASE
                  WHEN SUM(timeSpent) < 300 THEN 0
                  WHEN SUM(timeSpent) >= 300 AND SUM(timeSpent) < 360 THEN 5
                  WHEN SUM(timeSpent) >= 360 AND SUM(timeSpent) < 420 THEN 10
                  WHEN SUM(timeSpent) >= 420 AND SUM(timeSpent) < 480 THEN 20
                  WHEN SUM(timeSpent) >= 480 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Sleep' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser)
          WHERE date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser;
        END;
        ''');

      logger.i("Database _onUpgradeDatabase COMPLETED");
    }
  }

  void _createDatabase(Database db, int version) async {
    // creation of the main_category table
    await db.execute('''
      CREATE TABLE main_category(
        date TEXT,
        education REAL,
        skills REAL,
        entertainment REAL,
        selfDevelopment REAL,
        sleep REAL,
        currentLoggedInUser TEXT,
        PRIMARY KEY (date, currentLoggedInUser)
      )
    ''');
    // creation of the subcategory table
    await db.execute('''
    CREATE TABLE subcategory(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
      date TEXT,
      mainCategoryName TEXT,
      subcategoryName TEXT,
      timeRecorded TEXT,
      timeSpent REAL,
      currentLoggedInUser TEXT,
      FOREIGN KEY (date, currentLoggedInUser) 
      REFERENCES main_category(date, 	currentLoggedInUser)
    )
  ''');
    // a trigger to update the main_category table
    // calculate the sums from the subcategory table
    // and updates the main_category table depending on the aggregation
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_main_category
      AFTER INSERT ON subcategory
      BEGIN
        UPDATE main_category
        SET education = (SELECT SUM(timeSpent) FROM subcategory WHERE 
        mainCategoryName = 'Education' AND date = NEW.date AND 
        currentLoggedInUser = NEW.currentLoggedInUser),
            skills = (SELECT SUM(timeSpent) FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = NEW.date AND 
            currentLoggedInUser = NEW.currentLoggedInUser),
            entertainment = (SELECT SUM(timeSpent) FROM subcategory 
            WHERE mainCategoryName = 'Entertainment' AND date = NEW.date 
            AND currentLoggedInUser = NEW.currentLoggedInUser),
            selfDevelopment = (SELECT SUM(timeSpent) FROM subcategory WHERE 
            mainCategoryName = 'Self Development' AND date = NEW.date AND 
            currentLoggedInUser = NEW.currentLoggedInUser),
            sleep = (SELECT SUM(timeSpent) FROM subcategory WHERE 
            mainCategoryName = 'Sleep' AND date = NEW.date AND 
            currentLoggedInUser = NEW.currentLoggedInUser)
        WHERE date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser;
      END;
      ''');

    // a trigger to update the main category table
    // when an entry in the subcategory table is deleted
    await db.execute('''
        CREATE TRIGGER IF NOT EXISTS update_main_category_after_delete
        AFTER DELETE ON subcategory
        BEGIN
          UPDATE main_category
          SET education = (SELECT SUM(timeSpent) FROM subcategory WHERE 
          mainCategoryName = 'Education' AND date = OLD.date AND 
          currentLoggedInUser = OLD.currentLoggedInUser),
              skills = (SELECT SUM(timeSpent) FROM subcategory WHERE 
              mainCategoryName = 'Skills' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              entertainment = (SELECT SUM(timeSpent) FROM subcategory WHERE 
              mainCategoryName = 'Entertainment' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              selfDevelopment = (SELECT SUM(timeSpent) FROM subcategory WHERE 
              mainCategoryName = 'Self Development' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              sleep = (SELECT SUM(timeSpent) FROM subcategory WHERE 
              mainCategoryName = 'Sleep' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser)
          WHERE date = OLD.date AND 
          currentLoggedInUser = OLD.currentLoggedInUser;
        END;
        ''');
  }

// CRUD operations for MainCategory

  // insert new rows into the main category table
  Future<void> insertMainCategory(MainCategory mainCategory) async {
    try {
      final db = await database;
      await db.insert('main_category', mainCategory.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // get the totals for all 5 main categories
  Future<List<Map<String, dynamic>>> getAllMainCategoryTotals(
      {required String currentUser}) async {
    try {
      final db = await database;

      final resultAMCT = await db.rawQuery("""
            SELECT 
                CAST(ROUND(COALESCE(sum(education)/60, 0), 2) AS VARCHAR) AS "educationHours",
                CAST(ROUND(sum(education)/1440, 2) AS VARCHAR) AS "educationDays",
                CAST(ROUND(AVG(education)/60, 2) AS VARCHAR) AS "educationAverage",
                CAST(ROUND(COALESCE(sum(skills)/60, 0), 2) AS VARCHAR) AS "skillHours",
                CAST(ROUND(sum(skills)/1440, 2) AS VARCHAR) AS "skillDays",
                CAST(ROUND(AVG(skills)/60, 2) AS VARCHAR) AS "skillAverage",
                CAST(ROUND(COALESCE(sum(entertainment)/60, 0), 2) AS VARCHAR) AS "entertainmentHours",
                CAST(ROUND(sum(entertainment)/1440, 2) AS VARCHAR) AS "entertainmentDays",
                CAST(ROUND(AVG(entertainment)/60, 2) AS VARCHAR) AS "entertainmentAverage",
                CAST(ROUND(COALESCE(sum(selfDevelopment)/60, 0), 2) AS VARCHAR) AS "pgHours",
                CAST(ROUND(sum(selfDevelopment)/1440, 2) AS VARCHAR) AS "pgDays",
                CAST(ROUND(AVG(selfDevelopment)/60, 2) AS VARCHAR) AS "pgAverage",
                CAST(ROUND(COALESCE(sum(sleep)/60, 0), 2) AS VARCHAR) AS "sleepHours",
                CAST(ROUND(sum(sleep)/1440, 2) AS VARCHAR) AS "sleepDays",
                CAST(ROUND(AVG(sleep)/60, 2) AS VARCHAR) AS "sleepAverage"
            FROM main_category
            WHERE currentLoggedInUser = ?

          """, [currentUser]);

      return resultAMCT;
    } catch (e) {
      logger.e("Get All Main Category Total Error: $e");
      return [];
    }
  }

  // count the number of days in the main_category table
  Future<int> getNumberOfDays(
      {required String currentUser,
      bool getAllDays = true,
      String currentYear = ""}) async {
    try {
      final db = await database;

      // number of days
      final resultGNOD = getAllDays ? await db.rawQuery('''
        SELECT COUNT(DISTINCT date) AS NumberOfDays
        FROM main_category
        WHERE currentLoggedInUser = ?
      ''', [currentUser]) : await db.rawQuery('''
        SELECT COUNT(DISTINCT date) AS NumberOfDays
        FROM main_category
        WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
      ''', [currentUser, currentYear]);

      // check if the result is empty
      if (resultGNOD.isNotEmpty) {
        final numberOfDays = resultGNOD.first["NumberOfDays"];

        if (numberOfDays is int) {
          return numberOfDays;
        }
      }
    } catch (e) {
      logger.e("Error querying the database: $e");
    }

    return 0; // Return 0 if there's an error or no result.
  }

  // count the number of days in the main_category table for the current year
  Future<int> getNumberOfDaysInYear(
      {required String currentUser, required String currentYear}) async {
    try {
      final db = await database;

      // number of days
      final resultGNODY = await db.rawQuery('''
      SELECT COUNT(date) AS NumberOfDays
      FROM main_category
      WHERE currentLoggedInUser = ? AND str("YYYY", date) = ?
    ''', [currentUser, currentYear]);

      // check if the result is empty
      if (resultGNODY.isNotEmpty) {
        final numberOfDays = resultGNODY.first["NumberOfDays"];

        if (numberOfDays is int) {
          return numberOfDays;
        }
      }
    } catch (e) {
      logger.e("Error querying the database: $e");
    }

    return 0; // Return 0 if there's an error or no result.
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
    } catch (e) {
      logger.e("Error: $e");
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
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) 
        + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) + 
        COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0)) 
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ?
        ''', [currentUser]) : await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) 
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
    } catch (e) {
      // Handle any database query errors, e.g., log the error
      //and return an empty list or throw an exception.
      logger.e('Error in getMonthTotalAndAverage: $e');
      rethrow;
    }
  }

  // gets the entire total for the timeSpent column of the main_category table
  // for the current year
  Future<double> getEntireYearTotalMainCategoryTable(
      String currentUser, bool isUnaccounted, String currentYear) async {
    try {
      final db = await database;

      final query = isUnaccounted
          ? '''
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) 
        + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) + 
        COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0)) 
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
        '''
          : '''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) 
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0) 
        + COALESCE(SUM(sleep), 0) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
        ''';

      final resultETMCT = await db.rawQuery(query, [currentUser, currentYear]);

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
    } catch (e) {
      logger.e('Error in getMonthTotalAndAverage: $e');
      rethrow;
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
        SELECT  (COALESCE(SUM(education), 0.0) + COALESCE(SUM(skills), 0.0)
                + COALESCE(SUM(entertainment), 0.0) + COALESCE(SUM(selfDevelopment), 0.0)
                + COALESCE(SUM(sleep), 0.0))/60 AS Accounted,
                (((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0.0)
                + COALESCE(SUM(skills), 0.0) + COALESCE(SUM(entertainment), 0.0)
                + COALESCE(SUM(selfDevelopment), 0.0) + COALESCE(SUM(sleep), 0.0)))/60
                AS Unaccounted,
                strftime('%Y', date) AS Year
        FROM main_category
        WHERE currentLoggedInUser = ?
        GROUP BY Year
        ''', [currentUser]);

      return resultAAUBBY;
    } catch (e) {
      logger.e("Error: $e");
    }
    return [];
  }

  // gets the accounted and unaccounted totals for each month during a
  // particular year
  Future<List<Map<String, dynamic>>> getMonthDistibutionOfAccountedUnaccounted(
      {required String currentUser, required String year}) async {
    try {
      final db = await database;

      final resultMDAUA = await db.rawQuery('''
          SELECT  strftime('%m', date) AS Month, 
                (COALESCE(SUM(education), 0) + 
                COALESCE(SUM(skills), 0)
              + COALESCE(SUM(entertainment), 0) + 
              COALESCE(SUM(selfDevelopment), 0)
              + COALESCE(SUM(sleep), 0))/60 AS Accounted,
              (((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0)
                + COALESCE(SUM(skills), 0) + 
                COALESCE(SUM(entertainment), 0)
          + COALESCE(SUM(selfDevelopment), 0) + 
          COALESCE(SUM(sleep), 0)))/60 AS Unaccounted
      FROM main_category
      WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
      GROUP BY Month
        ''', [currentUser, year]);

      return resultMDAUA;
    } catch (e) {
      logger.e("Error: $e");
      return [];
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
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) 
        + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) 
        + COALESCE(SUM(selfDevelopment), 0) + COALESCE(SUM(sleep), 0)) 
        AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
            ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) 
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
    } catch (e) {
      logger.e("Error: $e");
      rethrow;
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
            (COALESCE(education, 0) + COALESCE(skills, 0) + 
            COALESCE(entertainment, 0) + COALESCE(selfDevelopment, 0) + 
            COALESCE(sleep, 0))/60 AS Accounted, 
            24 - (COALESCE(education, 0) + COALESCE(skills, 0) + 
            COALESCE(entertainment, 0) + COALESCE(selfDevelopment, 0) + 
            COALESCE(sleep, 0))/60 AS Unaccounted
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        ORDER BY date;
        ''', [currentUser, firstDatePeriod, lastDatePeriod]);

      return resultAWAAD;
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // get a table for both accounted and unaccounted values
  Future<List<Map<String, dynamic>>> getMonthAccountUnaccountTable(
      String currentUser, firstDay, lastDay) async {
    try {
      final db = await database;

      final resultMAT = await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0)
        + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
        + COALESCE(SUM(sleep), 0) AS Accounted, ((COUNT(date) * 24)*60)
         - (COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) 
         + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(selfDevelopment), 0)
         + COALESCE(SUM(sleep), 0)) AS Unaccounted
        FROM main_category
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        ''', [currentUser, firstDay, lastDay]);

      return resultMAT;
    } catch (e) {
      logger.e("Error: $e");
      return [];
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
      SELECT mainCategoryName AS result_tracked_category, SUM(timeSpent) 
      AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? AND 
      mainCategoryName != 'Sleep'
      GROUP BY mainCategoryName
      ORDER BY time_spent DESC
      LIMIT 1
      ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
      SELECT mainCategoryName AS result_tracked_category, SUM(timeSpent) 
      AS time_spent
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY mainCategoryName
      ORDER BY time_spent ASC
      LIMIT 1
          ''', [currentUser, firstDay, lastDay]);

      return resultMLTMC;
    } catch (e) {
      logger.e("Error: $e");
      return [];
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
        SELECT mainCategoryName, SUM(timeSpent)/60 AS totalTimeSpent
        FROM subcategory
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY mainCategoryName
        ''', [currentUser, firstDay, lastDay]);

      return resultMTTSSD;
    } catch (e) {
      // if there is an error, an empty list is returned
      // and the error is logged to the console
      logger.i("Error: $e");
      return [];
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
        SELECT mainCategoryName, SUM(timeSpent)/60 AS totalTimeSpent
        FROM subcategory
        WHERE currentLoggedInUser = ?
        GROUP BY mainCategoryName
        ''', [currentUser]);

      return resultEMTTS;
    } catch (e) {
      // if there is an error, an empty list is returned
      // and the error is logged to the console
      logger.i("Error: $e");
      return [];
    }
  }

  // get yearly totals for all the main categories
  Future<List<Map<String, dynamic>>> getYearlyTotalsForAllMainCatgories(
      {required String currentUser, required String year}) async {
    try {
      final db = await database;

      final resultYTFAMC = await db.rawQuery('''
        SELECT
          strftime('%m', date) AS Month,
          ROUND(COALESCE(SUM(education) / 60.0, 0), 2) AS education,
          ROUND(COALESCE(SUM(skills) / 60.0, 0), 2) AS skills,
          ROUND(COALESCE(SUM(entertainment) / 60.0, 0), 2) AS entertainment,
          ROUND(COALESCE(SUM(selfDevelopment) / 60.0, 0), 2) AS selfDevelopment,
          ROUND(COALESCE(SUM(sleep) / 60.0, 0), 2) AS sleep
        FROM main_category
        WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
        GROUP BY Month;
        ''', [currentUser, year]);

      return resultYTFAMC;
    } catch (e) {
      logger.i("Error: $e");

      return [];
    }
  }

  // get the daily accounted and intensity score for all main categories
  Future<List<Map<String, dynamic>>> getDailyAccountedAndIntensities(
      {required String currentUser}) async {
    try {
      final db = await database;

      final resultDAAI = await db.rawQuery('''
            SELECT date, 
                  ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                          COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                          COALESCE(sleep, 0)) / 60, 2) AS accounted,
                  CASE
                      WHEN ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                                  COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                                  COALESCE(sleep, 0)) / 60, 2) <= 0 THEN 0
                      WHEN ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                                  COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                                  COALESCE(sleep, 0)) / 60, 2) <= 5 THEN 5
                      WHEN ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                                  COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                                  COALESCE(sleep, 0)) / 60, 2) <= 10 THEN 10
                      WHEN ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                                  COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                                  COALESCE(sleep, 0)) / 60, 2) <= 15 THEN 15
                      WHEN ROUND((COALESCE(education, 0) + COALESCE(skills, 0) + 
                                  COALESCE(selfDevelopment, 0) + COALESCE(entertainment, 0) +
                                  COALESCE(sleep, 0)) / 60, 2) <= 20 THEN 20
                      ELSE 25
                  END AS intensity
            FROM main_category
            WHERE currentLoggedInUser = ?

        ''', [currentUser]);

      return resultDAAI;
    } catch (e) {
      logger.e("Daily Accounted and Intensity error: $e");
      return [];
    }
  }

  // updates existing main categories rows
  Future<void> updateMainCategory(MainCategory mainCategory) async {
    try {
      final db = await database;
      await db.update('main_category', mainCategory.toMap(),
          where: 'date = ?', whereArgs: [mainCategory.date]);
    } catch (e) {
      logger.e("Error: $e");
      throw "Error: $e";
    }
  }

  // delete rows in the main category table
  Future<void> deleteMainCategory(String date) async {
    try {
      final db = await database;
      await db.delete('main_category', where: 'date = ?', whereArgs: [date]);
    } catch (e) {
      logger.e("Error: $e");
      throw "Error: $e";
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
  Future<void> insertSubcategory(Subcategories subcategory) async {
    try {
      final db = await database;
      await db.insert('subcategory', subcategory.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
      throw "Error: $e";
    }
  }

  // get all data in the subcategories table
  Future<List<Subcategories>> getAllSubcategories() async {
    try {
      final db = await database;

      final allSubs = await db.query("subcategory");

      return allSubs.map((map) => Subcategories.fromMap(map)).toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // gets all the subcategories depending on the current date
  Future<List<Subcategories>> getCurrentDateSubcategory(
      String currentDate, String currentUser, String subcategoryName) async {
    try {
      final db = await database;

      final specificSubcategories = await db.query("subcategory",
          where: "date = ? AND currentLoggedInUser = ? AND subcategoryName = ?",
          whereArgs: [currentDate, currentUser, subcategoryName]);

      return specificSubcategories
          .map((map) => Subcategories.fromMap(map))
          .toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // calculate and return the total time spent on
  // all the categories for a particular date
  Future<double> getTotalTimeForCurrentDate(
      String currentDate, String currentUser) async {
    try {
      final db = await database;

      final result = await db.rawQuery('''
    SELECT SUM(timeSpent) as total
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
    } catch (e) {
      logger.e("Error: $e");
      rethrow;
    }
  }

  // gets the total time spent on all subcategories for an entire month
  Future<double> getMonthTotalTimeSpent(
      String currentUser, String startingDate, String endingDate) async {
    try {
      final db = await database;

      final resultMTTS = await db.rawQuery('''
      SELECT SUM(timeSpent) as total
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
    } catch (e) {
      // Handle the exception, e.g., log it or rethrow it for debugging.
      logger.e('Error in getMonthTotalTimeSpent: $e');
      return 0.0;
    }
  }

  /// Calculates total and average time spent on subcategories or main categories for a user.
  /// It sums time spent per day for each category, then averages these sums over the specified date range.
  /// [currentUser]: User ID for data retrieval.
  /// [startingDate], [endingDate]: Date range for query.
  /// [isSubcategory]: Determines if data is fetched for subcategories (true) or main categories (false).
  /// Returns a list of maps with category names, total and average times.
  Future<List<Map<String, dynamic>>> getMonthTotalAndAverage(String currentUser,
      String startingDate, String endingDate, bool isSubcategory) async {
    final db = await database;

    try {
      final resultMTA = isSubcategory ? await db.rawQuery('''
    SELECT subcategoryName, SUM(dailyTotal) AS total, 
    AVG(dailyTotal) AS average
    FROM (
      SELECT date, subcategoryName, SUM(timeSpent) AS dailyTotal
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY date, subcategoryName
    )
    GROUP BY subcategoryName
    ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate]) : await db.rawQuery('''
    SELECT mainCategoryName, SUM(dailyTotal) AS total, 
    AVG(dailyTotal) AS average
    FROM (
      SELECT date, mainCategoryName, SUM(timeSpent) AS dailyTotal
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY date, mainCategoryName
    )
    GROUP BY mainCategoryName
    ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate]);

      return resultMTA;
    } catch (e) {
      // Handle any database query errors, e.g., log
      // the error and return an empty list or throw an exception.
      logger.e('Error in getMonthTotalAndAverage: $e');
      return [];
    }
  }

  // calculates and returns the total time spent on a particular subcategory
  Future<double> getTotalTimeSpentPerSubcategory(
      String currentDate, String currentUser, String subcategoryName) async {
    try {
      final db = await database;

      // returns total based on the current date, user, and subcategory name
      final result = await db.rawQuery('''
    SELECT SUM(timeSpent) as total_time_spent
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
    } catch (e) {
      logger.e("Error: $e");
      return 0.0;
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
      SUM(timeSpent) AS time_spent
      FROM subcategory 
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? 
      AND mainCategoryName != 'Sleep'
      GROUP BY result_tracked_category
      ORDER BY time_spent DESC
      LIMIT 1;
      ''', [currentUser, firstDay, lastDay]) : await db.rawQuery('''
      SELECT subcategoryName AS result_tracked_category, 
      SUM(timeSpent) AS time_spent
      FROM subcategory 
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ? 
      AND mainCategoryName != 'Sleep'
      GROUP BY result_tracked_category
      ORDER BY time_spent ASC
      LIMIT 1;
        ''', [currentUser, firstDay, lastDay]);

      return resultMLTS;
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // get the highest time tracked for a subcategory for a particular
  // period of time
  Future<List<Map<String, dynamic>>> getHighestTrackedTimePerSubcategory(
      {required String currentUser,
      required String firstDay,
      required String lastDay}) async {
    try {
      final db = await database;

      // the result from the comman table expression
      final resultHTTPS = await db.rawQuery('''
        WITH RankedData AS (
            SELECT 
                date,
                subcategoryName,
                SUM(timeSpent)/60 AS timeSpent,
                ROW_NUMBER() OVER (PARTITION BY subcategoryName ORDER 
                BY timeSpent DESC) AS rk
            FROM subcategory
            WHERE currentLoggedInUser = ? 
            AND date BETWEEN ? AND ? AND timeSpent > 0
            GROUP BY date, subcategoryName
        )
        SELECT 
            date,
            subcategoryName,
            timeSpent
        FROM RankedData
        WHERE rk = 1
        ORDER BY timeSpent DESC;
        ''', [currentUser, firstDay, lastDay]);

      return resultHTTPS;
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // get the subcetegory totals for a specific date
  Future<List<Map<String, dynamic>>> getSubcategoryTotalsForSpecificDate(
      {required String selectedDate, required String currentUser}) async {
    try {
      final db = await database;

      final resultSTFSD = await db.rawQuery('''
      SELECT date, subcategoryName, ROUND(sum(timeSpent),2) AS totalTimeSpent
      FROM subcategory
      WHERE date = ? AND currentLoggedInUser = ?
      GROUP BY subcategoryName
      ORDER BY totalTimeSpent DESC
      ''', [selectedDate, currentUser]);

      return resultSTFSD;
    } catch (e) {
      logger.e("Subcategory Totals For Specific Date Error: $e");
      return [];
    }
  }

  // updates existing subcategory categories rows
  Future<void> updateSubcategory(Subcategories subcategory) async {
    try {
      final db = await database;
      await db.update('subcategory', subcategory.toMap(),
          where: 'id = ?', whereArgs: [subcategory.id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // deletes subcategory rows
  Future<void> deleteSubcategory(int id) async {
    try {
      final db = await database;
      await db.delete('subcategory', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // Comprehensive CRUD Operations for the ExperiencePoints Table

  // insert new rows into the experience_points table
  Future<void> insertExperiencePoint(ExperiencePoints experience) async {
    try {
      final db = await database;
      await db.insert('experience_points', experience.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // get  all data from the experience_points table.
  Future<List<ExperiencePoints>> getAllExperiencePoints(
      {required String date}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT *
      FROM experience_points
      WHERE date = ?;
      ''', [date]);

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
      SELECT ROUND((SUM(educationXP) + SUM(skillsXP) + SUM(sdXP) + SUM(sleepXP)) / 
              COUNT(DISTINCT date), 2) AS efficiencyScore
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
    } catch (e) {
      logger.e("(experiencePointsEfficiencyScore) ERROR: $e");
      return 0.0;
    }
  }

  // (year)
  Future<double> entireYearExperiencePointsEfficiencyScore(
      {required String currentUser, required String currentYear}) async {
    try {
      final db = await database;

      final resultEPES = await db.rawQuery('''
      SELECT ROUND((SUM(educationXP) + SUM(skillsXP) + SUM(sdXP) + SUM(sleepXP)) / 
        COUNT(DISTINCT date), 2) AS efficiencyScore
      FROM experience_points
      WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
      ''', [currentUser, currentYear]);

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
    } catch (e) {
      logger.e("(experiencePointsEfficiencyScore) ERROR: $e");
      return 0.0;
    }
  }

  /// Calculates the average monthly efficiency score for a user over a
  /// specified date range.
  /// The score is computed as the sum of experience points across categories
  /// (educationXP, skillsXP, sdXP, sleepXP),
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
        SELECT ROUND((SUM(educationXP) + SUM(skillsXP) + SUM(sdXP) 
                + SUM(sleepXP)) / COUNT(DISTINCT date), 2) AS efficiencyScore
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
    } catch (e) {
      logger.e("(monthlyEfficiencyScore) ERROR: $e");
      return 0.0;
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
