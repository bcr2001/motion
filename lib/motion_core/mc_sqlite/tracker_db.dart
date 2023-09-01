import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MainCategory {
  final String date;
  final int education;
  final int skills;
  final int entertainment;
  final int personalGrowth;
  final int sleep;
  final String currentLoggedInUser;

  MainCategory({
    required this.date,
    required this.education,
    required this.skills,
    required this.entertainment,
    required this.personalGrowth,
    required this.sleep,
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
  final String subDate;
  final String mainCategoryName;
  final String subcategoryName;
  final int timeSpent;
  final String currentLoggedInUser;

  Subcategories({
    required this.subDate,
    required this.mainCategoryName,
    required this.subcategoryName,
    required this.timeSpent,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to Subcategories object
  factory Subcategories.fromMap(Map<String, dynamic> map) {
    return Subcategories(
      subDate: map['subDate'],
      mainCategoryName: map['mainCategoryName'],
      subcategoryName: map['subcategoryName'],
      timeSpent: map['timeSpent'],
      currentLoggedInUser: map['currentLoggedInUser'],
    );
  }

  // Convert Subcategories object to a map
  Map<String, dynamic> toMap() {
    return {
      'subDate': subDate,
      'mainCategoryName': mainCategoryName,
      'subcategoryName': subcategoryName,
      'timeSpent': timeSpent,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }
}

class TrackerDatabaseHelper {
  // Private constructor to prevent instantiation from outside
  TrackerDatabaseHelper._();

  // Singleton instance
  static final TrackerDatabaseHelper _instance = TrackerDatabaseHelper._();

  // Database instance
  static Database? _database;

  // Getter for the instance
  static TrackerDatabaseHelper get instance => _instance;

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

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  void _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE main_category(
        date TEXT PRIMARY KEY,
        education INTEGER,
        skills INTEGER,
        entertainment INTEGER,
        personalGrowth INTEGER,
        sleep INTEGER,
        currentLoggedInUser TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE subcategory(
        subDate TEXT PRIMARY KEY,
        mainCategoryName TEXT,
        subcategoryName TEXT,
        timeSpent INTEGER,
        currentLoggedInUser TEXT,
        FOREIGN KEY(subDate) REFERENCES main_category(date)
      )
    ''');
  }

  // CRUD operations for MainCategory
  Future<void> insertMainCategory(MainCategory mainCategory) async {
    final db = await database;
    await db.insert('main_category', mainCategory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MainCategory>> getAllMainCategories() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('main_category');

    return maps.map((map) => MainCategory.fromMap(map)).toList();
  }

  Future<void> updateMainCategory(MainCategory mainCategory) async {
    final db = await database;
    await db.update('main_category', mainCategory.toMap(),
        where: 'date = ?', whereArgs: [mainCategory.date]);
  }

  Future<void> deleteMainCategory(String date) async {
    final db = await database;
    await db.delete('main_category', where: 'date = ?', whereArgs: [date]);
  }

  // CRUD operations for Subcategories
  Future<void> insertSubcategory(Subcategories subcategory) async {
    final db = await database;
    await db.insert('subcategory', subcategory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Subcategories>> getAllSubcategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subcategory');
    return maps.map((map) => Subcategories.fromMap(map)).toList();
  }

  Future<void> updateSubcategory(Subcategories subcategory) async {
    final db = await database;
    await db.update('subcategory', subcategory.toMap(),
        where: 'subDate = ?', whereArgs: [subcategory.subDate]);
  }

  Future<void> deleteSubcategory(String subDate) async {
    final db = await database;
    await db.delete('subcategory', where: 'subDate = ?', whereArgs: [subDate]);
  }
}
