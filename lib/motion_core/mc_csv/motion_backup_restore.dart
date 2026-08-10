import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MotionBackupRestorePreview {
  const MotionBackupRestorePreview({
    required this.trackingRows,
    required this.dailyTotalRows,
    required this.assignedRows,
    required this.firstTrackedDate,
    required this.lastTrackedDate,
  });

  final int trackingRows;
  final int dailyTotalRows;
  final int assignedRows;
  final String? firstTrackedDate;
  final String? lastTrackedDate;

  int get totalRows => trackingRows + dailyTotalRows + assignedRows;
}

class MotionBackupRestoreResult {
  const MotionBackupRestoreResult({
    required this.trackingRows,
    required this.dailyTotalRows,
    required this.experiencePointRows,
    required this.assignedRows,
  });

  final int trackingRows;
  final int dailyTotalRows;
  final int experiencePointRows;
  final int assignedRows;
}

class MotionValidatedBackup {
  const MotionValidatedBackup._({
    required this.currentUser,
    required this.preview,
    required List<Map<String, Object?>> mainCategoryRows,
    required List<Map<String, Object?>> subcategoryRows,
    required List<Map<String, Object?>> assignerRows,
  })  : _mainCategoryRows = mainCategoryRows,
        _subcategoryRows = subcategoryRows,
        _assignerRows = assignerRows;

  final String currentUser;
  final MotionBackupRestorePreview preview;
  final List<Map<String, Object?>> _mainCategoryRows;
  final List<Map<String, Object?>> _subcategoryRows;
  final List<Map<String, Object?>> _assignerRows;
}

class MotionBackupRestoreService {
  MotionBackupRestoreService({
    TrackerDatabaseHelper? trackerDb,
    AssignerDatabaseHelper? assignerDb,
    Future<Database> Function()? trackerDatabase,
    Future<Database> Function()? assignerDatabase,
  })  : _trackerDatabase = trackerDatabase ??
            (() => (trackerDb ?? TrackerDatabaseHelper()).database),
        _assignerDatabase = assignerDatabase ??
            (() => (assignerDb ?? AssignerDatabaseHelper()).database);

  static const int _maximumRowsPerFile = 500000;
  static const double _maximumMinutesPerDay = 1440.000001;

  static const List<String> _mainCategoryHeaders = [
    MotionDbColumns.date,
    MotionDbColumns.education,
    MotionDbColumns.work,
    MotionDbColumns.skills,
    MotionDbColumns.entertainment,
    MotionDbColumns.selfDevelopment,
    MotionDbColumns.sleep,
    MotionDbColumns.currentLoggedInUser,
  ];
  static const List<String> _subcategoryHeaders = [
    MotionDbColumns.date,
    MotionDbColumns.mainCategoryName,
    MotionDbColumns.subcategoryName,
    MotionDbColumns.timeSpent,
    MotionDbColumns.currentLoggedInUser,
  ];
  static const List<String> _assignerHeaders = [
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.subcategoryName,
    MotionDbColumns.mainCategoryName,
    MotionDbColumns.isActive,
    MotionDbColumns.isArchive,
    MotionDbColumns.dateCreated,
    MotionDbColumns.isStreakActive,
    MotionDbColumns.streakType,
    MotionDbColumns.streakTargetMinutes,
    MotionDbColumns.streakStartDate,
  ];
  static const Set<String> _mainCategories = {
    MotionCategories.education,
    MotionCategories.work,
    MotionCategories.skills,
    MotionCategories.entertainment,
    MotionCategories.selfDevelopment,
    MotionCategories.sleep,
  };

  final Future<Database> Function() _trackerDatabase;
  final Future<Database> Function() _assignerDatabase;

  MotionValidatedBackup validateBackup({
    required List<MotionCsvBackupFile> files,
    required String currentUser,
  }) {
    if (currentUser.trim().isEmpty) {
      throw StateError('Your Motion account is still loading.');
    }

    final backupFiles = _classifyBackupFiles(files);
    final mainCategoryRows = _parseRows(
      backupFiles[_BackupFileKind.mainCategory]!,
      _mainCategoryHeaders,
    );
    final subcategoryRows = _parseRows(
      backupFiles[_BackupFileKind.subcategory]!,
      _subcategoryHeaders,
    );
    final assignerRows = _parseRows(
      backupFiles[_BackupFileKind.assigner]!,
      _assignerHeaders,
    );

    final validatedMainRows = _validateMainCategoryRows(
      mainCategoryRows,
      currentUser,
    );
    final validatedSubcategoryRows = _validateSubcategoryRows(
      subcategoryRows,
      currentUser,
    );
    final validatedAssignerRows = _validateAssignerRows(
      assignerRows,
      currentUser,
    );

    if (validatedSubcategoryRows.isEmpty && validatedAssignerRows.isEmpty) {
      throw StateError(
          'The selected Motion backup contains no restorable data.');
    }

    final dates = validatedSubcategoryRows
        .map((row) => row[MotionDbColumns.date]! as String)
        .toList()
      ..sort();

    return MotionValidatedBackup._(
      currentUser: currentUser,
      preview: MotionBackupRestorePreview(
        trackingRows: validatedSubcategoryRows.length,
        dailyTotalRows: validatedMainRows.length,
        assignedRows: validatedAssignerRows.length,
        firstTrackedDate: dates.isEmpty ? null : dates.first,
        lastTrackedDate: dates.isEmpty ? null : dates.last,
      ),
      mainCategoryRows: validatedMainRows,
      subcategoryRows: validatedSubcategoryRows,
      assignerRows: validatedAssignerRows,
    );
  }

  Future<MotionBackupRestoreResult> restoreBackup({
    required MotionValidatedBackup backup,
    required String currentUser,
  }) async {
    if (backup.currentUser != currentUser) {
      throw StateError(
        'The validated backup does not belong to the current Motion account.',
      );
    }

    final trackerDb = await _trackerDatabase();
    final assignerDb = await _assignerDatabase();
    final previousAssignerRows = await assignerDb.query(
      MotionDbTables.assigner,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
    );

    await _replaceAssignerRows(
      assignerDb,
      currentUser: currentUser,
      rows: backup._assignerRows,
    );

    try {
      await trackerDb.transaction((txn) async {
        await txn.delete(
          MotionDbTables.activeTimerSession,
          where: '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [currentUser],
        );
        await txn.delete(
          MotionDbTables.subcategory,
          where: '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [currentUser],
        );
        await txn.delete(
          MotionDbTables.experiencePoints,
          where: '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [currentUser],
        );
        await txn.delete(
          MotionDbTables.mainCategory,
          where: '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [currentUser],
        );

        final restoredDates = <String>{
          ...backup._mainCategoryRows.map(
            (row) => row[MotionDbColumns.date]! as String,
          ),
          ...backup._subcategoryRows.map(
            (row) => row[MotionDbColumns.date]! as String,
          ),
        }.toList()
          ..sort();

        final dailyRowsBatch = txn.batch();
        for (final date in restoredDates) {
          dailyRowsBatch.insert(
            MotionDbTables.mainCategory,
            {
              MotionDbColumns.date: date,
              MotionDbColumns.currentLoggedInUser: currentUser,
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          dailyRowsBatch.insert(
            MotionDbTables.experiencePoints,
            {
              MotionDbColumns.date: date,
              MotionDbColumns.currentLoggedInUser: currentUser,
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        await dailyRowsBatch.commit(noResult: true);

        final trackingBatch = txn.batch();
        for (final row in backup._subcategoryRows) {
          trackingBatch.insert(
            MotionDbTables.subcategory,
            row,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        await trackingBatch.commit(noResult: true);
      });
    } catch (_) {
      await _replaceAssignerRows(
        assignerDb,
        currentUser: currentUser,
        rows: previousAssignerRows,
        preserveIds: true,
      );
      rethrow;
    }

    final restoredDates = <String>{
      ...backup._mainCategoryRows.map(
        (row) => row[MotionDbColumns.date]! as String,
      ),
      ...backup._subcategoryRows.map(
        (row) => row[MotionDbColumns.date]! as String,
      ),
    };

    return MotionBackupRestoreResult(
      trackingRows: backup._subcategoryRows.length,
      dailyTotalRows: restoredDates.length,
      experiencePointRows: restoredDates.length,
      assignedRows: backup._assignerRows.length,
    );
  }

  Map<_BackupFileKind, MotionCsvBackupFile> _classifyBackupFiles(
    List<MotionCsvBackupFile> files,
  ) {
    if (files.length != _BackupFileKind.values.length) {
      throw StateError(
        'Select exactly three files from one Motion backup: '
        'main_category.csv, subcategory.csv, and to_assign.csv.',
      );
    }

    final classified = <_BackupFileKind, MotionCsvBackupFile>{};
    for (final file in files) {
      final kind = _backupFileKind(file);
      if (classified.containsKey(kind)) {
        throw StateError(
          'The selected backup contains a duplicate ${kind.label} file.',
        );
      }
      classified[kind] = file;
    }

    for (final kind in _BackupFileKind.values) {
      if (!classified.containsKey(kind)) {
        throw StateError('The selected backup is missing ${kind.label}.');
      }
    }
    return classified;
  }

  _BackupFileKind _backupFileKind(MotionCsvBackupFile file) {
    final name = p.basename(file.fileName).toLowerCase();
    final kindFromName = switch (name) {
      final value when value.endsWith('main_category.csv') =>
        _BackupFileKind.mainCategory,
      final value when value.endsWith('subcategory.csv') =>
        _BackupFileKind.subcategory,
      final value when value.endsWith('to_assign.csv') =>
        _BackupFileKind.assigner,
      _ => null,
    };
    if (kindFromName != null) return kindFromName;

    try {
      final rows = const CsvToListConverter().convert(file.content);
      if (rows.isNotEmpty) {
        final headers = rows.first
            .map((value) => value.toString().trim().replaceFirst('\ufeff', ''))
            .toList();
        if (_listsEqual(headers, _mainCategoryHeaders)) {
          return _BackupFileKind.mainCategory;
        }
        if (_listsEqual(headers, _subcategoryHeaders)) {
          return _BackupFileKind.subcategory;
        }
        if (_listsEqual(headers, _assignerHeaders)) {
          return _BackupFileKind.assigner;
        }
      }
    } on FormatException {
      // _parseRows reports the detailed CSV error after classification.
    }

    throw StateError(
      '${file.fileName} is not a recognized Motion backup file.',
    );
  }

  List<Map<String, String>> _parseRows(
    MotionCsvBackupFile file,
    List<String> expectedHeaders,
  ) {
    late final List<List<dynamic>> csvRows;
    try {
      csvRows = const CsvToListConverter().convert(file.content);
    } on FormatException catch (error) {
      throw StateError('${file.fileName} is not valid CSV: ${error.message}');
    }
    if (csvRows.isEmpty) {
      throw StateError('${file.fileName} is empty.');
    }

    final actualHeaders = csvRows.first
        .map((value) => value.toString().trim().replaceFirst('\ufeff', ''))
        .toList();
    if (!_listsEqual(actualHeaders, expectedHeaders)) {
      throw StateError(
        '${file.fileName} does not have the expected Motion backup columns.',
      );
    }

    final dataRows = <Map<String, String>>[];
    for (var rowIndex = 1; rowIndex < csvRows.length; rowIndex++) {
      final values = csvRows[rowIndex];
      if (values.every((value) => value.toString().trim().isEmpty)) continue;
      if (values.length != expectedHeaders.length) {
        throw StateError(
          '${file.fileName}, row ${rowIndex + 1}, has '
          '${values.length} values instead of ${expectedHeaders.length}.',
        );
      }
      dataRows.add({
        for (var column = 0; column < expectedHeaders.length; column++)
          expectedHeaders[column]: values[column].toString().trim(),
      });
      if (dataRows.length > _maximumRowsPerFile) {
        throw StateError(
            '${file.fileName} contains too many rows to restore safely.');
      }
    }
    return dataRows;
  }

  List<Map<String, Object?>> _validateMainCategoryRows(
    List<Map<String, String>> rows,
    String currentUser,
  ) {
    final dates = <String>{};
    return rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      final date = _strictDate(
        row[MotionDbColumns.date],
        fileName: 'main_category.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.date,
      );
      if (!dates.add(date)) {
        throw StateError('main_category.csv contains duplicate date $date.');
      }
      _validateUser(row, currentUser, 'main_category.csv', rowNumber);

      final result = <String, Object?>{
        MotionDbColumns.date: date,
        MotionDbColumns.currentLoggedInUser: currentUser,
      };
      var dailyTotal = 0.0;
      for (final column in _mainCategoryHeaders.sublist(1, 7)) {
        final value = _nonNegativeDouble(
          row[column],
          fileName: 'main_category.csv',
          rowNumber: rowNumber,
          columnName: column,
        );
        result[column] = value;
        dailyTotal += value;
      }
      if (dailyTotal > _maximumMinutesPerDay) {
        throw StateError(
          'main_category.csv, row $rowNumber, exceeds 24 tracked hours.',
        );
      }
      return result;
    }).toList(growable: false);
  }

  List<Map<String, Object?>> _validateSubcategoryRows(
    List<Map<String, String>> rows,
    String currentUser,
  ) {
    final dailyTotals = <String, double>{};
    final validatedRows = rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      final date = _strictDate(
        row[MotionDbColumns.date],
        fileName: 'subcategory.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.date,
      );
      final mainCategory = _mainCategory(
        row[MotionDbColumns.mainCategoryName],
        fileName: 'subcategory.csv',
        rowNumber: rowNumber,
      );
      final subcategory = _requiredText(
        row[MotionDbColumns.subcategoryName],
        fileName: 'subcategory.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.subcategoryName,
      );
      final minutes = _nonNegativeDouble(
        row[MotionDbColumns.timeSpent],
        fileName: 'subcategory.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.timeSpent,
      );
      _validateUser(row, currentUser, 'subcategory.csv', rowNumber);

      dailyTotals[date] = (dailyTotals[date] ?? 0) + minutes;
      if (dailyTotals[date]! > _maximumMinutesPerDay) {
        throw StateError(
          'subcategory.csv exceeds 24 tracked hours on $date.',
        );
      }

      return <String, Object?>{
        MotionDbColumns.date: date,
        MotionDbColumns.mainCategoryName: mainCategory,
        MotionDbColumns.subcategoryName: subcategory,
        MotionDbColumns.timeSpent: minutes,
        MotionDbColumns.currentLoggedInUser: currentUser,
      };
    }).toList(growable: false);
    return validatedRows;
  }

  List<Map<String, Object?>> _validateAssignerRows(
    List<Map<String, String>> rows,
    String currentUser,
  ) {
    return rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(row, currentUser, 'to_assign.csv', rowNumber);
      final subcategory = _requiredText(
        row[MotionDbColumns.subcategoryName],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.subcategoryName,
      );
      final mainCategory = _mainCategory(
        row[MotionDbColumns.mainCategoryName],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
      );
      final isActive = _binaryInt(
        row[MotionDbColumns.isActive],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.isActive,
      );
      final isArchive = _binaryInt(
        row[MotionDbColumns.isArchive],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.isArchive,
      );
      final isStreakActive = _binaryInt(
        row[MotionDbColumns.isStreakActive],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.isStreakActive,
      );
      final dateCreated = _normalizedLegacyDate(
        row[MotionDbColumns.dateCreated],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.dateCreated,
      );
      final streakStartDate = _optionalNormalizedLegacyDate(
        row[MotionDbColumns.streakStartDate],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.streakStartDate,
      );
      final streakTargetMinutes = _nonNegativeDouble(
        row[MotionDbColumns.streakTargetMinutes],
        fileName: 'to_assign.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.streakTargetMinutes,
      );
      if (streakTargetMinutes > 1440) {
        throw StateError(
          'to_assign.csv, row $rowNumber, has a streak target over 24 hours.',
        );
      }

      return <String, Object?>{
        MotionDbColumns.currentLoggedInUser: currentUser,
        MotionDbColumns.subcategoryName: subcategory,
        MotionDbColumns.mainCategoryName: mainCategory,
        MotionDbColumns.isActive: isActive,
        MotionDbColumns.isArchive: isArchive,
        MotionDbColumns.dateCreated: dateCreated,
        MotionDbColumns.isStreakActive: isStreakActive,
        MotionDbColumns.streakType:
            row[MotionDbColumns.streakType]?.trim() ?? '',
        MotionDbColumns.streakTargetMinutes: streakTargetMinutes,
        MotionDbColumns.streakStartDate: streakStartDate,
      };
    }).toList(growable: false);
  }

  Future<void> _replaceAssignerRows(
    Database db, {
    required String currentUser,
    required List<Map<String, Object?>> rows,
    bool preserveIds = false,
  }) {
    return db.transaction((txn) async {
      await txn.delete(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      final batch = txn.batch();
      for (final originalRow in rows) {
        final row = Map<String, Object?>.from(originalRow);
        if (!preserveIds) row.remove(MotionDbColumns.id);
        batch.insert(
          MotionDbTables.assigner,
          row,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  void _validateUser(
    Map<String, String> row,
    String currentUser,
    String fileName,
    int rowNumber,
  ) {
    final backupUser = _requiredText(
      row[MotionDbColumns.currentLoggedInUser],
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: MotionDbColumns.currentLoggedInUser,
    );
    if (backupUser != currentUser) {
      throw StateError(
        '$fileName belongs to a different Motion account. '
        'Sign in to the account that created this backup.',
      );
    }
  }

  String _mainCategory(
    String? value, {
    required String fileName,
    required int rowNumber,
  }) {
    final category = _requiredText(
      value,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: MotionDbColumns.mainCategoryName,
    );
    if (!_mainCategories.contains(category)) {
      throw StateError(
        '$fileName, row $rowNumber, contains unknown main category "$category".',
      );
    }
    return category;
  }

  String _strictDate(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final date = _requiredText(
      value,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: columnName,
    );
    final parsed = MotionDateUtils.parseStoredDate(date);
    if (parsed == null || MotionDateUtils.formatDbDate(parsed) != date) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "$date". '
        'Motion backup dates must use yyyy-MM-dd.',
      );
    }
    return date;
  }

  String _normalizedLegacyDate(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final date = _requiredText(
      value,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: columnName,
    );
    final normalized = MotionDateUtils.normalizeStoredDate(date);
    if (normalized.isEmpty) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "$date".',
      );
    }
    return normalized;
  }

  String _optionalNormalizedLegacyDate(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final date = value?.trim() ?? '';
    if (date.isEmpty) return '';
    return _normalizedLegacyDate(
      date,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: columnName,
    );
  }

  String _requiredText(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      throw StateError(
        '$fileName, row $rowNumber, is missing $columnName.',
      );
    }
    return text;
  }

  double _nonNegativeDouble(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final text = value?.trim() ?? '';
    final parsed = double.tryParse(text);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "$text".',
      );
    }
    return math.max(0, parsed);
  }

  int _binaryInt(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);
    if (parsed != 0 && parsed != 1) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "$text".',
      );
    }
    return parsed!;
  }

  bool _listsEqual(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

enum _BackupFileKind {
  mainCategory('main_category.csv'),
  subcategory('subcategory.csv'),
  assigner('to_assign.csv');

  const _BackupFileKind(this.label);

  final String label;
}
