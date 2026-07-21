import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracking_time_policy.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

enum MotionCsvFileType {
  mainCategory,
  subcategory,
  assigner,
}

typedef MotionCsvImportProgressChanged = void Function(
  MotionCsvImportProgress progress,
);

class MotionCsvImportProgress {
  const MotionCsvImportProgress({
    required this.processedRows,
    required this.totalRows,
    required this.importedRows,
    required this.fileLabel,
  });

  final int processedRows;
  final int totalRows;
  final int importedRows;
  final String fileLabel;

  double get value => totalRows == 0 ? 0 : processedRows / totalRows;
}

class MotionDeletedDataSummary {
  const MotionDeletedDataSummary({
    required this.subcategoryRows,
    required this.mainCategoryRows,
    required this.experiencePointRows,
    required this.assignerRows,
    required this.activeTimerRows,
  });

  final int subcategoryRows;
  final int mainCategoryRows;
  final int experiencePointRows;
  final int assignerRows;
  final int activeTimerRows;

  int get totalRows =>
      subcategoryRows +
      mainCategoryRows +
      experiencePointRows +
      assignerRows +
      activeTimerRows;
}

class MotionDataSummary {
  const MotionDataSummary({
    required this.subcategoryRows,
    required this.mainCategoryRows,
    required this.experiencePointRows,
    required this.assignerRows,
    required this.activeTimerRows,
    required this.firstTrackedDate,
    required this.lastTrackedDate,
  });

  final int subcategoryRows;
  final int mainCategoryRows;
  final int experiencePointRows;
  final int assignerRows;
  final int activeTimerRows;
  final String? firstTrackedDate;
  final String? lastTrackedDate;

  int get totalRows =>
      subcategoryRows +
      mainCategoryRows +
      experiencePointRows +
      assignerRows +
      activeTimerRows;

  bool get hasExportableData => subcategoryRows > 0 || assignerRows > 0;
}

class MotionCsvPreview {
  const MotionCsvPreview({
    required this.fileName,
    required this.fileType,
    required this.totalRows,
    required this.validRows,
    required this.skippedRows,
    required this.firstDate,
    required this.lastDate,
  });

  final String fileName;
  final MotionCsvFileType fileType;
  final int totalRows;
  final int validRows;
  final int skippedRows;
  final String? firstDate;
  final String? lastDate;
}

class MotionCsvImportResult {
  const MotionCsvImportResult({
    required this.importedRows,
    required this.skippedRows,
    required this.rebuiltDailyRows,
  });

  final int importedRows;
  final int skippedRows;
  final int rebuiltDailyRows;
}

class MotionCsvBackupFile {
  const MotionCsvBackupFile({
    required this.fileName,
    required this.content,
  });

  final String fileName;
  final String content;
}

class MotionCsvDataTransfer {
  MotionCsvDataTransfer({
    TrackerDatabaseHelper? trackerDb,
    AssignerDatabaseHelper? assignerDb,
    Future<Database> Function()? trackerDatabase,
    Future<Database> Function()? assignerDatabase,
  })  : _trackerDatabase = trackerDatabase ??
            (() => (trackerDb ?? TrackerDatabaseHelper()).database),
        _assignerDatabase = assignerDatabase ??
            (() => (assignerDb ?? AssignerDatabaseHelper()).database);

  final Future<Database> Function() _trackerDatabase;
  final Future<Database> Function() _assignerDatabase;
  static const MethodChannel _downloadsChannel =
      MethodChannel('motion/downloads');

  Future<String> exportAllToDownloads({required String currentUser}) async {
    await _ensureHasExportableData(currentUser);

    if (Platform.isAndroid) {
      return _exportAllToAndroidDownloads(currentUser: currentUser);
    }

    final downloadsDirectory = await _downloadsDirectory();
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: downloadsDirectory,
    );
  }

  Future<String> exportBackupToDownloads({required String currentUser}) async {
    await _ensureHasExportableData(currentUser);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final prefix = 'motion_backup_${timestamp}_';

    if (Platform.isAndroid) {
      return _exportAllToAndroidDownloads(
        currentUser: currentUser,
        fileNamePrefix: prefix,
      );
    }

    final downloadsDirectory = await _downloadsDirectory();
    final backupDirectory = Directory(
      p.join(downloadsDirectory.path, 'motion_backup_$timestamp'),
    );
    return _exportAllToDirectory(
      currentUser: currentUser,
      directory: backupDirectory,
    );
  }

  Future<List<MotionCsvBackupFile>> backupFiles({
    required String currentUser,
  }) async {
    await _ensureHasExportableData(currentUser);

    return [
      MotionCsvBackupFile(
        fileName: 'main_category.csv',
        content:
            await _csvContentFromRows(await _mainCategoryRows(currentUser)),
      ),
      MotionCsvBackupFile(
        fileName: 'subcategory.csv',
        content: await _csvContentFromRows(await _subcategoryRows(currentUser)),
      ),
      MotionCsvBackupFile(
        fileName: 'to_assign.csv',
        content: await _csvContentFromRows(await _assignerRows(currentUser)),
      ),
    ];
  }

  Future<String> _exportAllToAndroidDownloads({
    required String currentUser,
    String fileNamePrefix = '',
  }) async {
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}main_category.csv',
      rows: await _mainCategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}subcategory.csv',
      rows: await _subcategoryRows(currentUser),
    );
    await _writeAndroidCsvFile(
      fileName: '${fileNamePrefix}to_assign.csv',
      rows: await _assignerRows(currentUser),
    );

    return 'Downloads';
  }

  Future<String> exportAllToDirectory({
    required String currentUser,
    required String directoryPath,
  }) async {
    await _ensureHasExportableData(currentUser);

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

  Future<MotionCsvPreview> previewCsv({
    required MotionCsvFileType fileType,
    required String filePath,
  }) async {
    final csvRows = await _readCsvRows(filePath);
    if (csvRows.isEmpty) {
      return MotionCsvPreview(
        fileName: p.basename(filePath),
        fileType: fileType,
        totalRows: 0,
        validRows: 0,
        skippedRows: 0,
        firstDate: null,
        lastDate: null,
      );
    }

    final headers = _headers(csvRows);
    switch (fileType) {
      case MotionCsvFileType.mainCategory:
        throw UnsupportedError(
          'main_category.csv is derived from subcategory.csv and is export-only.',
        );
      case MotionCsvFileType.subcategory:
        _requireHeaders(headers, [
          MotionDbColumns.date,
          MotionDbColumns.mainCategoryName,
          MotionDbColumns.subcategoryName,
          MotionDbColumns.timeSpent,
        ]);
        return _previewRows(
          filePath: filePath,
          fileType: fileType,
          csvRows: csvRows,
          headers: headers,
          isValidRow: (rowMap) {
            return _normalizeDate(rowMap[MotionDbColumns.date]).isNotEmpty &&
                (rowMap[MotionDbColumns.mainCategoryName] ?? '').isNotEmpty &&
                (rowMap[MotionDbColumns.subcategoryName] ?? '').isNotEmpty;
          },
          dateForRow: (rowMap) => _normalizeDate(rowMap[MotionDbColumns.date]),
        );
      case MotionCsvFileType.assigner:
        _requireHeaders(headers, [
          MotionDbColumns.subcategoryName,
          MotionDbColumns.mainCategoryName,
          MotionDbColumns.isActive,
          MotionDbColumns.dateCreated,
        ]);
        return _previewRows(
          filePath: filePath,
          fileType: fileType,
          csvRows: csvRows,
          headers: headers,
          isValidRow: (rowMap) {
            return (rowMap[MotionDbColumns.subcategoryName] ?? '').isNotEmpty &&
                (rowMap[MotionDbColumns.mainCategoryName] ?? '').isNotEmpty;
          },
          dateForRow: (rowMap) =>
              _normalizeDate(rowMap[MotionDbColumns.dateCreated]),
        );
    }
  }

  Future<MotionCsvImportResult> importCsv({
    required MotionCsvFileType fileType,
    required String filePath,
    required String currentUser,
    MotionCsvImportProgressChanged? onProgress,
  }) async {
    final csvRows = await _readCsvRows(filePath);
    if (csvRows.length <= 1) {
      return const MotionCsvImportResult(
        importedRows: 0,
        skippedRows: 0,
        rebuiltDailyRows: 0,
      );
    }

    switch (fileType) {
      case MotionCsvFileType.mainCategory:
        throw UnsupportedError(
          'main_category.csv is derived from subcategory.csv and is export-only.',
        );
      case MotionCsvFileType.subcategory:
        return _importSubcategory(
          csvRows,
          currentUser,
          onProgress: onProgress,
        );
      case MotionCsvFileType.assigner:
        return _importAssigner(
          csvRows,
          currentUser,
          onProgress: onProgress,
        );
    }
  }

  Future<MotionDeletedDataSummary> deleteAllDataForUser({
    required String currentUser,
  }) async {
    final trackerDb = await _trackerDatabase();
    final assignerDb = await _assignerDatabase();
    var subcategoryRows = 0;
    var mainCategoryRows = 0;
    var experiencePointRows = 0;
    var activeTimerRows = 0;

    await trackerDb.transaction((txn) async {
      activeTimerRows = await txn.delete(
        MotionDbTables.activeTimerSession,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      subcategoryRows = await txn.delete(
        MotionDbTables.subcategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      experiencePointRows = await txn.delete(
        MotionDbTables.experiencePoints,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
      mainCategoryRows = await txn.delete(
        MotionDbTables.mainCategory,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );
    });

    final assignerRows = await assignerDb.delete(
      MotionDbTables.assigner,
      where: '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [currentUser],
    );

    return MotionDeletedDataSummary(
      subcategoryRows: subcategoryRows,
      mainCategoryRows: mainCategoryRows,
      experiencePointRows: experiencePointRows,
      assignerRows: assignerRows,
      activeTimerRows: activeTimerRows,
    );
  }

  Future<MotionCsvImportResult> _importSubcategory(
    List<List<dynamic>> csvRows,
    String currentUser, {
    MotionCsvImportProgressChanged? onProgress,
  }) async {
    final db = await _trackerDatabase();
    final headers = _headers(csvRows);
    _requireHeaders(headers, [
      MotionDbColumns.date,
      MotionDbColumns.mainCategoryName,
      MotionDbColumns.subcategoryName,
      MotionDbColumns.timeSpent,
    ]);
    var importedRows = 0;
    var skippedRows = 0;
    var processedRows = 0;
    final rebuiltDates = <String>{};
    final totalRows = csvRows.length - 1;

    final importedMinutesByDate = <String, double>{};
    for (final row in csvRows.skip(1)) {
      final rowMap = _rowMap(headers, row);
      final date = _normalizeDate(rowMap[MotionDbColumns.date]);
      final mainCategoryName = rowMap[MotionDbColumns.mainCategoryName] ?? '';
      final subcategoryName = rowMap[MotionDbColumns.subcategoryName] ?? '';
      if (date.isEmpty || mainCategoryName.isEmpty || subcategoryName.isEmpty) {
        continue;
      }
      final minutes = _parseDouble(rowMap[MotionDbColumns.timeSpent]);
      TrackingTimePolicy.validateBlock(minutes);
      importedMinutesByDate.update(
        date,
        (total) => total + minutes,
        ifAbsent: () => minutes,
      );
    }
    for (final dailyTotal in importedMinutesByDate.entries) {
      TrackingTimePolicy.validateDailyTotal(
        existingMinutes: 0,
        additionalMinutes: dailyTotal.value,
        date: dailyTotal.key,
      );
    }

    _reportImportProgress(
      onProgress,
      processedRows: processedRows,
      totalRows: totalRows,
      importedRows: importedRows,
      fileLabel: 'subcategory.csv',
      force: true,
    );

    await db.transaction((txn) async {
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

      for (final row in csvRows.skip(1)) {
        processedRows++;
        final rowMap = _rowMap(headers, row);
        final date = _normalizeDate(rowMap[MotionDbColumns.date]);
        final mainCategoryName = rowMap[MotionDbColumns.mainCategoryName] ?? '';
        final subcategoryName = rowMap[MotionDbColumns.subcategoryName] ?? '';
        if (date.isEmpty ||
            mainCategoryName.isEmpty ||
            subcategoryName.isEmpty) {
          skippedRows++;
          _reportImportProgress(
            onProgress,
            processedRows: processedRows,
            totalRows: totalRows,
            importedRows: importedRows,
            fileLabel: 'subcategory.csv',
          );
          continue;
        }

        await _ensureDailyRows(txn, currentUser, date);
        rebuiltDates.add(date);
        await txn.insert(MotionDbTables.subcategory, {
          MotionDbColumns.date: date,
          MotionDbColumns.mainCategoryName: mainCategoryName,
          MotionDbColumns.subcategoryName: subcategoryName,
          MotionDbColumns.timeSpent:
              _parseDouble(rowMap[MotionDbColumns.timeSpent]),
          MotionDbColumns.currentLoggedInUser: currentUser,
        });

        importedRows++;
        _reportImportProgress(
          onProgress,
          processedRows: processedRows,
          totalRows: totalRows,
          importedRows: importedRows,
          fileLabel: 'subcategory.csv',
        );
      }
    });

    await _backfillXp(currentUser);
    _reportImportProgress(
      onProgress,
      processedRows: totalRows,
      totalRows: totalRows,
      importedRows: importedRows,
      fileLabel: 'subcategory.csv',
      force: true,
    );
    return MotionCsvImportResult(
      importedRows: importedRows,
      skippedRows: skippedRows,
      rebuiltDailyRows: rebuiltDates.length,
    );
  }

  Future<MotionCsvImportResult> _importAssigner(
    List<List<dynamic>> csvRows,
    String currentUser, {
    MotionCsvImportProgressChanged? onProgress,
  }) async {
    final db = await _assignerDatabase();
    final headers = _headers(csvRows);
    _requireHeaders(headers, [
      MotionDbColumns.subcategoryName,
      MotionDbColumns.mainCategoryName,
      MotionDbColumns.isActive,
      MotionDbColumns.dateCreated,
    ]);
    var importedRows = 0;
    var skippedRows = 0;
    var processedRows = 0;
    final totalRows = csvRows.length - 1;
    _reportImportProgress(
      onProgress,
      processedRows: processedRows,
      totalRows: totalRows,
      importedRows: importedRows,
      fileLabel: 'to_assign.csv',
      force: true,
    );

    await db.transaction((txn) async {
      await txn.delete(
        MotionDbTables.assigner,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
      );

      for (final row in csvRows.skip(1)) {
        processedRows++;
        final rowMap = _rowMap(headers, row);
        final subcategoryName = rowMap[MotionDbColumns.subcategoryName] ?? '';
        final mainCategoryName = rowMap[MotionDbColumns.mainCategoryName] ?? '';
        if (subcategoryName.isEmpty || mainCategoryName.isEmpty) {
          skippedRows++;
          _reportImportProgress(
            onProgress,
            processedRows: processedRows,
            totalRows: totalRows,
            importedRows: importedRows,
            fileLabel: 'to_assign.csv',
          );
          continue;
        }

        await txn.insert(
          MotionDbTables.assigner,
          {
            MotionDbColumns.currentLoggedInUser: currentUser,
            MotionDbColumns.subcategoryName: subcategoryName,
            MotionDbColumns.mainCategoryName: mainCategoryName,
            MotionDbColumns.isActive:
                _parseInt(rowMap[MotionDbColumns.isActive]),
            MotionDbColumns.isArchive:
                _parseInt(rowMap[MotionDbColumns.isArchive]),
            MotionDbColumns.dateCreated:
                _normalizeDate(rowMap[MotionDbColumns.dateCreated]),
            MotionDbColumns.isStreakActive:
                _parseInt(rowMap[MotionDbColumns.isStreakActive]),
            MotionDbColumns.streakType:
                rowMap[MotionDbColumns.streakType] ?? '',
            MotionDbColumns.streakTargetMinutes:
                _parseDouble(rowMap[MotionDbColumns.streakTargetMinutes]),
            MotionDbColumns.streakStartDate:
                _normalizeDate(rowMap[MotionDbColumns.streakStartDate]),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        importedRows++;
        _reportImportProgress(
          onProgress,
          processedRows: processedRows,
          totalRows: totalRows,
          importedRows: importedRows,
          fileLabel: 'to_assign.csv',
        );
      }
    });

    _reportImportProgress(
      onProgress,
      processedRows: totalRows,
      totalRows: totalRows,
      importedRows: importedRows,
      fileLabel: 'to_assign.csv',
      force: true,
    );
    return MotionCsvImportResult(
      importedRows: importedRows,
      skippedRows: skippedRows,
      rebuiltDailyRows: 0,
    );
  }

  Future<List<List<dynamic>>> _mainCategoryRows(String currentUser) async {
    final db = await _trackerDatabase();
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
    final db = await _trackerDatabase();
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
    final db = await _assignerDatabase();
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
        MotionDbColumns.isStreakActive,
        MotionDbColumns.streakType,
        MotionDbColumns.streakTargetMinutes,
        MotionDbColumns.streakStartDate,
      ],
      ...rows.map((row) => [
            row[MotionDbColumns.currentLoggedInUser],
            row[MotionDbColumns.subcategoryName],
            row[MotionDbColumns.mainCategoryName],
            row[MotionDbColumns.isActive],
            row[MotionDbColumns.isArchive],
            row[MotionDbColumns.dateCreated],
            row[MotionDbColumns.isStreakActive],
            row[MotionDbColumns.streakType],
            row[MotionDbColumns.streakTargetMinutes],
            row[MotionDbColumns.streakStartDate],
          ]),
    ];
  }

  Future<void> _writeCsvFile({
    required Directory directory,
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = await _csvContentFromRows(rows);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(csv);
  }

  Future<void> _writeAndroidCsvFile({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csv = await _csvContentFromRows(rows);
    await _downloadsChannel.invokeMethod<String>('saveCsv', {
      'fileName': fileName,
      'content': csv,
    });
  }

  Future<String> _csvContentFromRows(List<List<dynamic>> rows) async {
    return const ListToCsvConverter().convert(rows);
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

  MotionCsvPreview _previewRows({
    required String filePath,
    required MotionCsvFileType fileType,
    required List<List<dynamic>> csvRows,
    required List<String> headers,
    required bool Function(Map<String, String> rowMap) isValidRow,
    required String Function(Map<String, String> rowMap) dateForRow,
  }) {
    var validRows = 0;
    var skippedRows = 0;
    String? firstDate;
    String? lastDate;

    for (final row in csvRows.skip(1)) {
      final rowMap = _rowMap(headers, row);
      if (!isValidRow(rowMap)) {
        skippedRows++;
        continue;
      }

      validRows++;
      final date = dateForRow(rowMap);
      if (date.isEmpty) continue;
      if (firstDate == null || date.compareTo(firstDate) < 0) {
        firstDate = date;
      }
      if (lastDate == null || date.compareTo(lastDate) > 0) {
        lastDate = date;
      }
    }

    return MotionCsvPreview(
      fileName: p.basename(filePath),
      fileType: fileType,
      totalRows: csvRows.length - 1,
      validRows: validRows,
      skippedRows: skippedRows,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  void _requireHeaders(List<String> headers, List<String> requiredHeaders) {
    final missingHeaders =
        requiredHeaders.where((header) => !headers.contains(header)).toList();
    if (missingHeaders.isNotEmpty) {
      throw FormatException(
        'Missing required CSV column(s): ${missingHeaders.join(', ')}',
      );
    }
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
    return MotionDateUtils.normalizeStoredDate(value);
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
        MotionDbColumns.accountabilityBonusXp: 0,
        MotionDbColumns.currentLoggedInUser: currentUser,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _backfillXp(String currentUser) async {
    final db = await _trackerDatabase();
    await db.execute('''
      INSERT OR IGNORE INTO ${MotionDbTables.experiencePoints}
        (${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser},
        ${MotionDbColumns.educationXp}, ${MotionDbColumns.workXp},
        ${MotionDbColumns.skillsXp}, ${MotionDbColumns.selfDevelopmentXp},
        ${MotionDbColumns.sleepXp}, ${MotionDbColumns.accountabilityBonusXp})
      SELECT ${MotionDbColumns.date}, ${MotionDbColumns.currentLoggedInUser},
        0, 0, 0, 0, 0, 0
      FROM ${MotionDbTables.mainCategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?;
    ''', [currentUser]);
  }

  Future<void> _ensureHasExportableData(String currentUser) async {
    final summary = await dataSummaryForUser(currentUser: currentUser);

    if (!summary.hasExportableData) {
      throw StateError('There is no Motion data to export yet.');
    }
  }

  Future<MotionDataSummary> dataSummaryForUser({
    required String currentUser,
  }) async {
    final trackerDb = await _trackerDatabase();
    final assignerDb = await _assignerDatabase();

    final subcategoryCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.subcategory}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final mainCategoryCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.mainCategory}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final experiencePointCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.experiencePoints}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final activeTimerCount = Sqflite.firstIntValue(await trackerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.activeTimerSession}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final assignerCount = Sqflite.firstIntValue(await assignerDb.rawQuery(
          '''
          SELECT COUNT(*)
          FROM ${MotionDbTables.assigner}
          WHERE ${MotionDbColumns.currentLoggedInUser} = ?
          ''',
          [currentUser],
        )) ??
        0;

    final dateRange = await trackerDb.rawQuery(
      '''
      SELECT
        MIN(${MotionDbColumns.date}) AS firstDate,
        MAX(${MotionDbColumns.date}) AS lastDate
      FROM ${MotionDbTables.subcategory}
      WHERE ${MotionDbColumns.currentLoggedInUser} = ?
      ''',
      [currentUser],
    );

    return MotionDataSummary(
      subcategoryRows: subcategoryCount,
      mainCategoryRows: mainCategoryCount,
      experiencePointRows: experiencePointCount,
      assignerRows: assignerCount,
      activeTimerRows: activeTimerCount,
      firstTrackedDate: dateRange.first['firstDate']?.toString(),
      lastTrackedDate: dateRange.first['lastDate']?.toString(),
    );
  }

  void _reportImportProgress(
    MotionCsvImportProgressChanged? onProgress, {
    required int processedRows,
    required int totalRows,
    required int importedRows,
    required String fileLabel,
    bool force = false,
  }) {
    if (onProgress == null) return;
    if (!force && processedRows % 25 != 0 && processedRows != totalRows) {
      return;
    }

    onProgress(
      MotionCsvImportProgress(
        processedRows: processedRows,
        totalRows: totalRows,
        importedRows: importedRows,
        fileLabel: fileLabel,
      ),
    );
  }
}
