import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MainCategory {
  final String date;
  int education;
  int skills;
  int entertainment;
  int personalGrowth;
  int sleep;
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
  final String subDate;
  final String mainCategoryName;
  final String subcategoryName;
  int timeSpent;
  final String currentLoggedInUser;

  Subcategories({
    this.id,
    required this.subDate,
    required this.mainCategoryName,
    required this.subcategoryName,
    this.timeSpent = 0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to Subcategories object
  factory Subcategories.fromMap(Map<String, dynamic> map) {
    return Subcategories(
      id: map["id"],
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
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, // Add id as the primary key
      subDate TEXT,
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
        where: 'id = ?', whereArgs: [subcategory.id]);
  }

  Future<void> deleteSubcategory(String id) async {
    final db = await database;
    await db.delete('subcategory', where: 'id = ?', whereArgs: [id]);
  }
}
