import 'dart:async';
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

    return await openDatabase(path, version: 6, onCreate: _createDatabase);
  }

  void _createDatabase(Database db, int version) async {
    // creation of the main_category table
    await db.execute('''
      CREATE TABLE main_category(
        date TEXT,
        education REAL,
        skills REAL,
        entertainment REAL,
        personalGrowth REAL,
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
      FOREIGN KEY (date, currentLoggedInUser) REFERENCES main_category(date, 	currentLoggedInUser)
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
        SET education = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Education' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),
            skills = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Skills' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),
            entertainment = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Entertainment' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),
            personalGrowth = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Personal Growth' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser),
            sleep = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Sleep' AND date = NEW.date AND currentLoggedInUser = NEW.currentLoggedInUser)
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
          SET education = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Education' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),
              skills = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Skills' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),
              entertainment = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Entertainment' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),
              personalGrowth = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Personal Growth' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser),
              sleep = (SELECT SUM(timeSpent) FROM subcategory WHERE mainCategoryName = 'Sleep' AND date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser)
          WHERE date = OLD.date AND currentLoggedInUser = OLD.currentLoggedInUser;
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
      throw ("An Error Occured during inserting");
    }
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

// CRUD operations for Subcategories

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
      rethrow; // Rethrow the exception for debugging or custom error handling.
    }
  }

  // gets the total and average time spent on all
  // subcategories for the entire month
  Future<List<Map<String, dynamic>>> getMonthTotalAndAverage(String currentUser,
      String startingDate, String endingDate, bool isSubcategory) async {
    final db = await database;

    try {
      final resultMTA = isSubcategory ? await db.rawQuery('''
      SELECT subcategoryName, SUM(timeSpent) AS total, AVG(timeSpent * 1.0) AS average
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY subcategoryName
      ORDER BY total DESC;
      ''', [currentUser, startingDate, endingDate]) : await db.rawQuery('''
      SELECT mainCategoryName, SUM(timeSpent) AS total, AVG(timeSpent * 1.0) AS average
      FROM subcategory
      WHERE currentLoggedInUser = ? AND date BETWEEN ? AND ?
      GROUP BY mainCategoryName
      ORDER BY total DESC;
      ''', [currentUser, startingDate, endingDate]);

      return resultMTA;
    } catch (e) {
      // Handle any database query errors, e.g., log the error and return an empty list or throw an exception.
      logger.e('Error in getMonthTotalAndAverage: $e');
      return [];
    }
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
        SELECT ((COUNT(date) * 24)*60) - (COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(personalGrowth), 0) + COALESCE(SUM(sleep), 0)) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ?
        ''', [currentUser]) : await db.rawQuery('''
        SELECT COALESCE(SUM(education), 0) + COALESCE(SUM(skills), 0) + COALESCE(SUM(entertainment), 0) + COALESCE(SUM(personalGrowth), 0) + COALESCE(SUM(sleep), 0) AS EntireTotalResult
        FROM main_category
        WHERE currentLoggedInUser = ?
        ''', [currentUser]);

      if (resultETMCT.isNotEmpty) {
        final totalETMCT = resultETMCT.first["EntireTotalResult"];
        if (totalETMCT is double) {
          return totalETMCT;
        } else {
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e) {
      // Handle any database query errors, e.g., log the error and return an empty list or throw an exception.
      logger.e('Error in getMonthTotalAndAverage: $e');
      rethrow;
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
      rethrow;
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

// Delete the entire database
  Future<void> deleteDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, "tracker.db");

      await deleteDatabase(path);
      _database = null; // Reset the database instance

      logger.i("Database has been deleted");
    } catch (e) {
      logger.e("Error: $e");
    }
  }
}
