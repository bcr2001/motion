import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

enum MotionCsvFileType {
  mainCategory,
  subcategory,
  assigner,
}

class MotionCsvDataTransfer {
  MotionCsvDataTransfer({
    TrackerDatabaseHelper? trackerDb,
    AssignerDatabaseHelper? assignerDb,
  })  : _trackerDb = trackerDb ?? TrackerDatabaseHelper(),
        _assignerDb = assignerDb ?? AssignerDatabaseHelper();

  final TrackerDatabaseHelper _trackerDb;
  final AssignerDatabaseHelper _assignerDb;
  static const MethodChannel _downloadsChannel =
      MethodChannel('motion/downloads');

  Future<String> exportAllToDownloads({required String currentUser}) async {
    if (Platform.isAndroid) {
      return _exportAllToAndroidDownloads(currentUser);
    }

    final downloadsDirectory = await _downloadsDirectory();
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: downloadsDirectory,
    );
  }

  Future<String> _exportAllToAndroidDownloads(String currentUser) async {
    await _writeAndroidCsvFile(
      fileName: 'main_category.csv',
      rows: await _mainCategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: 'subcategory.csv',
      rows: await _subcategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: 'to_assign.csv',
      rows: await _assignerRows(currentUser),
    );

    return 'Downloads';
  }

  Future<String> exportAllToDirectory({
    required String currentUser,
    required String directoryPath,
  }) async {
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: Directory(directoryPath),
    );
  }

  Future<String> _exportAllToDirectory({
    required String currentUser,
    required Directory directory,
  }) async {
    await directory.create(recursive: true);

    await _writeCsvFile(
      directory: directory,
      fileName: 'main_category.csv',
      rows: await _mainCategoryRows(currentUser),
    );
    await _writeCsvFile(
      directory: directory,
      fileName: 'subcategory.csv',
      rows: await _subcategoryRows(currentUser),
    );
    await _writeCsvFile(
      directory: directory,
      fileName: 'to_assign.csv',
      rows: await _assignerRows(currentUser),
    );

    return directory.path;
  }

  Future<int> importCsv({
    required MotionCsvFileType fileType,
    required String filePath,
    required String currentUser,
  }) async {
    final csvRows = await _readCsvRows(filePath);
    if (csvRows.length <= 1) return 0;

    switch (fileType) {
      case MotionCsvFileType.mainCategory:
        return _importMainCategory(csvRows, currentUser);
      case MotionCsvFileType.subcategory:
        return _importSubcategory(csvRows, currentUser);
      case MotionCsvFileType.assigner:
        return _importAssigner(csvRows, currentUser);
    }
  }

  Future<int> _importMainCategory(
    List<List<dynamic>> csvRows,
    String currentUser,
  ) async {
    final db = await _trackerDb.database;
    final headers = _headers(csvRows);
    var importedRows = 0;

    await db.transaction((txn) async {
      await txn.delete(
        MotionDbTables.mainCategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );

      for (final row in csvRows.skip(1)) {
        final rowMap = _rowMap(headers, row);
        final date = _normalizeDate(rowMap[MotionDbColumns.date]);
        if (date.isEmpty) continue;

        await txn.insert(
          MotionDbTables.mainCategory,
          {
            MotionDbColumns.date: date,
            MotionDbColumns.education:
                _parseDouble(rowMap[MotionDbColumns.education]),
            MotionDbColumns.work: _parseDouble(rowMap[MotionDbColumns.work]),
            MotionDbColumns.skills: _parseDouble(
                _firstValue(rowMap, [MotionDbColumns.skills, 'skill'])),
            MotionDbColumns.entertainment:
                _parseDouble(rowMap[MotionDbColumns.entertainment]),
            MotionDbColumns.selfDevelopment:
                _parseDouble(rowMap[MotionDbColumns.selfDevelopment]),
            MotionDbColumns.sleep: _parseDouble(rowMap[MotionDbColumns.sleep]),
            MotionDbColumns.currentLoggedInUser: currentUser,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        importedRows++;
      }
    });

    await _backfillXp(currentUser);
    return importedRows;
  }

  Future<int> _importSubcategory(
    List<List<dynamic>> csvRows,
    String currentUser,
  ) async {
    final db = await _trackerDb.database;
    final headers = _headers(csvRows);
    var importedRows = 0;

    await db.transaction((txn) async {
      await txn.delete(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );

      for (final row in csvRows.skip(1)) {
        final rowMap = _rowMap(headers, row);
        final date = _normalizeDate(rowMap[MotionDbColumns.date]);
        if (date.isEmpty) continue;

        await _ensureDailyRows(txn, currentUser, date);
        await txn.insert(MotionDbTables.subcategory, {
          MotionDbColumns.date: date,
          MotionDbColumns.mainCategoryName:
              rowMap[MotionDbColumns.mainCategoryName] ?? '',
          MotionDbColumns.subcategoryName:
              rowMap[MotionDbColumns.subcategoryName] ?? '',
          MotionDbColumns.timeSpent:
              _parseDouble(rowMap[MotionDbColumns.timeSpent]),
          MotionDbColumns.currentLoggedInUser: currentUser,
        });

        importedRows++;
      }
    });

    await _backfillXp(currentUser);
    return importedRows;
  }

  Future<int> _importAssigner(
    List<List<dynamic>> csvRows,
    String currentUser,
  ) async {
    final db = await _assignerDb.database;
    final headers = _headers(csvRows);
    var importedRows = 0;

    await db.transaction((txn) async {
      await txn.delete(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );

      for (final row in csvRows.skip(1)) {
        final rowMap = _rowMap(headers, row);
        await txn.insert(
          MotionDbTables.assigner,
          {
            MotionDbColumns.currentLoggedInUser: currentUser,
            MotionDbColumns.subcategoryName:
                rowMap[MotionDbColumns.subcategoryName] ?? '',
            MotionDbColumns.mainCategoryName:
                rowMap[MotionDbColumns.mainCategoryName] ?? '',
            MotionDbColumns.isActive:
                _parseInt(rowMap[MotionDbColumns.isActive]),
            MotionDbColumns.isArchive:
                _parseInt(rowMap[MotionDbColumns.isArchive]),
            MotionDbColumns.dateCreated:
                _normalizeDate(rowMap[MotionDbColumns.dateCreated]),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        importedRows++;
      }
    });

    return importedRows;
  }

  Future<List<List<dynamic>>> _mainCategoryRows(String currentUser) async {
    final db = await _trackerDb.database;
    final rows = await db.query(
      MotionDbTables.mainCategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy: MotionDbColumns.date,
    );

    return [
      [
        MotionDbColumns.date,
        MotionDbColumns.education,
        MotionDbColumns.work,
        MotionDbColumns.skills,
        MotionDbColumns.entertainment,
        MotionDbColumns.selfDevelopment,
        MotionDbColumns.sleep,
        MotionDbColumns.currentLoggedInUser,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.date],
            row[MotionDbColumns.education],
            row[MotionDbColumns.work],
            row[MotionDbColumns.skills],
            row[MotionDbColumns.entertainment],
            row[MotionDbColumns.selfDevelopment],
            row[MotionDbColumns.sleep],
            row[MotionDbColumns.currentLoggedInUser],
          ]),
    ];
  }

  Future<List<List<dynamic>>> _subcategoryRows(String currentUser) async {
    final db = await _trackerDb.database;
    final rows = await db.query(
      MotionDbTables.subcategory,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy:
          '${MotionDbColumns.date}, ${MotionDbColumns.mainCategoryName}, ${MotionDbColumns.subcategoryName}',
    );

    return [
      [
        MotionDbColumns.date,
        MotionDbColumns.mainCategoryName,
        MotionDbColumns.subcategoryName,
        MotionDbColumns.timeSpent,
        MotionDbColumns.currentLoggedInUser,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.date],
            row[MotionDbColumns.mainCategoryName],
            row[MotionDbColumns.subcategoryName],
            row[MotionDbColumns.timeSpent],
            row[MotionDbColumns.currentLoggedInUser],
          ]),
    ];
  }

  Future<List<List<dynamic>>> _assignerRows(String currentUser) async {
    final db = await _assignerDb.database;
    final rows = await db.query(
      MotionDbTables.assigner,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
      orderBy:
          '${MotionDbColumns.mainCategoryName}, ${MotionDbColumns.subcategoryName}',
    );

    return [
      [
        MotionDbColumns.currentLoggedInUser,
        MotionDbColumns.subcategoryName,
        MotionDbColumns.mainCategoryName,
        MotionDbColumns.isActive,
        MotionDbColumns.isArchive,
        MotionDbColumns.dateCreated,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.currentLoggedInUser],
            row[MotionDbColumns.subcategoryName],
            row[MotionDbColumns.mainCategoryName],
            row[MotionDbColumns.isActive],
            row[MotionDbColumns.isArchive],
            row[MotionDbColumns.dateCreated],
          ]),
    ];
  }

  Future<void> _writeCsvFile({
    required Directory directory,
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = const ListToCsvConverter().convert(rows);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(csv);
  }

  Future<void> _writeAndroidCsvFile({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = const ListToCsvConverter().convert(rows);
    await _downloadsChannel.invokeMethod<String>('saveCsv', {
      'fileName': fileName,
      'content': csv,
    });
  }

  Future<List<List<dynamic>>> _readCsvRows(String filePath) async {
    final csvString = await File(filePath).readAsString();
    return const CsvToListConverter().convert(csvString);
  }

  List<String> _headers(List<List<dynamic>> csvRows) {
    return csvRows.first.map((value) => value.toString().trim()).toList();
  }

  Map<String, String> _rowMap(List<String> headers, List<dynamic> row) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      map[headers[i]] = row[i].toString().trim();
    }
    return map;
  }

  String? _firstValue(Map<String, String> rowMap, List<String> keys) {
    for (final key in keys) {
      if (rowMap.containsKey(key)) return rowMap[key];
    }
    return null;
  }

  double _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return 0.0;
    final normalized = value.replaceAll('mins', '').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  int _parseInt(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return int.tryParse(value.trim()) ?? 0;
  }

  String _normalizeDate(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) {
      return DateFormat('yyyy-MM-dd').format(isoDate);
    }

    for (final pattern in ['M/d/yyyy', 'd/M/yyyy']) {
      try {
        return DateFormat('yyyy-MM-dd')
            .format(DateFormat(pattern).parseStrict(trimmed));
      } catch (_) {
        continue;
      }
    }

    return '';
  }

  Future<Directory> _downloadsDirectory() async {
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        await downloadsDirectory.create(recursive: true);
        return downloadsDirectory;
      }
    } catch (_) {
      // Some Android devices do not expose Downloads through path_provider.
    }

    final androidDownloads = Directory('/storage/emulated/0/Download');
    if (await androidDownloads.exists()) return androidDownloads;

    throw const FileSystemException('Downloads directory is unavailable.');
  }

  Future<void> _ensureDailyRows(
    Transaction txn,
    String currentUser,
    String date,
  ) async {
    await txn.insert(
      MotionDbTables.mainCategory,
      {
        MotionDbColumns.date: date,
        MotionDbColumns.education: 0.0,
        MotionDbColumns.work: 0.0,
        MotionDbColumns.skills: 0.0,
        MotionDbColumns.entertainment: 0.0,
        MotionDbColumns.selfDevelopment: 0.0,
        MotionDbColumns.sleep: 0.0,
        MotionDbColumns.currentLoggedInUser: currentUser,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await txn.insert(
      MotionDbTables.experiencePoints,
      {
        MotionDbColumns.date: date,
        MotionDbColumns.educationXp: 0,
        MotionDbColumns.workXp: 0,
        MotionDbColumns.skillsXp: 0,
        MotionDbColumns.selfDevelopmentXp: 0,
        MotionDbColumns.sleepXp: 0,
        MotionDbColumns.currentLoggedInUser: currentUser,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _backfillXp(String currentUser) async {
    final db = await _trackerDb.database;
    await db.execute('''
      INSERT OR IGNORE INTO ${MotionDbTables.experiencePoints}
        (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser},
        ${MotionDbColumns.educationXp}, ${MotionDbColumns.workXp},
        ${MotionDbColumns.skillsXp}, ${MotionDbColumns.selfDevelopmentXp},
        ${MotionDbColumns.sleepXp})
      SELECT ${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser},
        0, 0, 0, 0, 0
      FROM ${MotionDbTables.mainCategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?;
    ''', [currentUser]);
  }
}
