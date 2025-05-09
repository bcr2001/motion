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
        version: 10, onCreate: _createDatabase, onUpgrade: _onUpgradeDatabase);
  }

  void _onUpgradeDatabase(Database db, int oldVersion, int newVersion) async {
    logger.i("Database _onUpgradeDatabase function called");
    if (oldVersion < 10) {
      // await db.execute('DROP TABLE IF EXISTS experience_points');
      // Upgrade the database schema here
      // await db.execute('''
      //   CREATE TABLE experience_points(
      //     date TEXT,
      //     educationXP INTEGER,
      //     skillsXP INTEGER,
      //     sdXP INTEGER,
      //     sleepXP INTEGER,
      //     currentLoggedInUser TEXT,
      //     PRIMARY KEY (date, currentLoggedInUser),hi
      //     FOREIGN KEY (date, currentLoggedInUser)
      //     REFERENCES main_category(date, currentLoggedInUser)
      //   )
      // ''');

      // logger.i("Database _onUpgradeDatabase COMPLETED");
    }
  }

  void _createDatabase(Database db, int version) async {
    // create the experience point table
    await db.execute('''
        CREATE TABLE experience_points(
          date TEXT,
          educationXP INTEGER,
          skillsXP INTEGER,
          sdXP INTEGER,
          sleepXP INTEGER,
          currentLoggedInUser TEXT,
          PRIMARY KEY (date, currentLoggedInUser),
          FOREIGN KEY (date, currentLoggedInUser)
          REFERENCES main_category(date, currentLoggedInUser)
        )
      ''');

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
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) < 60 THEN 5
                  WHEN COALESCE(SUM(timeSpent), 0) < 120 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) < 180 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) < 240 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Education' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),

            skillsXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) >= 15 AND COALESCE(SUM(timeSpent), 0) < 60 THEN 5
                  WHEN COALESCE(SUM(timeSpent), 0) >= 60 AND COALESCE(SUM(timeSpent), 0) < 120 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) >= 120 AND COALESCE(SUM(timeSpent), 0) < 180 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) >= 180 AND COALESCE(SUM(timeSpent), 0) < 240 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),


            sdXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) >= 15 AND COALESCE(SUM(timeSpent), 0) < 60 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) >= 60 AND COALESCE(SUM(timeSpent), 0) < 120 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) >= 120 AND COALESCE(SUM(timeSpent), 0) < 180 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 180 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Self Development' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),


            sleepXP = (SELECT 
                CASE
                    WHEN COALESCE(SUM(timeSpent), 0) < 300 THEN 0
                    WHEN COALESCE(SUM(timeSpent), 0) >= 300 AND COALESCE(SUM(timeSpent), 0) < 360 THEN 5
                    WHEN COALESCE(SUM(timeSpent), 0) >= 360 AND COALESCE(SUM(timeSpent), 0) < 420 THEN 10
                    WHEN COALESCE(SUM(timeSpent), 0) >= 420 AND COALESCE(SUM(timeSpent), 0) < 480 THEN 20
                    WHEN COALESCE(SUM(timeSpent), 0) >= 480 THEN 25
                    ELSE 0 
                END
              FROM subcategory 
              WHERE mainCategoryName = 'Sleep' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser)
            WHERE date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser;
          END;  
        ''');

    // trigger to update the experience point table if
    // a deletion is made in the subcategory table
    await db.execute('''
        CREATE TRIGGER IF NOT EXISTS update_experience_points_after_delete
        AFTER DELETE ON subcategory
        BEGIN
          UPDATE experience_points
          SET 
            educationXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) < 60 THEN 5
                  WHEN COALESCE(SUM(timeSpent), 0) < 120 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) < 180 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) < 240 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Education' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            skillsXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) >= 15 AND COALESCE(SUM(timeSpent), 0) < 60 THEN 5
                  WHEN COALESCE(SUM(timeSpent), 0) >= 60 AND COALESCE(SUM(timeSpent), 0) < 120 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) >= 120 AND COALESCE(SUM(timeSpent), 0) < 180 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) >= 180 AND COALESCE(SUM(timeSpent), 0) < 240 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 240 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            sdXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 15 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) >= 15 AND COALESCE(SUM(timeSpent), 0) < 60 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) >= 60 AND COALESCE(SUM(timeSpent), 0) < 120 THEN 15
                  WHEN COALESCE(SUM(timeSpent), 0) >= 120 AND COALESCE(SUM(timeSpent), 0) < 180 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 180 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Self Development' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),

            sleepXP = (SELECT 
              CASE
                  WHEN COALESCE(SUM(timeSpent), 0) < 300 THEN 0
                  WHEN COALESCE(SUM(timeSpent), 0) >= 300 AND COALESCE(SUM(timeSpent), 0) < 360 THEN 5
                  WHEN COALESCE(SUM(timeSpent), 0) >= 360 AND COALESCE(SUM(timeSpent), 0) < 420 THEN 10
                  WHEN COALESCE(SUM(timeSpent), 0) >= 420 AND COALESCE(SUM(timeSpent), 0) < 480 THEN 20
                  WHEN COALESCE(SUM(timeSpent), 0) >= 480 THEN 25
                  ELSE 0 
              END
            FROM subcategory 
            WHERE mainCategoryName = 'Sleep' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser)
          WHERE date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser;
        END;
        ''');
    // a trigger to update the main_category table
    // calculate the sums from the subcategory table
    // and updates the main_category table depending on the aggregation
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_main_category
      AFTER INSERT ON subcategory
      BEGIN
        UPDATE main_category
        SET education = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
        mainCategoryName = 'Education' AND date = NEW.date AND 
        currentLoggedInUser = NEW.currentLoggedInUser),
            skills = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory 
            WHERE mainCategoryName = 'Skills' AND date = NEW.date AND 
            currentLoggedInUser = NEW.currentLoggedInUser),
            entertainment = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory 
            WHERE mainCategoryName = 'Entertainment' AND date = NEW.date 
            AND currentLoggedInUser = NEW.currentLoggedInUser),
            selfDevelopment = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
            mainCategoryName = 'Self Development' AND date = NEW.date AND 
            currentLoggedInUser = NEW.currentLoggedInUser),
            sleep = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
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
          SET education = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
          mainCategoryName = 'Education' AND date = OLD.date AND 
          currentLoggedInUser = OLD.currentLoggedInUser),
              skills = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
              mainCategoryName = 'Skills' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              entertainment = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
              mainCategoryName = 'Entertainment' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              selfDevelopment = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
              mainCategoryName = 'Self Development' AND date = OLD.date AND 
              currentLoggedInUser = OLD.currentLoggedInUser),
              sleep = (SELECT COALESCE(SUM(timeSpent), 0) FROM subcategory WHERE 
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
                WHEN mainCategoryName = 'Education' THEN
                    CASE 
                        WHEN totalTimeSpent < 15 THEN '0'
                        WHEN totalTimeSpent < 60 THEN '5'
                        WHEN totalTimeSpent < 120 THEN '10'
                        WHEN totalTimeSpent < 180 THEN '15'
                        WHEN totalTimeSpent < 240 THEN '20'
                        WHEN totalTimeSpent >= 240 THEN '25'
                        ELSE '0'
                    END
                WHEN mainCategoryName = 'Skills' THEN
                    CASE 
                        WHEN totalTimeSpent < 15 THEN '0'
                        WHEN totalTimeSpent >= 15 AND totalTimeSpent < 60 THEN '5'
                        WHEN totalTimeSpent >= 60 AND totalTimeSpent < 120 THEN '10'
                        WHEN totalTimeSpent >= 120 AND totalTimeSpent < 180 THEN '15'
                        WHEN totalTimeSpent >= 180 AND totalTimeSpent < 240 THEN '20'
                        WHEN totalTimeSpent >= 240 THEN '25'
                        ELSE '0'
                    END
                WHEN mainCategoryName = 'Self Development' THEN
                    CASE 
                        WHEN totalTimeSpent < 15 THEN '0'
                        WHEN totalTimeSpent >= 15 AND totalTimeSpent < 60 THEN '10'
                        WHEN totalTimeSpent >= 60 AND totalTimeSpent < 120 THEN '15'
                        WHEN totalTimeSpent >= 120 AND totalTimeSpent < 180 THEN '20'
                        WHEN totalTimeSpent >= 180 THEN '25'
                        ELSE '0'
                    END
                WHEN mainCategoryName = 'Sleep' THEN
                    CASE 
                        WHEN totalTimeSpent < 300 THEN '0'
                        WHEN totalTimeSpent >= 300 AND totalTimeSpent < 360 THEN '5'
                        WHEN totalTimeSpent >= 360 AND totalTimeSpent < 420 THEN '10'
                        WHEN totalTimeSpent >= 420 AND totalTimeSpent < 480 THEN '20'
                        WHEN totalTimeSpent >= 480 THEN '25'
                        ELSE '0'
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
    } catch (e) {
      logger.e("(getLeftJoinOnMainAndXP) Error: $e");
      return [];
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
        SELECT mainCategoryName, COALESCE(SUM(timeSpent)/60, 0) AS totalTimeSpent
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
        SELECT mainCategoryName, COALESCE(SUM(timeSpent)/60, 0) AS totalTimeSpent
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
      {required String currentUser,
      String year = "",
      bool getEntireIntensity = true}) async {
    try {
      final db = await database;

      final resultDAAI = getEntireIntensity ? await db.rawQuery('''
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

        ''', [currentUser]) : await db.rawQuery('''
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
            WHERE currentLoggedInUser = ? AND strftime("%Y", date) = ?

        ''', [currentUser, year]);

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
    } catch (e) {
      logger.e("getAllSubcategoryTotals Error $e");

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
    } catch (e) {
      // Handle the exception, e.g., log it or rethrow it for debugging.
      logger.e('Error in getMonthTotalTimeSpent: $e');
      return 0.0;
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
Future<List<Map<String, dynamic>>> getMonthTotalAndAverage(
    String currentUser, String startingDate, String endingDate, bool isSubcategory) async {
  final db = await database;

  try {
    final resultMTA = isSubcategory
        ? await db.rawQuery('''
      SELECT subcategoryName, COALESCE(SUM(timeSpent), 0) AS total, 
      COALESCE(AVG(timeSpent), 0) AS average
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY subcategoryName
      ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate])
        : await db.rawQuery('''
      SELECT mainCategoryName, COALESCE(SUM(dailyTotal),0) AS total, 
      COALESCE(AVG(dailyTotal), 0) AS average
      FROM (
        SELECT date, mainCategoryName, COALESCE(SUM(timeSpent), 0) AS dailyTotal
        FROM subcategory
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date, mainCategoryName
      )
      GROUP BY mainCategoryName
      ORDER BY total DESC;
    ''', [currentUser, startingDate, endingDate]);

    return resultMTA;
  } catch (e, stackTrace) {
    logger.e('Error in getMonthTotalAndAverage: $e\nStack Trace: $stackTrace');
    return [];
  }
}


/// Calculates the user's streak based on tracked activities.
/// 
/// A streak is defined as consecutive days where at least one subcategory 
/// (education, skills, entertainment, self-development, or sleep) has been tracked.
/// 
/// - If the user tracks any subcategory on a given day, the streak increases.
/// - If there is a gap (a day with no tracked subcategories), the streak resets.
/// - Future dates are ignored.
/// - The streak is counted correctly based on past tracked activity.
/// 
/// This function queries the database for all tracked records of the current user, 
/// processes them in chronological order, and determines the streak count.
Future<int> getUserStreak({required String currentUser}) async {
  // Get a reference to the database
  final db = await database;

  // Fetch all records for the current user, summing up category values for each date
  // The records are ordered by date in ascending order
  final List<Map<String, dynamic>> records = await db.rawQuery('''
    SELECT date, (education + skills + entertainment + selfDevelopment + sleep) AS total
    FROM main_category
    WHERE currentLoggedInUser = ?
    ORDER BY date ASC
  ''', [currentUser]);

  // If there are no records, return a streak of 0
  if (records.isEmpty) return 0;

  int streak = 0; // Keeps track of the user's streak
  DateTime? previousDate; // Stores the last recorded date for comparison
  DateTime now = DateTime.now();
  DateTime currentDate = DateTime(now.year, now.month, now.day); // Normalize to start of the day

  // Iterate through each record in the database
  for (var record in records) {
    DateTime recordDate = DateTime.parse(record['date']); // Convert date from string to DateTime
    double total = record['total']; // Sum of all tracked subcategories for that date

    if (recordDate.isAfter(currentDate)) {
      continue; // Skip future dates
    }

    if (total > 0) { // If any subcategory was tracked on this date
      if (previousDate == null) {
        // First tracked day, start the streak at 1
        streak = 1;
      } else if (recordDate.difference(previousDate).inDays == 1) {
        // If the current record is exactly one day after the previous, continue the streak
        streak++;
      } else if (recordDate.difference(previousDate).inDays > 1) {
        // If there's a gap of more than one day, reset the streak to 1
        streak = 1;
      }
      previousDate = recordDate; // Update previousDate for the next iteration
    }
  }

  // **NEW LOGIC: Reset streak if today is not the next day after the last recorded date**
  if (previousDate != null) {
    int daysSinceLastRecord = currentDate.difference(previousDate).inDays;
    if (daysSinceLastRecord > 1) {
      return 0; // Streak resets because there was a skipped day
    }
  }

  return streak;
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
      SELECT date, subcategoryName, ROUND(COALESCE(SUM(timeSpent), 0),2) AS totalTimeSpent
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

      logger.i("Update successfull");
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
      WHERE strftime('%Y', date) = ?;
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
          SELECT ROUND((
            COALESCE(SUM(educationXP), 0) + 
            COALESCE(SUM(skillsXP), 0) + 
            COALESCE(SUM(sdXP), 0) + 
            COALESCE(SUM(sleepXP), 0)
          ) / COUNT(DISTINCT date), 2) AS efficiencyScore
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
          SELECT ROUND(
            (
              COALESCE(SUM(educationXP), 0) + 
              COALESCE(SUM(skillsXP), 0) + 
              COALESCE(SUM(sdXP), 0) + 
              COALESCE(SUM(sleepXP), 0)
            ) / COUNT(DISTINCT date), 2
          ) AS efficiencyScore
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
      SELECT ROUND((
        COALESCE(SUM(educationXP), 0) + 
        COALESCE(SUM(skillsXP), 0) + 
        COALESCE(SUM(sdXP), 0) + 
        COALESCE(SUM(sleepXP), 0)
      ) / COUNT(DISTINCT date), 2) AS efficiencyScore
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

  // Gets the all time total XP points
  // or XP points for the current year
  Future<int> getTotalXP(
      {required String currentUser,
      required bool isEntire,
      String? year}) async {
    try {
      final db = await database;

      final resultGTXP = isEntire ? await db.rawQuery("""
        SELECT (COALESCE(SUM(educationXP), 0) + 
                COALESCE(SUM(skillsXP), 0) + 
                COALESCE(SUM(sdXP), 0) + 
                COALESCE(SUM(sleepXP), 0)) AS entireTotalXP
        FROM experience_points
        WHERE currentLoggedInUser = ?
        """, [currentUser]) : await db.rawQuery("""
        SELECT (COALESCE(SUM(educationXP), 0) + 
                COALESCE(SUM(skillsXP), 0) + 
                COALESCE(SUM(sdXP), 0) + 
                COALESCE(SUM(sleepXP), 0)) AS entireTotalXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ?
          """, [currentUser, year]);

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
    } catch (e) {
      logger.i("getTotalXP error: $e");
      return 0;
    }
  }

  // Gets the efficiency score for the selected date
  // Gets the total experience points for the selected date
  Future<int> dailyExperiencePoints(
      {required String currentUser, required String selectedDate}) async {
    try {
      final db = await database;

      final resultDES = await db.rawQuery('''
      SELECT COALESCE(SUM(educationXP), 0) + COALESCE(SUM(skillsXP), 0) + 
             COALESCE(SUM(sdXP), 0) + COALESCE(SUM(sleepXP), 0) AS totalXP
      FROM experience_points
      WHERE currentLoggedInUser = ? AND date = ?
    ''', [currentUser, selectedDate]);

      if (resultDES.isNotEmpty) {
        final totalXP = resultDES.first['totalXP'];

        if (totalXP is int) {
          return totalXP;
        } else {
          return 0; // Handle the case where the result is not a double
        }
      } else {
        return 0; // Return 0.0 if no matching records are found
      }
    } catch (e) {
      logger.e("(dailyExperiencePoints) ERROR: $e");
      return 0; // Return 0.0 on error
    }
  }

  // this function get the most and least productive months
  Future<List<Map<String, dynamic>>> getMostAndLeastProductiveMonths(
      {required bool getMostProductiveMonth,
      required String currentUser,
      required String year}) async {
    try {
      final db = await database;

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
                    COALESCE(SUM(educationXP), 0) + COALESCE(SUM(skillsXP), 0) + 
                    COALESCE(SUM(sdXP), 0) + COALESCE(SUM(sleepXP), 0) AS totalMostXP
              FROM experience_points
              WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ? 
              GROUP BY month_num
          ) AS totalMostXP
        """, [currentUser, year]) : await db.rawQuery("""
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
                  COALESCE(SUM(educationXP), 0) + COALESCE(SUM(skillsXP), 0) + 
                  COALESCE(SUM(sdXP), 0) + COALESCE(SUM(sleepXP), 0) AS totalLeastXP
            FROM experience_points
            WHERE currentLoggedInUser = ? AND strftime('%Y', date) = ? 
            GROUP BY month_num
        ) AS totalLeastXP
          """, [currentUser, year]);
      return resultMALPM;
    } catch (e) {
      logger.e("(getMostAndLeastProductiveMonths) ERROR: $e");
      return [];
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
        SELECT date, COALESCE(SUM(educationXP), 0) + COALESCE(SUM(skillsXP), 0) + 
             COALESCE(SUM(sdXP), 0) + COALESCE(SUM(sleepXP), 0) AS totalMostXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date
      ) AS totalMostXP
        """, [currentUser, firstDay, lastDay]) : await db.rawQuery("""
      SELECT COALESCE(date, 'TBD') AS date, COALESCE(MIN(totalLeastXP),0) AS least_productive
      FROM (
        SELECT date, COALESCE(SUM(educationXP), 0) + COALESCE(SUM(skillsXP), 0) + 
             COALESCE(SUM(sdXP), 0) + COALESCE(SUM(sleepXP), 0) AS totalLeastXP
        FROM experience_points
        WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
        GROUP BY date
      ) AS totalLeastXP
        """, [currentUser, firstDay, lastDay]);

      return resultMALPD;
    } catch (e) {
      logger.e("(getMostAndLeastProductiveDays) ERROR $e");
      return [];
    }
  }

  /// Fetches *all* experience_points rows for [currentUser].
Future<List<ExperiencePoints>> getAllExperiencePointsForUser({
  required String currentUser,
}) async {
  final db = await database;
  // Query every column in the table, filtered by the user
  final result = await db.query(
    'experience_points',
    where: 'currentLoggedInUser = ?',
    whereArgs: [currentUser],
  );

  // Map each row to your model
  return result
      .map((row) => ExperiencePoints.fromMap(row))
      .toList();
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
