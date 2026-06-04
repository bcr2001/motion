import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:sqflite/sqflite.dart';

class TrackerDatabaseSchema {
  static const int version = 11;

  static const String mainCategoryTable = MotionDbTables.mainCategory;
  static const String subcategoryTable = MotionDbTables.subcategory;
  static const String experiencePointsTable = MotionDbTables.experiencePoints;
  static const List<String> triggerNames = [
    'update_experience_points',
    'update_experience_points_after_update',
    'update_experience_points_after_delete',
    'update_main_category',
    'update_main_category_after_update',
    'update_main_category_after_delete',
  ];

  static Future<void> create(Database db) async {
    await _createTables(db);
    await _createTriggers(db);
  }

  static Future<void> migrate(
      Database db, int oldVersion, int newVersion) async {
    await ensureSchema(db);
  }

  static Future<void> ensureSchema(Database db) async {
    await _createTables(db);
    await _ensureColumns(db);
    await _createTriggers(db);
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $mainCategoryTable(
        ${MotionDbColumns.date} TEXT,
        ${MotionDbColumns.education} REAL DEFAULT 0,
        ${MotionDbColumns.work} REAL DEFAULT 0,
        ${MotionDbColumns.skills} REAL DEFAULT 0,
        ${MotionDbColumns.entertainment} REAL DEFAULT 0,
        ${MotionDbColumns.selfDevelopment} REAL DEFAULT 0,
        ${MotionDbColumns.sleep} REAL DEFAULT 0,
        ${MotionDbColumns.currentLoggedInUser} TEXT,
        PRIMARY KEY (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser})
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $experiencePointsTable(
        ${MotionDbColumns.date} TEXT,
        ${MotionDbColumns.educationXp} INTEGER DEFAULT 0,
        ${MotionDbColumns.workXp} INTEGER DEFAULT 0,
        ${MotionDbColumns.skillsXp} INTEGER DEFAULT 0,
        ${MotionDbColumns.selfDevelopmentXp} INTEGER DEFAULT 0,
        ${MotionDbColumns.sleepXp} INTEGER DEFAULT 0,
        ${MotionDbColumns.currentLoggedInUser} TEXT,
        PRIMARY KEY (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser}),
        FOREIGN KEY (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser})
        REFERENCES $mainCategoryTable(${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser})
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $subcategoryTable(
        ${MotionDbColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        ${MotionDbColumns.date} TEXT,
        ${MotionDbColumns.mainCategoryName} TEXT,
        ${MotionDbColumns.subcategoryName} TEXT,
        ${MotionDbColumns.timeRecorded} TEXT,
        ${MotionDbColumns.timeSpent} REAL DEFAULT 0,
        ${MotionDbColumns.currentLoggedInUser} TEXT,
        FOREIGN KEY (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser})
        REFERENCES $mainCategoryTable(${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser})
      )
    ''');
  }

  static Future<void> _ensureColumns(Database db) async {
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.date, 'TEXT');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.education, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.work, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.skills, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.entertainment, 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, mainCategoryTable,
        MotionDbColumns.selfDevelopment, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.sleep, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, mainCategoryTable, MotionDbColumns.currentLoggedInUser, 'TEXT');

    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.date, 'TEXT');
    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.mainCategoryName, 'TEXT');
    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.subcategoryName, 'TEXT');
    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.timeRecorded, 'TEXT');
    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.timeSpent, 'REAL DEFAULT 0');
    await _addColumnIfMissing(
        db, subcategoryTable, MotionDbColumns.currentLoggedInUser, 'TEXT');

    await _addColumnIfMissing(
        db, experiencePointsTable, MotionDbColumns.date, 'TEXT');
    await _addColumnIfMissing(db, experiencePointsTable,
        MotionDbColumns.educationXp, 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(
        db, experiencePointsTable, MotionDbColumns.workXp, 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, experiencePointsTable,
        MotionDbColumns.skillsXp, 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, experiencePointsTable,
        MotionDbColumns.selfDevelopmentXp, 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, experiencePointsTable,
        MotionDbColumns.sleepXp, 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(
        db, experiencePointsTable, MotionDbColumns.currentLoggedInUser, 'TEXT');
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnExists = columns.any((column) => column['name'] == columnName);

    if (!columnExists) {
      await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
    }
  }

  static Future<void> _createTriggers(Database db) async {
    await _dropTriggers(db);

    await db.execute('''
      CREATE TRIGGER update_experience_points
      AFTER INSERT ON $subcategoryTable
      BEGIN
        UPDATE $experiencePointsTable
        SET ${_experiencePointAssignments('NEW')}
        WHERE ${_rowMatch('NEW')};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER update_experience_points_after_update
      AFTER UPDATE ON $subcategoryTable
      BEGIN
        UPDATE $experiencePointsTable
        SET ${_experiencePointAssignments('OLD')}
        WHERE ${_rowMatch('OLD')};

        UPDATE $experiencePointsTable
        SET ${_experiencePointAssignments('NEW')}
        WHERE ${_rowMatch('NEW')};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER update_experience_points_after_delete
      AFTER DELETE ON $subcategoryTable
      BEGIN
        UPDATE $experiencePointsTable
        SET ${_experiencePointAssignments('OLD')}
        WHERE ${_rowMatch('OLD')};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER update_main_category
      AFTER INSERT ON $subcategoryTable
      BEGIN
        UPDATE $mainCategoryTable
        SET ${_mainCategoryAssignments('NEW')}
        WHERE ${_rowMatch('NEW')};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER update_main_category_after_update
      AFTER UPDATE ON $subcategoryTable
      BEGIN
        UPDATE $mainCategoryTable
        SET ${_mainCategoryAssignments('OLD')}
        WHERE ${_rowMatch('OLD')};

        UPDATE $mainCategoryTable
        SET ${_mainCategoryAssignments('NEW')}
        WHERE ${_rowMatch('NEW')};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER update_main_category_after_delete
      AFTER DELETE ON $subcategoryTable
      BEGIN
        UPDATE $mainCategoryTable
        SET ${_mainCategoryAssignments('OLD')}
        WHERE ${_rowMatch('OLD')};
      END;
    ''');
  }

  static Future<void> _dropTriggers(Database db) async {
    for (final triggerName in triggerNames) {
      await db.execute('DROP TRIGGER IF EXISTS $triggerName');
    }
  }

  static String _experiencePointAssignments(String rowAlias) {
    return '''
          ${MotionDbColumns.educationXp} = (${_standardXpFor(MotionCategories.education, rowAlias)}),
          ${MotionDbColumns.workXp} = (${_workXpFor(rowAlias)}),
          ${MotionDbColumns.skillsXp} = (${_standardXpFor(MotionCategories.skills, rowAlias)}),
          ${MotionDbColumns.selfDevelopmentXp} = (${_selfDevelopmentXpFor(rowAlias)}),
          ${MotionDbColumns.sleepXp} = (${_sleepXpFor(rowAlias)})
    ''';
  }

  static String _standardXpFor(String category, String rowAlias) {
    return '''
      SELECT CASE
        WHEN CAST(total / 15 AS INTEGER) > 20 THEN 20
        ELSE CAST(total / 15 AS INTEGER)
      END
      FROM (${_trackedTotal(category, rowAlias)})
    ''';
  }

  static String _workXpFor(String rowAlias) {
    return '''
      SELECT CASE
        WHEN CAST(total / 15 AS INTEGER) > 25 THEN 25
        ELSE CAST(total / 15 AS INTEGER)
      END
      FROM (${_trackedTotal(MotionCategories.work, rowAlias)})
    ''';
  }

  static String _selfDevelopmentXpFor(String rowAlias) {
    return '''
      SELECT CASE
        WHEN CAST(total / 15 AS INTEGER) > 20 THEN 20
        ELSE CAST(total / 15 AS INTEGER)
      END
      FROM (${_trackedTotal(MotionCategories.selfDevelopment, rowAlias)})
    ''';
  }

  static String _sleepXpFor(String rowAlias) {
    return '''
      SELECT CASE
        WHEN total < 300 THEN 0
        WHEN total < 360 THEN 8
        WHEN total < 420 THEN 15
        WHEN total <= 540 THEN 25
        WHEN total <= 600 THEN 15
        ELSE 5
      END
      FROM (${_trackedTotal(MotionCategories.sleep, rowAlias)})
    ''';
  }

  static String _mainCategoryAssignments(String rowAlias) {
    return '''
          ${MotionDbColumns.education} = (${_categoryTotal(MotionCategories.education, rowAlias)}),
          ${MotionDbColumns.work} = (${_categoryTotal(MotionCategories.work, rowAlias)}),
          ${MotionDbColumns.skills} = (${_categoryTotal(MotionCategories.skills, rowAlias)}),
          ${MotionDbColumns.entertainment} = (${_categoryTotal(MotionCategories.entertainment, rowAlias)}),
          ${MotionDbColumns.selfDevelopment} = (${_categoryTotal(MotionCategories.selfDevelopment, rowAlias)}),
          ${MotionDbColumns.sleep} = (${_categoryTotal(MotionCategories.sleep, rowAlias)})
    ''';
  }

  static String _categoryTotal(String category, String rowAlias) {
    return '''
      SELECT total
      FROM (${_trackedTotal(category, rowAlias)})
    ''';
  }

  static String _trackedTotal(String category, String rowAlias) {
    return '''
      SELECT COALESCE(SUM(${MotionDbColumns.timeSpent}), 0) AS total
      FROM $subcategoryTable
      WHERE ${MotionDbColumns.mainCategoryName} = '$category'
        AND ${MotionDbColumns.date} = $rowAlias.${MotionDbColumns.date}
        AND ${MotionDbColumns.currentLoggedInUser} =
            $rowAlias.${MotionDbColumns.currentLoggedInUser}
    ''';
  }

  static String _rowMatch(String rowAlias) {
    return '''
      ${MotionDbColumns.date} = $rowAlias.${MotionDbColumns.date}
      AND ${MotionDbColumns.currentLoggedInUser} =
          $rowAlias.${MotionDbColumns.currentLoggedInUser}
    ''';
  }
}
