import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// assigner database that stores the subcategories and their
// main category names as well as whether they are active or not
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
