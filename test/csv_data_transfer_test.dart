import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_csv/csv_data_transfer.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  group('MotionCsvDataTransfer', () {
    late _FakeMotionDatabase trackerDb;
    late _FakeMotionDatabase assignerDb;
    late MotionCsvDataTransfer transfer;
    late Directory tempDir;

    setUp(() {
      trackerDb = _FakeMotionDatabase();
      assignerDb = _FakeMotionDatabase();
      transfer = MotionCsvDataTransfer(
        trackerDatabase: () async => trackerDb,
        assignerDatabase: () async => assignerDb,
      );
      tempDir = Directory.systemTemp.createTempSync('motion_csv_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    File writeCsv(String fileName, String csv) {
      final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      file.writeAsStringSync(csv.trim().replaceAll('\n', '\r\n'));
      return file;
    }

    test('refuses export when there is no data to export', () async {
      expect(
        () => transfer.exportAllToDirectory(
          currentUser: 'user-1',
          directoryPath: tempDir.path,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('previews subcategory csv before import', () async {
      final file = writeCsv('subcategory.csv', '''
date,mainCategoryName,subcategoryName,timeSpent,currentLoggedInUser
1/1/2026,Skills,Chess,60,old-user
bad-date,Skills,Invalid,10,old-user
1/3/2026,,Missing Main,10,old-user
''');

      final preview = await transfer.previewCsv(
        fileType: MotionCsvFileType.subcategory,
        filePath: file.path,
      );

      expect(preview.fileName, 'subcategory.csv');
      expect(preview.totalRows, 3);
      expect(preview.validRows, 1);
      expect(preview.skippedRows, 2);
      expect(preview.firstDate, '2026-01-01');
      expect(preview.lastDate, '2026-01-01');
    });

    test('imports subcategories for the current user and reports progress',
        () async {
      trackerDb.tables[MotionDbTables.subcategory] = [
        {
          MotionDbColumns.date: '2025-12-31',
          MotionDbColumns.mainCategoryName: MotionCategories.skills,
          MotionDbColumns.subcategoryName: 'Old',
          MotionDbColumns.timeSpent: 10.0,
          MotionDbColumns.currentLoggedInUser: 'user-1',
        },
      ];
      trackerDb.tables[MotionDbTables.mainCategory] = [
        {
          MotionDbColumns.date: '2025-12-31',
          MotionDbColumns.currentLoggedInUser: 'user-1',
        },
      ];
      trackerDb.tables[MotionDbTables.experiencePoints] = [
        {
          MotionDbColumns.date: '2025-12-31',
          MotionDbColumns.currentLoggedInUser: 'user-1',
        },
      ];
      final file = writeCsv('subcategory.csv', '''
date,mainCategoryName,subcategoryName,timeSpent,currentLoggedInUser
1/1/2026,Skills,Chess,60,old-user
1/1/2026,Sleep,Sleep,480,old-user
not-a-date,Skills,Bad Row,10,old-user
''');
      final progress = <MotionCsvImportProgress>[];

      final result = await transfer.importCsv(
        fileType: MotionCsvFileType.subcategory,
        filePath: file.path,
        currentUser: 'user-1',
        onProgress: progress.add,
      );

      expect(result.importedRows, 2);
      expect(result.skippedRows, 1);
      expect(result.rebuiltDailyRows, 1);
      expect(progress.first.processedRows, 0);
      expect(progress.last.processedRows, 3);

      final subcategoryRows = trackerDb.tables[MotionDbTables.subcategory]!;
      expect(subcategoryRows, hasLength(2));
      expect(
        subcategoryRows.map((row) => row[MotionDbColumns.currentLoggedInUser]),
        everyElement('user-1'),
      );
      expect(
        subcategoryRows.map((row) => row[MotionDbColumns.subcategoryName]),
        containsAll(['Chess', 'Sleep']),
      );
      expect(
        trackerDb.tables[MotionDbTables.mainCategory],
        contains(
          containsPair(MotionDbColumns.date, '2026-01-01'),
        ),
      );
      expect(
        trackerDb.tables[MotionDbTables.experiencePoints],
        contains(
          containsPair(MotionDbColumns.date, '2026-01-01'),
        ),
      );
      expect(trackerDb.executedSql, isNotEmpty);
    });

    test('imports assigner csv with streak settings', () async {
      final file = writeCsv('to_assign.csv', '''
currentLoggedInUser,subcategoryName,mainCategoryName,isActive,isArchive,dateCreated,isStreakActive,streakType,streakTargetMinutes,streakStartDate
old-user,Chess,Skills,1,0,1/1/2026,1,targetTime,60,1/1/2026
old-user,,Skills,1,0,1/2/2026,0,,0,
''');

      final result = await transfer.importCsv(
        fileType: MotionCsvFileType.assigner,
        filePath: file.path,
        currentUser: 'user-1',
      );

      expect(result.importedRows, 1);
      expect(result.skippedRows, 1);
      final rows = assignerDb.tables[MotionDbTables.assigner]!;
      expect(rows, hasLength(1));
      expect(rows.single[MotionDbColumns.currentLoggedInUser], 'user-1');
      expect(rows.single[MotionDbColumns.subcategoryName], 'Chess');
      expect(rows.single[MotionDbColumns.isStreakActive], 1);
      expect(rows.single[MotionDbColumns.streakType], 'targetTime');
      expect(rows.single[MotionDbColumns.streakTargetMinutes], 60.0);
      expect(rows.single[MotionDbColumns.streakStartDate], '2026-01-01');
    });

  });
}

class _FakeMotionDatabase implements Database, Transaction {
  final tables = <String, List<Map<String, Object?>>>{};
  final executedSql = <String>[];

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) {
    return action(this);
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = tables.putIfAbsent(table, () => []);
    final before = rows.length;
    if (whereArgs == null || whereArgs.isEmpty) {
      rows.clear();
      return before;
    }

    rows.removeWhere(
      (row) => row[MotionDbColumns.currentLoggedInUser] == whereArgs.first,
    );
    return before - rows.length;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = tables.putIfAbsent(table, () => []);
    if (conflictAlgorithm == ConflictAlgorithm.ignore &&
        (table == MotionDbTables.mainCategory ||
            table == MotionDbTables.experiencePoints)) {
      final exists = rows.any(
        (row) =>
            row[MotionDbColumns.date] == values[MotionDbColumns.date] &&
            row[MotionDbColumns.currentLoggedInUser] ==
                values[MotionDbColumns.currentLoggedInUser],
      );
      if (exists) return 0;
    }

    rows.add(Map<String, Object?>.from(values));
    return rows.length;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return _rowsForUser(table, whereArgs);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final table = _tableFromSql(sql);
    final rows = _rowsForUser(table, arguments);
    if (sql.contains('MIN(') && sql.contains('MAX(')) {
      final dates = rows
          .map((row) => row[MotionDbColumns.date]?.toString())
          .whereType<String>()
          .where((date) => date.isNotEmpty)
          .toList()
        ..sort();
      return [
        {
          'firstDate': dates.isEmpty ? null : dates.first,
          'lastDate': dates.isEmpty ? null : dates.last,
        }
      ];
    }

    return [
      {'COUNT(*)': rows.length}
    ];
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
  }

  List<Map<String, Object?>> _rowsForUser(
    String table,
    List<Object?>? arguments,
  ) {
    final rows = tables.putIfAbsent(table, () => []);
    if (arguments == null || arguments.isEmpty) {
      return List<Map<String, Object?>>.from(rows);
    }

    return rows
        .where(
          (row) => row[MotionDbColumns.currentLoggedInUser] == arguments.first,
        )
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  String _tableFromSql(String sql) {
    if (sql.contains(MotionDbTables.subcategory)) {
      return MotionDbTables.subcategory;
    }
    if (sql.contains(MotionDbTables.mainCategory)) {
      return MotionDbTables.mainCategory;
    }
    if (sql.contains(MotionDbTables.experiencePoints)) {
      return MotionDbTables.experiencePoints;
    }
    if (sql.contains(MotionDbTables.assigner)) {
      return MotionDbTables.assigner;
    }
    throw UnsupportedError('Unknown fake SQL table: $sql');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
