import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MainCategory {
  final String date;
  double education;
  double skills;
  double entertainment;
  double personalGrowth;
  double sleep;
  String currentLoggedInUser;

  MainCategory({
    required this.date,
    this.education = 0.0,
    this.skills = 0.0,
    this.entertainment = 0.0,
    this.personalGrowth = 0.0,
    this.sleep = 0.0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to MainCategory object
  factory MainCategory.fromMap(Map<String, dynamic> map) {
    return MainCategory(
      date: map['date'],
      education: map['education'] ?? 0.0,
      skills: map['skills'] ?? 0.0,
      entertainment: map['entertainment'] ?? 0.0,
      personalGrowth: map['personalGrowth'] ?? 0.0,
      sleep: map['sleep'] ?? 0.0,
      currentLoggedInUser: map['currentLoggedInUser'],
    );
  }

  // Convert MainCategory object to a map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'education': education,
      'skills': skills,
      'entertainment': entertainment,
      'personalGrowth': personalGrowth,
      'sleep': sleep,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Main category{date: $date, education: $education, skills: $skills, entertainment: $entertainment, personalGrowth: $personalGrowth, sleep: $sleep, user: $currentLoggedInUser}';
  }
}

class Subcategories {
  int? id;
  final String date;
  final String mainCategoryName;
  final String subcategoryName;
  final String timeRecorded;
  double timeSpent;
  final String currentLoggedInUser;

  Subcategories({
    this.id,
    required this.date,
    required this.mainCategoryName,
    required this.subcategoryName,
    required this.timeRecorded,
    this.timeSpent = 0.0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to Subcategories object
  factory Subcategories.fromMap(Map<String, dynamic> map) {
    return Subcategories(
      id: map["id"],
      date: map['date'],
      mainCategoryName: map['mainCategoryName'],
      subcategoryName: map['subcategoryName'],
      timeRecorded: map["timeRecorded"],
      timeSpent: map['timeSpent'],
      currentLoggedInUser: map['currentLoggedInUser'],
    );
  }

  // Convert Subcategories object to a map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'mainCategoryName': mainCategoryName,
      'subcategoryName': subcategoryName,
      'timeRecorded': timeRecorded,
      'timeSpent': timeSpent,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Subcategories {'
        'Id: $id, '
        'date: $date, '
        'mainCategoryName: $mainCategoryName, '
        'subcategoryName $subcategoryName, '
        'timeRecorded: $timeRecorded,'
        'timeSpent: $timeSpent, '
        'currentLoggedInUser: $currentLoggedInUser'
        '}';
  }
}

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
    //Create a trigger to update the main_category table
    //Calculate the sums from the subcategory table and update the main_category table
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
    }
  }

  // delete rows in the main category table
  Future<void> deleteMainCategory(String date) async {
    try {
      final db = await database;
      await db.delete('main_category', where: 'date = ?', whereArgs: [date]);
    } catch (e) {
      logger.e("Error: $e");
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
    }
  }

  // get all data in the subcategories table
  Future<List<Subcategories>> getAllSubcategories() async {
    final db = await database;

    final allSubs = await db.query("subcategory");

    return allSubs.map((map) => Subcategories.fromMap(map)).toList();
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

  // calculate and return the total time spent on all the categories for a particular date
  Future<double> getTotalTimeForCurrentDate(
      String currentDate, String currentUser) async {
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
  }

  // calculates and returns the total and average time spent on a subcategory for an entire week
  Future<double> getWeeklyTotalAndAverage(String subcategoryName,
      String currentUser, String startingDate, String endingDate) async {
    final db = await database;

    final results = await db.rawQuery('''
    SELECT SUM(timeSpent) as total
    FROM subcategory
    WHERE subcategoryName = ? AND currentLoggedInUser = ? AND date BETWEEN ? AND ?;
    ''', [subcategoryName, currentUser, startingDate, endingDate]);

    if (results.isNotEmpty) {
      final weekTotal = results.first["total"];

      if (weekTotal is double) {
        return weekTotal;
      } else {
        return 0.0;
      }
    } else {
      return 0.0;
    }
  }

  // calculates and returns the total time spent on a particular subcategory
  Future<double> getTotalTimeSpentPerSubcategory(
      String currentDate, String currentUser, String subcategoryName) async {
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
