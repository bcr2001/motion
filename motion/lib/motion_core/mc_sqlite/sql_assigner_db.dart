import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// This class defines the AssignerDatabaseHelper for managing the 'to_assign'
// table in the SQLite database. The 'to_assign' table is designed to store
// information about various assignments. Each record includes details such as
// the subcategory and main category of the assignment, along with flags
// indicating whether each assignment is currently active or archived.
class AssignerDatabaseHelper {
  // Singleton instance of AssignerDatabaseHelper to ensure
  // only one instance exists.
  static final AssignerDatabaseHelper _instance =
      AssignerDatabaseHelper._privateConstructor();

  // Private variable to hold the database instance.
  static Database? _database;

  // Private constructor for the Singleton pattern.
  AssignerDatabaseHelper._privateConstructor();

  // Factory constructor to return the Singleton instance.
  factory AssignerDatabaseHelper() {
    return _instance;
  }

  // Getter for the database. If the database is already initialized, it
  // returns the existing instance. If not, it initializes the database
  // and then returns the instance.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // Private method to initialize the database.
  // This sets up the path for the database file and opens the database,
  // applying the onCreate and onUpgrade methods as needed.
  Future<Database> _initDatabase() async {
    // Get the default database path provided by the sqflite package.
    final dbPath = await getDatabasesPath();

    // Set the path for our database file.
    final path = join(dbPath, "assigner.db");

    // Open the database, creating it if it doesn't exist and
    // upgrading it if necessary.
    return await openDatabase(path,
        version: 6, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  // Method called when the database is created for the first time.
  // This is where we define the schema of our database.
  Future<void> _onCreate(Database db, int version) async {
    // Execute SQL query to create a new table.
    // The 'to_assign' table will store various details about assignments.
    await db.execute("""
      CREATE TABLE to_assign(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        currentLoggedInUser TEXT,
        subcategoryName TEXT,
        mainCategoryName TEXT,
        isActive INTEGER,
        isArchive INTEGER DEFAULT 0,
        dateCreated TEXT
      )
    """);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (newVersion > oldVersion) {
      // Add the new column 'isArchive' to the table
      await db.execute(
          "ALTER TABLE to_assign ADD COLUMN isArchive INTEGER DEFAULT 0");
    }
  }

  // Method to insert a new 'Assigner' record into the 'to_assign' table.
  Future<void> assignInsert(Assigner categoryAssigner) async {
    try {
      // Get the instance of the database.
      final db = await database;

      // Insert the 'Assigner' object into the 'to_assign' table.
      // The 'toMap' method of the 'Assigner' class converts the object into
      // a map format suitable for database insertion. 'conflictAlgorithm:
      // ConflictAlgorithm.replace' is used to handle conflicts by replacing
      // old data with new data.
      await db.insert("to_assign", categoryAssigner.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Log any errors that occur during the database insertion.
      logger.e("(assignInsert): Error: $e");
    }
  }

  // get all items in the database
  // Method to retrieve all records from the 'to_assign' table.
  Future<List<Assigner>> getAllItems() async {
    try {
      // Get the instance of the database.
      final db = await database;

      // Query the database to get all records from the 'to_assign' table.
      final allItems = await db.query("to_assign");

      // Convert each record (map) into an 'Assigner' object
      // and return the list of these objects. 'Assigner.fromAssignerMap'
      // is used to convert a map into an 'Assigner' instance.
      return allItems.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      // Log any errors that occur during the database query.
      logger.e("Assigner(getAllItems): Error => $e");

      // Return an empty list in case of an error.
      return [];
    }
  }

  // Method to retrieve all active items from the 'to_assign' table.
  Future<List<Assigner>> getAllActiveItems() async {
    try {
      // Obtain the database instance.
      final db = await database;

      // Query the 'to_assign' table to fetch only those records where
      // 'isActive' is 1. This indicates that the items are currently active.
      final activeItems = await db.query("to_assign",
          where: "isActive = ?", // SQL WHERE clause to filter active items.
          whereArgs: [1]
          // Arguments for the WHERE clause. '1' represents
          // true for 'isActive'.
          );

      // Convert each record (map) from the query result into an
      // 'Assigner' object. 'Assigner.fromAssignerMap' is a factory constructor
      // that creates an 'Assigner' instance from a Map.
      return activeItems.map((map) => Assigner.fromAssignerMap(map)).toList();
    } catch (e) {
      // Log any errors encountered during the database query.
      logger.e("Assigner (getAllActiveItems): Error => $e");

      // Return an empty list in case of an error.
      return [];
    }
  }

  // Method to check if the 'to_assign' table is empty or
  // if there are no active subcategories being tracked.
  Future<List<Map<String, dynamic>>> isTableEmptyOrNotBeingTracked(
      {required String currentUser}) async {
    try {
      // Obtain the database instance.
      final db = await database;

      // Execute a raw SQL query to determine if there are any active
      // items for the current user. The query uses a CASE statement to
      // return 'False' if there are active items (COUNT(*) > 0),
      // and 'True' if there are none.
      final resultITEONBT = await db.rawQuery('''
        SELECT 
            CASE 
                WHEN COUNT(*) > 0 THEN 'False'
                ELSE 'True'
            END AS AllAreZero
        FROM to_assign
        WHERE isActive <> 0 AND currentLoggedInUser = ?;
        ''', [currentUser]);

      // Return the result of the query.
      return resultITEONBT;
    } catch (e) {
      // Log any errors encountered during the database query.
      logger.i("Assigner (isTableEmptyOrNotBeingTracked)ERROR => $e");
      return [];
    }
  }

  // Method to update a specific row in the 'to_assign' database table.
  Future<void> assignUpdate(Assigner categoryAssigner) async {
    try {
      // Get the instance of the database.
      final db = await database;

      // Update the row in the 'to_assign' table that corresponds
      // to the given 'Assigner' object. 'categoryAssigner.toMap()'
      // converts the 'Assigner' object to a map format suitable
      // for the update operation. The 'where' clause specifies that
      // the update should only apply to the row with the matching 'id'.
      await db.update("to_assign", categoryAssigner.toMap(), // Data to update.
          where: "id = ?", // SQL WHERE clause to specify which row to update.
          whereArgs: [
            categoryAssigner.id
          ] // Argument for the WHERE clause - the ID of the 'Assigner'.
          );
    } catch (e) {
      // Log any errors encountered during the update operation.
      logger.e("Assigner (assignUpdate): Error => $e");
    }
  }

  // Method to delete a row from the 'to_assign' database table.
  Future<void> assignDelete(int id) async {
    try {
      // Obtain the database instance.
      final db = await database;

      // Execute the delete operation on the 'to_assign' table.
      // The 'where' clause specifies that the delete should only apply
      // to the row with the matching 'id'.
      await db.delete("to_assign",
          where: "id = ?", // SQL WHERE clause to specify which row to delete.
          whereArgs: [
            id
          ] // Argument for the WHERE clause - the ID of the row to delete.
          );
    } catch (e) {
      // Log any errors encountered during the delete operation.
      logger.e("Assigner (assignDelete): Error => $e");
    }
  }

  // Method to delete the entire 'assigner.db' database.
  Future<void> deleteDB() async {
    try {
      // Retrieve the path where the database is stored.
      final dbPath = await getDatabasesPath();

      // Delete the database file from the filesystem.
      await deleteDatabase(join(dbPath, "assigner.db"));

      // Set the database instance to null, indicating that the database 
      // is no longer available.
      _database = null;
    } catch (e) {
      // Log any errors encountered during the database deletion process.
      logger.e("Error: $e");
    }
  }
}
