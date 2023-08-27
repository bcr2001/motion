import 'package:motion/motion_reusable/reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// main categories structure
class MainCategory {
  final String date;
  final int education;
  final int skills;
  final int entertainment;
  final int personalGrowth;
  final int sleep;

  MainCategory(
      {required this.date,
      required this.education,
      required this.skills,
      required this.entertainment,
      required this.personalGrowth,
      required this.sleep});

  factory MainCategory.fromMainMap(Map<String, dynamic> map) {
    return MainCategory(
      date: map["date"],
      education: map["education"],
      skills: map["skills"],
      entertainment: map["entertainment"],
      personalGrowth: map["personalGrowth"],
      sleep: map["sleep"],
    );
  }

  Map<String, dynamic> toMapMain() {
    return {
      "date": date,
      "education": education,
      "skills": skills,
      "entertainment": entertainment,
      "personalGrowth": personalGrowth,
      "sleep": sleep
    };
  }

  @override
  String toString() {
    return 'MainCategory{'
        'date: $date, '
        'education: $education, '
        'skills: $skills, '
        'entertainment: $entertainment, '
        'personalGrowth: $personalGrowth, '
        'sleep: $sleep'
        '}';
  }
}

// subcategories structure
class Subcategories {
  final String subDate;
  final String mainCategoryName;
  final String subcategoryName;
  final int timeSpent;

  Subcategories(
      {required this.subDate,
      required this.mainCategoryName,
      required this.subcategoryName,
      required this.timeSpent});

  factory Subcategories.fromMapSubs(Map<String, dynamic> map) {
    return Subcategories(
        subDate: map["subDate"],
        mainCategoryName: map["mainCategoryName"],
        subcategoryName: map["subcategoryName"],
        timeSpent: map["timeSpent"]);
  }

  Map<String, dynamic> toMapSubs() {
    return {
      "subDate": subDate,
      "mainCategoryName": mainCategoryName,
      "subcategoryName": subcategoryName,
      "timeSpent": timeSpent
    };
  }

  @override
  String toString() {
    return 'Subcategory{'
        'subDate: $subDate, '
        'mainCategoryName: $mainCategoryName, '
        'subcategoryName: $subcategoryName, '
        'timeSpent: $timeSpent'
        '}';
  }
}

// database helper
class DatabaseHelper {
  static Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, "tracker.db"), version: 1,
        onCreate: (db, version) async {
      await db.execute("""
        CREATE TABLE main_category(
          date TEXT PRIMARY KEY,
          education REAL,
          skills REAL,
          entertainment REAL,
          personalGrowth REAL,
          sleep REAL
        )
        """);
      await db.execute("""
        CREATE TABLE subcategory(
          subDate TEXT  PRIMARY KEY,
          mainCategoryName TEXT,
          subcategoryName TEXT,
          timeSpent REAL,
          FOREIGN KEY(subDate) REFERENCES main_category(date)
        )
        """);
    });
  }

  // INSERT DATA INTO THE DATABASE
  // main category table
  static Future<void> insertToMain(MainCategory main) async {
    try {
      // access the database
      final db = await DatabaseHelper.database();

      // insert the data
      await db.insert("main_category", main.toMapMain(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // subcategory table
  static Future<void> insertToSubcategory(Subcategories subcategory) async {
    try {
      final db = await DatabaseHelper.database();

      await db.insert("subcategory", subcategory.toMapSubs(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // UPDATE DATA INTO THE DATABASE
  // main category table
  static Future<void> updateMain(MainCategory main) async {
    try {
      final db = await DatabaseHelper.database();

      await db.update("main_category", main.toMapMain(),
          where: "date = ?", whereArgs: [main.date]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // subcategory table
  static Future<void> updateSubcategory(Subcategories subcategory) async {
    try {
      final db = await DatabaseHelper.database();

      await db.update("subcategory", subcategory.toMapSubs(),
          where: "subDate = ?", whereArgs: [subcategory.subDate]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // DELETE DATA FROM THE DATABASE
  // main category
  static Future<void> deleteFromMain(String date) async {
    try {
      final db = await DatabaseHelper.database();

      await db.delete("main_category", where: "date = ?", whereArgs: [date]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // subcategory
  static Future<void> deleteFromSubcategory(int subDate) async {
    try {
      final db = await DatabaseHelper.database();

      await db
          .delete("subcategory", where: "subDate = ?", whereArgs: [subDate]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // DELETE THE ENTIRE DATABASE
  static Future<void> deleteEntireDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, "tracker.db");

      await deleteDatabase(path);
    } catch (e) {
      logger.e("Error: $e");
    }
  }
}
