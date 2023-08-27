import 'package:motion/motion_reusable/reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Assigner {
  int? id;
  final String subcategoryName;
  final String mainCategoryName;

  Assigner(
      {required this.subcategoryName, required this.mainCategoryName, this.id});

  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
        subcategoryName: map["subcategoryName"],
        mainCategoryName: map["mainCategoryName"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "subcategoryName": subcategoryName,
      "mainCategoryName": mainCategoryName
    };
  }

  @override
  String toString() {
    return 'CategoryAssigner{id: $id, subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName}';
  }
}

class AssignerDatabaseHelper {
  static Future<Database> assignerDatabase() async {
    final dbPath = await getDatabasesPath();

    return await openDatabase(join(dbPath, "assigner.db"), version: 1,
        onCreate: (db, version) async {
      await db.execute("""
        CREATE TABLE to_assign(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          subcategoryName TEXT,
          mainCategoryName TEXT
        )
        """);
    });
  }

  // insert data into the database
  static Future<void> assignInsert(Assigner categoryAssigner) async {
    try {
      final db = await AssignerDatabaseHelper.assignerDatabase();

      await db.insert("to_assign", categoryAssigner.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // update data
  static Future<void> assignUpdate(Assigner categoryAssigner) async {
    try {
      final db = await AssignerDatabaseHelper.assignerDatabase();

      await db.update("to_assign", categoryAssigner.toMap(),
          where: "id = ?", whereArgs: [categoryAssigner.id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // delete data
  static Future<void> assignDelete(int id) async {
    try {
      final db = await AssignerDatabaseHelper.assignerDatabase();

      await db.delete("to_assign", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // delete the database
  static Future<void> deleteDB() async {
    try {
      final dbPath = await getDatabasesPath();

      await deleteDatabase(join(dbPath, "assigner.db"));
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // get all data in the database
  static Future<List<Assigner>> getAllItems() async {
    try {
      final db = await AssignerDatabaseHelper.assignerDatabase();

      final allItems = await db.query("to_assign");

      return allItems.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }

  // get all the subcategories under a main category
  static Future<List<Assigner>> getSubcategories(
      String mainCategoryName) async {
    try {
      final db = await AssignerDatabaseHelper.assignerDatabase();

      final subcategories = await db.query("to_assign",
          where: "mainCategoryName = ?", whereArgs: [mainCategoryName]);

      return subcategories.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      logger.e("Error: $e");
      return [];
    }
  }
}
