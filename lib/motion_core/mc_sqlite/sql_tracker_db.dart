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
    this.education = 0,
    this.skills = 0,
    this.entertainment = 0,
    this.personalGrowth = 0,
    this.sleep = 0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to MainCategory object
  factory MainCategory.fromMap(Map<String, dynamic> map) {
    return MainCategory(
      date: map['date'],
      education: map['education'],
      skills: map['skills'],
      entertainment: map['entertainment'],
      personalGrowth: map['personalGrowth'],
      sleep: map['sleep'],
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
    this.timeSpent = 0,
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

    return await openDatabase(path, version: 3, onCreate: _createDatabase);
  }

  void _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE main_category(
        date TEXT PRIMARY KEY,
        education REAL,
        skills REAL,
        entertainment REAL,
        personalGrowth REAL,
        sleep REAL,
        currentLoggedInUser TEXT
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
      FOREIGN KEY(date) REFERENCES main_category(date)
    )
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

      final List<Map<String, dynamic>> maps = await db.query('main_category');

      return maps.map((map) => MainCategory.fromMap(map)).toList();
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

  // calculates and returns the total time spent on a particular subcategory
  Future<double> getTotalTimeSpent(
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
    } catch (e) {
      logger.e("Error: $e");
    }
  }
}
