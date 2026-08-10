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

    test('refuses export when there is no data to export', () async {
      expect(
        () => transfer.exportAllToDirectory(
          currentUser: 'user-1',
          directoryPath: tempDir.path,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('builds database-derived CSV backup files', () async {
      _seedExportableData(
        trackerDb: trackerDb,
        assignerDb: assignerDb,
        currentUser: 'user-1',
      );

      final files = await transfer.backupFiles(currentUser: 'user-1');

      expect(
        files.map((file) => file.fileName),
        ['main_category.csv', 'subcategory.csv', 'to_assign.csv'],
      );
      expect(files[0].content, contains('education,work,skills'));
      expect(files[1].content, contains('Skills,Chess,45.0,user-1'));
      expect(files[2].content, contains('Chess,Skills,1,0'));
    });

    test('exports all database-derived CSV files to a selected directory',
        () async {
      _seedExportableData(
        trackerDb: trackerDb,
        assignerDb: assignerDb,
        currentUser: 'user-1',
      );

      final location = await transfer.exportAllToDirectory(
        currentUser: 'user-1',
        directoryPath: tempDir.path,
      );

      expect(location, tempDir.path);
      expect(
        File('${tempDir.path}${Platform.pathSeparator}main_category.csv')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${tempDir.path}${Platform.pathSeparator}subcategory.csv')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${tempDir.path}${Platform.pathSeparator}to_assign.csv')
            .existsSync(),
        isTrue,
      );
    });

    test('deletes local data only for the selected Motion user', () async {
      for (final table in [
        MotionDbTables.subcategory,
        MotionDbTables.mainCategory,
        MotionDbTables.experiencePoints,
        MotionDbTables.activeTimerSession,
      ]) {
        trackerDb.tables[table] = [
          {MotionDbColumns.currentLoggedInUser: 'user-1'},
          {MotionDbColumns.currentLoggedInUser: 'user-2'},
        ];
      }
      assignerDb.tables[MotionDbTables.assigner] = [
        {MotionDbColumns.currentLoggedInUser: 'user-1'},
        {MotionDbColumns.currentLoggedInUser: 'user-2'},
      ];

      final summary = await transfer.deleteAllDataForUser(
        currentUser: 'user-1',
      );

      expect(summary.subcategoryRows, 1);
      expect(summary.mainCategoryRows, 1);
      expect(summary.experiencePointRows, 1);
      expect(summary.assignerRows, 1);
      expect(summary.activeTimerRows, 1);
      expect(summary.totalRows, 5);
      for (final rows in trackerDb.tables.values) {
        expect(
          rows.map((row) => row[MotionDbColumns.currentLoggedInUser]),
          everyElement('user-2'),
        );
      }
      expect(
        assignerDb.tables[MotionDbTables.assigner]!
            .single[MotionDbColumns.currentLoggedInUser],
        'user-2',
      );
    });
  });
}

void _seedExportableData({
  required _FakeMotionDatabase trackerDb,
  required _FakeMotionDatabase assignerDb,
  required String currentUser,
}) {
  trackerDb.tables[MotionDbTables.mainCategory] = [
    {
      MotionDbColumns.date: '2026-01-01',
      MotionDbColumns.education: 60.0,
      MotionDbColumns.work: 0.0,
      MotionDbColumns.skills: 45.0,
      MotionDbColumns.entertainment: 20.0,
      MotionDbColumns.selfDevelopment: 10.0,
      MotionDbColumns.sleep: 480.0,
      MotionDbColumns.currentLoggedInUser: currentUser,
    },
  ];
  trackerDb.tables[MotionDbTables.subcategory] = [
    {
      MotionDbColumns.date: '2026-01-01',
      MotionDbColumns.mainCategoryName: MotionCategories.skills,
      MotionDbColumns.subcategoryName: 'Chess',
      MotionDbColumns.timeSpent: 45.0,
      MotionDbColumns.currentLoggedInUser: currentUser,
    },
  ];
  assignerDb.tables[MotionDbTables.assigner] = [
    {
      MotionDbColumns.currentLoggedInUser: currentUser,
      MotionDbColumns.subcategoryName: 'Chess',
      MotionDbColumns.mainCategoryName: MotionCategories.skills,
      MotionDbColumns.isActive: 1,
      MotionDbColumns.isArchive: 0,
      MotionDbColumns.dateCreated: '2026-01-01',
      MotionDbColumns.isStreakActive: 1,
      MotionDbColumns.streakType: 'trackedToday',
      MotionDbColumns.streakTargetMinutes: 0.0,
      MotionDbColumns.streakStartDate: '2026-01-01',
    },
  ];
}

class _FakeMotionDatabase implements Database, Transaction {
  final tables = <String, List<Map<String, Object?>>>{};

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
    if (sql.contains(MotionDbTables.activeTimerSession)) {
      return MotionDbTables.activeTimerSession;
    }
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
