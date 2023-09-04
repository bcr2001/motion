import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Assigner {
  int? id;
  final String currentLoggedInUser;
  final String subcategoryName;
  final String mainCategoryName;
  int isActive;
  final String dateCreated;

  Assigner({
    this.id,
    required this.currentLoggedInUser,
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.dateCreated,
    this.isActive = 0,
  });
  // (0 == false while 1 == true)

  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
        id: map["id"],
        currentLoggedInUser: map["currentLoggedInUser"],
        subcategoryName: map["subcategoryName"],
        mainCategoryName: map["mainCategoryName"],
        isActive: map["isActive"],
        dateCreated: map["dateCreated"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "currentLoggedInUser": currentLoggedInUser,
      "subcategoryName": subcategoryName,
      "mainCategoryName": mainCategoryName,
      "isActive": isActive,
      "dateCreated": dateCreated
    };
  }

  @override
  String toString() {
    return 'CategoryAssigner{id: $id,currentLoggedInUser: $currentLoggedInUser ,subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName, isActive: $isActive,dateCreated: $dateCreated}';
  }
}

class AssignerDatabaseHelper {
  static final AssignerDatabaseHelper _instance =
      AssignerDatabaseHelper._privateConstructor();

  static Database? _database;

  AssignerDatabaseHelper._privateConstructor();

  factory AssignerDatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "assigner.db");

    return await openDatabase(path, version: 4, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE to_assign(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        currentLoggedInUser TEXT,
        subcategoryName TEXT,
        mainCategoryName TEXT,
        isActive INTEGER,
        dateCreated TEXT
      )
    """);
  }

  // insert data into the to_assign table
  Future<void> assignInsert(Assigner categoryAssigner) async {
    try {
      final db = await database;

      await db.insert("to_assign", categoryAssigner.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  
  // get all items in the database
  Future<List<Assigner>> getAllItems() async {
    try {
      final db = await database;

      final allItems = await db.query("to_assign");

      return allItems.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // get all items that are active
  Future<List<Assigner>> getAllActiveItems() async {
    try {
      final db = await database;

      final activeItems =
          await db.query("to_assign", where: "isActive = ?", whereArgs: [1]);

      return activeItems.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // update rows in the to_assign database
  Future<void> assignUpdate(Assigner categoryAssigner) async {
    try {
      final db = await database;

      await db.update("to_assign", categoryAssigner.toMap(),
          where: "id = ?", whereArgs: [categoryAssigner.id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // delete rows in the to_assign database
  Future<void> assignDelete(int id) async {
    try {
      final db = await database;

      await db.delete("to_assign", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // delete the entire database
  Future<void> deleteDB() async {
    try {
      final dbPath = await getDatabasesPath();

      await deleteDatabase(join(dbPath, "assigner.db"));
      _database = null;
    } catch (e) {
      logger.e("Error: $e");
    }
  }
}
