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
    required this.timelineCollectionRows,
    required this.goalRows,
    required this.goalCheckInRows,
    required this.firstTrackedDate,
    required this.lastTrackedDate,
  });

  final int trackingRows;
  final int dailyTotalRows;
  final int assignedRows;
  final int timelineCollectionRows;
  final int goalRows;
  final int goalCheckInRows;
  final String? firstTrackedDate;
  final String? lastTrackedDate;

  int get totalRows =>
      trackingRows +
      dailyTotalRows +
      assignedRows +
      timelineCollectionRows +
      goalRows +
      goalCheckInRows;
}

class MotionBackupRestoreResult {
  const MotionBackupRestoreResult({
    required this.trackingRows,
    required this.dailyTotalRows,
    required this.experiencePointRows,
    required this.assignedRows,
    required this.timelineCollectionRows,
    required this.goalRows,
    required this.goalCheckInRows,
  });

  final int trackingRows;
  final int dailyTotalRows;
  final int experiencePointRows;
  final int assignedRows;
  final int timelineCollectionRows;
  final int goalRows;
  final int goalCheckInRows;
}

class MotionValidatedBackup {
  const MotionValidatedBackup._({
    required this.currentUser,
    required this.preview,
    required List<Map<String, Object?>> mainCategoryRows,
    required List<Map<String, Object?>> subcategoryRows,
    required List<Map<String, Object?>> assignerRows,
    required List<Map<String, Object?>> timelineCollectionRows,
    required List<Map<String, Object?>> goalRows,
    required List<Map<String, Object?>> goalCheckInRows,
    required List<Map<String, Object?>> goalPauseRows,
    required List<Map<String, Object?>> goalDependencyRows,
    required this.includesGoalData,
  })  : _mainCategoryRows = mainCategoryRows,
        _subcategoryRows = subcategoryRows,
        _assignerRows = assignerRows,
        _timelineCollectionRows = timelineCollectionRows,
        _goalRows = goalRows,
        _goalCheckInRows = goalCheckInRows,
        _goalPauseRows = goalPauseRows,
        _goalDependencyRows = goalDependencyRows;

  final String currentUser;
  final MotionBackupRestorePreview preview;
  final List<Map<String, Object?>> _mainCategoryRows;
  final List<Map<String, Object?>> _subcategoryRows;
  final List<Map<String, Object?>> _assignerRows;
  final List<Map<String, Object?>> _timelineCollectionRows;
  final List<Map<String, Object?>> _goalRows;
  final List<Map<String, Object?>> _goalCheckInRows;
  final List<Map<String, Object?>> _goalPauseRows;
  final List<Map<String, Object?>> _goalDependencyRows;
  final bool includesGoalData;
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
  static const List<String> _legacyGoalHeaders = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalStatus,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _goalHeaders = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalActivationDate,
    MotionDbColumns.goalAutoStartAfterPrerequisites,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalDeadlineDate,
    MotionDbColumns.goalFailureDate,
    MotionDbColumns.goalFailureReason,
    MotionDbColumns.goalTargetDays,
    MotionDbColumns.goalRetryOfId,
    MotionDbColumns.goalStatus,
    MotionDbColumns.timelineEntryType,
    MotionDbColumns.timelineCollectionId,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _goalHeadersV24 = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalActivationDate,
    MotionDbColumns.goalAutoStartAfterPrerequisites,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalDeadlineDate,
    MotionDbColumns.goalStatus,
    MotionDbColumns.timelineEntryType,
    MotionDbColumns.timelineCollectionId,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _goalHeadersWithoutAutoStart = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalActivationDate,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalDeadlineDate,
    MotionDbColumns.goalStatus,
    MotionDbColumns.timelineEntryType,
    MotionDbColumns.timelineCollectionId,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _goalHeadersWithoutActivation = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalDeadlineDate,
    MotionDbColumns.goalStatus,
    MotionDbColumns.timelineEntryType,
    MotionDbColumns.timelineCollectionId,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _typedGoalHeadersWithoutDeadline = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalName,
    MotionDbColumns.goalDescription,
    MotionDbColumns.goalStartDate,
    MotionDbColumns.goalCompletionDate,
    MotionDbColumns.goalStatus,
    MotionDbColumns.timelineEntryType,
    MotionDbColumns.timelineCollectionId,
    MotionDbColumns.goalCreatedAtEpochMs,
    MotionDbColumns.goalUpdatedAtEpochMs,
  ];
  static const List<String> _timelineCollectionHeaders = [
    MotionDbColumns.id,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.timelineCollectionName,
    MotionDbColumns.timelineCollectionCreatedAtEpochMs,
    MotionDbColumns.timelineCollectionUpdatedAtEpochMs,
  ];
  static const List<String> _goalCheckInHeaders = [
    MotionDbColumns.goalId,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.date,
  ];
  static const List<String> _goalPauseHeaders = [
    MotionDbColumns.id,
    MotionDbColumns.goalId,
    MotionDbColumns.currentLoggedInUser,
    MotionDbColumns.goalPauseStartDate,
    MotionDbColumns.goalPauseResumeDate,
    MotionDbColumns.goalPauseReason,
  ];
  static const List<String> _goalDependencyHeaders = [
    MotionDbColumns.dependentGoalId,
    MotionDbColumns.prerequisiteGoalId,
    MotionDbColumns.currentLoggedInUser,
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
    final includesGoalData = backupFiles.containsKey(_BackupFileKind.goals);
    final timelineCollectionRows =
        backupFiles.containsKey(_BackupFileKind.timelineCollections)
            ? _parseRows(
                backupFiles[_BackupFileKind.timelineCollections]!,
                _timelineCollectionHeaders,
              )
            : const <Map<String, String>>[];
    final goalRows = includesGoalData
        ? _parseRowsAcceptingHeaders(
            backupFiles[_BackupFileKind.goals]!,
            const [
              _goalHeaders,
              _goalHeadersV24,
              _goalHeadersWithoutAutoStart,
              _goalHeadersWithoutActivation,
              _typedGoalHeadersWithoutDeadline,
              _legacyGoalHeaders,
            ],
          )
        : const <Map<String, String>>[];
    final goalCheckInRows = includesGoalData
        ? _parseRows(
            backupFiles[_BackupFileKind.goalCheckIns]!,
            _goalCheckInHeaders,
          )
        : const <Map<String, String>>[];
    final goalPauseRows = includesGoalData &&
            backupFiles.containsKey(_BackupFileKind.goalPausePeriods)
        ? _parseRows(
            backupFiles[_BackupFileKind.goalPausePeriods]!,
            _goalPauseHeaders,
          )
        : const <Map<String, String>>[];
    final goalDependencyRows = includesGoalData &&
            backupFiles.containsKey(_BackupFileKind.goalDependencies)
        ? _parseRows(
            backupFiles[_BackupFileKind.goalDependencies]!,
            _goalDependencyHeaders,
          )
        : const <Map<String, String>>[];

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
    final validatedTimelineCollectionRows = _validateTimelineCollectionRows(
      timelineCollectionRows,
      currentUser,
    );
    final validatedGoalRows = _validateGoalRows(
      goalRows,
      currentUser,
      validatedTimelineCollectionRows,
    );
    final validatedGoalPauseRows = _validateGoalPauseRows(
      goalPauseRows,
      currentUser,
      validatedGoalRows,
    );
    final validatedGoalDependencyRows = _validateGoalDependencyRows(
      goalDependencyRows,
      currentUser,
      validatedGoalRows,
    );
    final validatedGoalCheckInRows = _validateGoalCheckInRows(
      goalCheckInRows,
      currentUser,
      validatedGoalRows,
    );

    if (validatedSubcategoryRows.isEmpty &&
        validatedAssignerRows.isEmpty &&
        validatedTimelineCollectionRows.isEmpty &&
        validatedGoalRows.isEmpty) {
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
        timelineCollectionRows: validatedTimelineCollectionRows.length,
        goalRows: validatedGoalRows.length,
        goalCheckInRows: validatedGoalCheckInRows.length,
        firstTrackedDate: dates.isEmpty ? null : dates.first,
        lastTrackedDate: dates.isEmpty ? null : dates.last,
      ),
      mainCategoryRows: validatedMainRows,
      subcategoryRows: validatedSubcategoryRows,
      assignerRows: validatedAssignerRows,
      timelineCollectionRows: validatedTimelineCollectionRows,
      goalRows: validatedGoalRows,
      goalCheckInRows: validatedGoalCheckInRows,
      goalPauseRows: validatedGoalPauseRows,
      goalDependencyRows: validatedGoalDependencyRows,
      includesGoalData: includesGoalData,
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
        if (backup.includesGoalData) {
          await txn.delete(
            MotionDbTables.goalDependencies,
            where: '${MotionDbColumns.currentLoggedInUser} = ?',
            whereArgs: [currentUser],
          );
          await txn.delete(
            MotionDbTables.goals,
            where: '${MotionDbColumns.currentLoggedInUser} = ?',
            whereArgs: [currentUser],
          );

          await txn.delete(
            MotionDbTables.timelineCollections,
            where: '${MotionDbColumns.currentLoggedInUser} = ?',
            whereArgs: [currentUser],
          );

          final restoredCollectionIds = <int, int>{};
          for (final originalRow in backup._timelineCollectionRows) {
            final backupId = originalRow[MotionDbColumns.id]! as int;
            final row = Map<String, Object?>.from(originalRow)
              ..remove(MotionDbColumns.id);
            final restoredId = await txn.insert(
              MotionDbTables.timelineCollections,
              row,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
            restoredCollectionIds[backupId] = restoredId;
          }

          final restoredGoalIds = <int, int>{};
          for (final originalRow in backup._goalRows) {
            final backupId = originalRow[MotionDbColumns.id]! as int;
            final row = Map<String, Object?>.from(originalRow)
              ..remove(MotionDbColumns.id)
              ..remove(MotionDbColumns.goalRetryOfId);
            final backupCollectionId =
                row[MotionDbColumns.timelineCollectionId] as int?;
            row[MotionDbColumns.timelineCollectionId] =
                backupCollectionId == null
                    ? null
                    : restoredCollectionIds[backupCollectionId];
            final restoredId = await txn.insert(
              MotionDbTables.goals,
              row,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
            restoredGoalIds[backupId] = restoredId;
          }
          for (final originalRow in backup._goalRows) {
            final backupRetryOfId =
                originalRow[MotionDbColumns.goalRetryOfId] as int?;
            if (backupRetryOfId == null) continue;
            final restoredGoalId =
                restoredGoalIds[originalRow[MotionDbColumns.id]! as int];
            final restoredRetryOfId = restoredGoalIds[backupRetryOfId];
            if (restoredGoalId == null || restoredRetryOfId == null) {
              throw StateError('A restored retry history is incomplete.');
            }
            await txn.update(
              MotionDbTables.goals,
              {MotionDbColumns.goalRetryOfId: restoredRetryOfId},
              where: '${MotionDbColumns.id} = ?',
              whereArgs: [restoredGoalId],
            );
          }
          final dependencyBatch = txn.batch();
          for (final originalRow in backup._goalDependencyRows) {
            final backupDependentId =
                originalRow[MotionDbColumns.dependentGoalId]! as int;
            final backupPrerequisiteId =
                originalRow[MotionDbColumns.prerequisiteGoalId]! as int;
            dependencyBatch.insert(
              MotionDbTables.goalDependencies,
              {
                MotionDbColumns.dependentGoalId:
                    restoredGoalIds[backupDependentId],
                MotionDbColumns.prerequisiteGoalId:
                    restoredGoalIds[backupPrerequisiteId],
                MotionDbColumns.currentLoggedInUser: currentUser,
              },
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
          await dependencyBatch.commit(noResult: true);
          final pauseBatch = txn.batch();
          for (final originalRow in backup._goalPauseRows) {
            final backupGoalId = originalRow[MotionDbColumns.goalId]! as int;
            final row = Map<String, Object?>.from(originalRow)
              ..remove(MotionDbColumns.id)
              ..[MotionDbColumns.goalId] = restoredGoalIds[backupGoalId];
            pauseBatch.insert(
              MotionDbTables.goalPausePeriods,
              row,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
          await pauseBatch.commit(noResult: true);
          final checkInBatch = txn.batch();
          for (final originalRow in backup._goalCheckInRows) {
            final backupGoalId = originalRow[MotionDbColumns.goalId]! as int;
            checkInBatch.insert(
              MotionDbTables.goalCheckIns,
              {
                ...originalRow,
                MotionDbColumns.goalId: restoredGoalIds[backupGoalId],
              },
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
          await checkInBatch.commit(noResult: true);
        }
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
      timelineCollectionRows: backup._timelineCollectionRows.length,
      goalRows: backup._goalRows.length,
      goalCheckInRows: backup._goalCheckInRows.length,
    );
  }

  Map<_BackupFileKind, MotionCsvBackupFile> _classifyBackupFiles(
    List<MotionCsvBackupFile> files,
  ) {
    if (files.length < 3 || files.length > _BackupFileKind.values.length) {
      throw StateError(
        'Select the complete set of files from one Motion backup.',
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

    for (final kind in const [
      _BackupFileKind.mainCategory,
      _BackupFileKind.subcategory,
      _BackupFileKind.assigner,
    ]) {
      if (!classified.containsKey(kind)) {
        throw StateError('The selected backup is missing ${kind.label}.');
      }
    }
    final hasGoals = classified.containsKey(_BackupFileKind.goals);
    final hasCheckIns = classified.containsKey(_BackupFileKind.goalCheckIns);
    if (hasGoals != hasCheckIns) {
      throw StateError(
        'A timeline backup must include both goals.csv and '
        'goal_check_ins.csv.',
      );
    }
    final hasCollections =
        classified.containsKey(_BackupFileKind.timelineCollections);
    if (hasCollections && !hasGoals) {
      throw StateError(
        'timeline_collections.csv must be restored together with goals.csv '
        'and goal_check_ins.csv.',
      );
    }
    final hasPausePeriods =
        classified.containsKey(_BackupFileKind.goalPausePeriods);
    if (hasPausePeriods && !hasGoals) {
      throw StateError(
        'goal_pause_periods.csv must be restored together with goals.csv '
        'and goal_check_ins.csv.',
      );
    }
    final hasDependencies =
        classified.containsKey(_BackupFileKind.goalDependencies);
    if (hasDependencies && !hasGoals) {
      throw StateError(
        'goal_dependencies.csv must be restored together with goals.csv '
        'and goal_check_ins.csv.',
      );
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
      final value when value.endsWith('timeline_collections.csv') =>
        _BackupFileKind.timelineCollections,
      final value when value.endsWith('goal_check_ins.csv') =>
        _BackupFileKind.goalCheckIns,
      final value when value.endsWith('goal_pause_periods.csv') =>
        _BackupFileKind.goalPausePeriods,
      final value when value.endsWith('goal_dependencies.csv') =>
        _BackupFileKind.goalDependencies,
      final value when value.endsWith('goals.csv') => _BackupFileKind.goals,
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
        if (_listsEqual(headers, _timelineCollectionHeaders)) {
          return _BackupFileKind.timelineCollections;
        }
        if (_listsEqual(headers, _goalHeaders) ||
            _listsEqual(headers, _goalHeadersV24) ||
            _listsEqual(headers, _goalHeadersWithoutAutoStart) ||
            _listsEqual(headers, _goalHeadersWithoutActivation) ||
            _listsEqual(headers, _typedGoalHeadersWithoutDeadline) ||
            _listsEqual(headers, _legacyGoalHeaders)) {
          return _BackupFileKind.goals;
        }
        if (_listsEqual(headers, _goalCheckInHeaders)) {
          return _BackupFileKind.goalCheckIns;
        }
        if (_listsEqual(headers, _goalPauseHeaders)) {
          return _BackupFileKind.goalPausePeriods;
        }
        if (_listsEqual(headers, _goalDependencyHeaders)) {
          return _BackupFileKind.goalDependencies;
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

  List<Map<String, String>> _parseRowsAcceptingHeaders(
    MotionCsvBackupFile file,
    List<List<String>> acceptedHeaders,
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
    for (final headers in acceptedHeaders) {
      if (_listsEqual(actualHeaders, headers)) {
        return _parseRows(file, headers);
      }
    }
    throw StateError(
      '${file.fileName} does not have recognized Motion backup columns.',
    );
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

  List<Map<String, Object?>> _validateTimelineCollectionRows(
    List<Map<String, String>> rows,
    String currentUser,
  ) {
    final ids = <int>{};
    final normalizedNames = <String>{};
    return rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(
        row,
        currentUser,
        'timeline_collections.csv',
        rowNumber,
      );
      final id = _positiveInt(
        row[MotionDbColumns.id],
        fileName: 'timeline_collections.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.id,
      );
      if (!ids.add(id)) {
        throw StateError(
          'timeline_collections.csv contains duplicate collection ID $id.',
        );
      }
      final name = _requiredText(
        row[MotionDbColumns.timelineCollectionName],
        fileName: 'timeline_collections.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.timelineCollectionName,
      );
      if (name.length > 60) {
        throw StateError(
          'timeline_collections.csv, row $rowNumber, has a collection name '
          'longer than 60 characters.',
        );
      }
      if (!normalizedNames.add(name.toLowerCase())) {
        throw StateError(
          'timeline_collections.csv contains duplicate collection name "$name".',
        );
      }
      return <String, Object?>{
        MotionDbColumns.id: id,
        MotionDbColumns.currentLoggedInUser: currentUser,
        MotionDbColumns.timelineCollectionName: name,
        MotionDbColumns.timelineCollectionCreatedAtEpochMs: _nonNegativeInt(
          row[MotionDbColumns.timelineCollectionCreatedAtEpochMs],
          fileName: 'timeline_collections.csv',
          rowNumber: rowNumber,
          columnName: MotionDbColumns.timelineCollectionCreatedAtEpochMs,
        ),
        MotionDbColumns.timelineCollectionUpdatedAtEpochMs: _nonNegativeInt(
          row[MotionDbColumns.timelineCollectionUpdatedAtEpochMs],
          fileName: 'timeline_collections.csv',
          rowNumber: rowNumber,
          columnName: MotionDbColumns.timelineCollectionUpdatedAtEpochMs,
        ),
      };
    }).toList(growable: false);
  }

  List<Map<String, Object?>> _validateGoalRows(
    List<Map<String, String>> rows,
    String currentUser,
    List<Map<String, Object?>> collections,
  ) {
    final ids = <int>{};
    final collectionIds =
        collections.map((row) => row[MotionDbColumns.id]! as int).toSet();
    final validated = rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(row, currentUser, 'goals.csv', rowNumber);
      final id = _positiveInt(
        row[MotionDbColumns.id],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.id,
      );
      if (!ids.add(id)) {
        throw StateError('goals.csv contains duplicate timeline ID $id.');
      }
      final startDate = _strictDate(
        row[MotionDbColumns.goalStartDate],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalStartDate,
      );
      final hasActivationColumn =
          row.containsKey(MotionDbColumns.goalActivationDate);
      final activationDate = hasActivationColumn
          ? _optionalStrictDate(
              row[MotionDbColumns.goalActivationDate],
              fileName: 'goals.csv',
              rowNumber: rowNumber,
              columnName: MotionDbColumns.goalActivationDate,
            )
          : startDate;
      final completionDate = _optionalStrictDate(
        row[MotionDbColumns.goalCompletionDate],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalCompletionDate,
      );
      final automaticStart =
          row.containsKey(MotionDbColumns.goalAutoStartAfterPrerequisites)
              ? _binaryInt(
                  row[MotionDbColumns.goalAutoStartAfterPrerequisites],
                  fileName: 'goals.csv',
                  rowNumber: rowNumber,
                  columnName: MotionDbColumns.goalAutoStartAfterPrerequisites,
                )
              : 0;
      final deadlineDate = _optionalStrictDate(
        row[MotionDbColumns.goalDeadlineDate],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalDeadlineDate,
      );
      final failureDate = _optionalStrictDate(
        row[MotionDbColumns.goalFailureDate],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalFailureDate,
      );
      final failureReason =
          row[MotionDbColumns.goalFailureReason]?.trim() ?? '';
      if (failureReason.length > 200) {
        throw StateError(
          'goals.csv, row $rowNumber, has a failure note longer than 200 characters.',
        );
      }
      final targetDaysText = row[MotionDbColumns.goalTargetDays]?.trim() ?? '';
      final targetDays = targetDaysText.isEmpty
          ? null
          : _positiveInt(
              targetDaysText,
              fileName: 'goals.csv',
              rowNumber: rowNumber,
              columnName: MotionDbColumns.goalTargetDays,
            );
      final retryOfText = row[MotionDbColumns.goalRetryOfId]?.trim() ?? '';
      final retryOfGoalId = retryOfText.isEmpty
          ? null
          : _positiveInt(
              retryOfText,
              fileName: 'goals.csv',
              rowNumber: rowNumber,
              columnName: MotionDbColumns.goalRetryOfId,
            );
      final status = _requiredText(
        row[MotionDbColumns.goalStatus],
        fileName: 'goals.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalStatus,
      );
      if (status != 'active' && status != 'achieved' && status != 'failed') {
        throw StateError(
          'goals.csv, row $rowNumber, has invalid timeline status "$status".',
        );
      }
      if ((status == 'achieved') != (completionDate != null)) {
        throw StateError(
          'goals.csv, row $rowNumber, has inconsistent status and completion date.',
        );
      }
      if ((status == 'failed') != (failureDate != null)) {
        throw StateError(
          'goals.csv, row $rowNumber, has inconsistent failed status and failure date.',
        );
      }
      if (completionDate != null && failureDate != null) {
        throw StateError(
          'goals.csv, row $rowNumber, cannot be both achieved and failed.',
        );
      }
      if (status == 'achieved' && activationDate == null) {
        throw StateError(
          'goals.csv, row $rowNumber, completes without an activation date.',
        );
      }
      if (activationDate != null && activationDate.compareTo(startDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, activates before its planned start.',
        );
      }
      if (completionDate != null &&
          activationDate != null &&
          completionDate.compareTo(activationDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, completes before it activates.',
        );
      }
      if (completionDate != null && completionDate.compareTo(startDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, completes before it starts.',
        );
      }
      if (failureDate != null &&
          activationDate != null &&
          failureDate.compareTo(activationDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, fails before it activates.',
        );
      }
      if (failureDate != null && failureDate.compareTo(startDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, fails before it starts.',
        );
      }
      if (deadlineDate != null && deadlineDate.compareTo(startDate) < 0) {
        throw StateError(
          'goals.csv, row $rowNumber, has a deadline before it starts.',
        );
      }
      final entryType =
          row[MotionDbColumns.timelineEntryType]?.trim().isNotEmpty == true
              ? row[MotionDbColumns.timelineEntryType]!.trim()
              : 'timeline';
      if (entryType != 'timeline' && entryType != 'goal') {
        throw StateError(
          'goals.csv, row $rowNumber, has invalid entry type "$entryType".',
        );
      }
      if (entryType == 'timeline' && deadlineDate != null) {
        throw StateError(
          'goals.csv, row $rowNumber, gives a deadline to a timeline.',
        );
      }
      if (entryType == 'timeline' &&
          (failureDate != null ||
              targetDays != null ||
              retryOfGoalId != null)) {
        throw StateError(
          'goals.csv, row $rowNumber, gives goal-only attempt data to a timeline.',
        );
      }
      final collectionText =
          row[MotionDbColumns.timelineCollectionId]?.trim() ?? '';
      final collectionId = collectionText.isEmpty
          ? null
          : _positiveInt(
              collectionText,
              fileName: 'goals.csv',
              rowNumber: rowNumber,
              columnName: MotionDbColumns.timelineCollectionId,
            );
      if (collectionId != null && !collectionIds.contains(collectionId)) {
        throw StateError(
          'goals.csv, row $rowNumber, references missing collection '
          '$collectionId.',
        );
      }
      return <String, Object?>{
        MotionDbColumns.id: id,
        MotionDbColumns.currentLoggedInUser: currentUser,
        MotionDbColumns.goalName: _requiredText(
          row[MotionDbColumns.goalName],
          fileName: 'goals.csv',
          rowNumber: rowNumber,
          columnName: MotionDbColumns.goalName,
        ),
        MotionDbColumns.goalDescription:
            row[MotionDbColumns.goalDescription]?.trim() ?? '',
        MotionDbColumns.goalStartDate: startDate,
        MotionDbColumns.goalActivationDate: activationDate,
        MotionDbColumns.goalAutoStartAfterPrerequisites: automaticStart,
        MotionDbColumns.goalCompletionDate: completionDate,
        MotionDbColumns.goalDeadlineDate: deadlineDate,
        MotionDbColumns.goalFailureDate: failureDate,
        MotionDbColumns.goalFailureReason: failureReason,
        MotionDbColumns.goalTargetDays: targetDays,
        MotionDbColumns.goalRetryOfId: retryOfGoalId,
        MotionDbColumns.goalStatus:
            status == 'achieved' ? 'achieved' : 'active',
        MotionDbColumns.timelineEntryType: entryType,
        MotionDbColumns.timelineCollectionId: collectionId,
        MotionDbColumns.goalCreatedAtEpochMs: _nonNegativeInt(
          row[MotionDbColumns.goalCreatedAtEpochMs],
          fileName: 'goals.csv',
          rowNumber: rowNumber,
          columnName: MotionDbColumns.goalCreatedAtEpochMs,
        ),
        MotionDbColumns.goalUpdatedAtEpochMs: _nonNegativeInt(
          row[MotionDbColumns.goalUpdatedAtEpochMs],
          fileName: 'goals.csv',
          rowNumber: rowNumber,
          columnName: MotionDbColumns.goalUpdatedAtEpochMs,
        ),
      };
    }).toList(growable: false);
    final goalsById = <int, Map<String, Object?>>{
      for (final goal in validated) goal[MotionDbColumns.id]! as int: goal,
    };
    for (final goal in validated) {
      final goalId = goal[MotionDbColumns.id]! as int;
      final retryOfGoalId = goal[MotionDbColumns.goalRetryOfId] as int?;
      if (retryOfGoalId == null) continue;
      if (retryOfGoalId == goalId) {
        throw StateError('goals.csv links attempt $goalId to itself.');
      }
      final previous = goalsById[retryOfGoalId];
      if (previous == null ||
          previous[MotionDbColumns.goalFailureDate] == null) {
        throw StateError(
          'goals.csv links attempt $goalId to a missing or non-failed attempt.',
        );
      }
      final retryStart = goal[MotionDbColumns.goalStartDate]! as String;
      final previousFailure =
          previous[MotionDbColumns.goalFailureDate]! as String;
      if (retryStart.compareTo(previousFailure) < 0) {
        throw StateError(
          'goals.csv starts retry $goalId before the previous attempt failed.',
        );
      }
      final visited = <int>{goalId};
      var cursor = retryOfGoalId;
      while (true) {
        if (!visited.add(cursor)) {
          throw StateError('goals.csv contains a circular retry history.');
        }
        final parent = goalsById[cursor];
        final next = parent?[MotionDbColumns.goalRetryOfId] as int?;
        if (next == null) break;
        cursor = next;
      }
    }
    return validated;
  }

  List<Map<String, Object?>> _validateGoalPauseRows(
    List<Map<String, String>> rows,
    String currentUser,
    List<Map<String, Object?>> goals,
  ) {
    final goalsById = {
      for (final goal in goals) goal[MotionDbColumns.id]! as int: goal,
    };
    final ids = <int>{};
    final validated = rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(row, currentUser, 'goal_pause_periods.csv', rowNumber);
      final id = _positiveInt(
        row[MotionDbColumns.id],
        fileName: 'goal_pause_periods.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.id,
      );
      if (!ids.add(id)) {
        throw StateError(
          'goal_pause_periods.csv contains duplicate pause ID $id.',
        );
      }
      final goalId = _positiveInt(
        row[MotionDbColumns.goalId],
        fileName: 'goal_pause_periods.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalId,
      );
      final goal = goalsById[goalId];
      if (goal == null) {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, references missing goal $goalId.',
        );
      }
      if (goal[MotionDbColumns.timelineEntryType] != 'goal') {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, references a timeline instead of a goal.',
        );
      }
      final startDate = _strictDate(
        row[MotionDbColumns.goalPauseStartDate],
        fileName: 'goal_pause_periods.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalPauseStartDate,
      );
      final resumeDate = _optionalStrictDate(
        row[MotionDbColumns.goalPauseResumeDate],
        fileName: 'goal_pause_periods.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalPauseResumeDate,
      );
      final goalStart = goal[MotionDbColumns.goalStartDate]! as String;
      final endDate = goal[MotionDbColumns.goalCompletionDate] as String? ??
          goal[MotionDbColumns.goalFailureDate] as String?;
      if (startDate.compareTo(goalStart) < 0 ||
          (endDate != null && startDate.compareTo(endDate) > 0)) {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, starts outside the goal date range.',
        );
      }
      if (resumeDate != null && resumeDate.compareTo(startDate) < 0) {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, resumes before the pause begins.',
        );
      }
      if (endDate != null &&
          (resumeDate == null || resumeDate.compareTo(endDate) > 0)) {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, is not closed within the finished goal.',
        );
      }
      final reason = row[MotionDbColumns.goalPauseReason]?.trim() ?? '';
      if (reason.length > 200) {
        throw StateError(
          'goal_pause_periods.csv, row $rowNumber, has a pause reason longer than 200 characters.',
        );
      }
      return <String, Object?>{
        MotionDbColumns.id: id,
        MotionDbColumns.goalId: goalId,
        MotionDbColumns.currentLoggedInUser: currentUser,
        MotionDbColumns.goalPauseStartDate: startDate,
        MotionDbColumns.goalPauseResumeDate: resumeDate,
        MotionDbColumns.goalPauseReason: reason,
      };
    }).toList(growable: false);

    final byGoal = <int, List<Map<String, Object?>>>{};
    for (final row in validated) {
      byGoal
          .putIfAbsent(row[MotionDbColumns.goalId]! as int, () => [])
          .add(row);
    }
    for (final entry in byGoal.entries) {
      final periods = entry.value
        ..sort((first, second) =>
            (first[MotionDbColumns.goalPauseStartDate]! as String).compareTo(
              second[MotionDbColumns.goalPauseStartDate]! as String,
            ));
      String? previousEnd;
      for (final period in periods) {
        final start = period[MotionDbColumns.goalPauseStartDate]! as String;
        if (previousEnd == null && period != periods.first) {
          throw StateError(
            'goal_pause_periods.csv contains a pause after an open pause for goal ${entry.key}.',
          );
        }
        if (previousEnd != null && start.compareTo(previousEnd) < 0) {
          throw StateError(
            'goal_pause_periods.csv contains overlapping pauses for goal ${entry.key}.',
          );
        }
        previousEnd = period[MotionDbColumns.goalPauseResumeDate] as String?;
      }
    }
    return validated;
  }

  List<Map<String, Object?>> _validateGoalDependencyRows(
    List<Map<String, String>> rows,
    String currentUser,
    List<Map<String, Object?>> goals,
  ) {
    final goalsById = {
      for (final goal in goals) goal[MotionDbColumns.id]! as int: goal,
    };
    final links = <String>{};
    final graph = <int, Set<int>>{};
    final validated = rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(row, currentUser, 'goal_dependencies.csv', rowNumber);
      final dependentId = _positiveInt(
        row[MotionDbColumns.dependentGoalId],
        fileName: 'goal_dependencies.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.dependentGoalId,
      );
      final prerequisiteId = _positiveInt(
        row[MotionDbColumns.prerequisiteGoalId],
        fileName: 'goal_dependencies.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.prerequisiteGoalId,
      );
      if (dependentId == prerequisiteId) {
        throw StateError(
          'goal_dependencies.csv, row $rowNumber, links an entry to itself.',
        );
      }
      if (!links.add('$dependentId|$prerequisiteId')) {
        throw StateError(
          'goal_dependencies.csv contains a duplicate progression link.',
        );
      }
      final dependent = goalsById[dependentId];
      final prerequisite = goalsById[prerequisiteId];
      if (dependent == null || prerequisite == null) {
        throw StateError(
          'goal_dependencies.csv, row $rowNumber, references a missing entry.',
        );
      }
      final collectionId = dependent[MotionDbColumns.timelineCollectionId];
      if (collectionId == null ||
          prerequisite[MotionDbColumns.timelineCollectionId] != collectionId) {
        throw StateError(
          'goal_dependencies.csv, row $rowNumber, links entries from different collections.',
        );
      }
      graph.putIfAbsent(dependentId, () => <int>{}).add(prerequisiteId);
      return <String, Object?>{
        MotionDbColumns.dependentGoalId: dependentId,
        MotionDbColumns.prerequisiteGoalId: prerequisiteId,
        MotionDbColumns.currentLoggedInUser: currentUser,
      };
    }).toList(growable: false);

    bool hasCycle(int current, Set<int> visiting, Set<int> visited) {
      if (visiting.contains(current)) return true;
      if (!visited.add(current)) return false;
      visiting.add(current);
      for (final prerequisite in graph[current] ?? const <int>{}) {
        if (hasCycle(prerequisite, visiting, visited)) return true;
      }
      visiting.remove(current);
      return false;
    }

    final visited = <int>{};
    for (final goalId in graph.keys) {
      if (hasCycle(goalId, <int>{}, visited)) {
        throw StateError(
          'goal_dependencies.csv contains a circular progression.',
        );
      }
    }

    for (final goal in goals) {
      final goalId = goal[MotionDbColumns.id]! as int;
      final activationDate = goal[MotionDbColumns.goalActivationDate];
      final prerequisiteIds = graph[goalId] ?? const <int>{};
      final automaticStart =
          goal[MotionDbColumns.goalAutoStartAfterPrerequisites] == 1;
      if (automaticStart && prerequisiteIds.isEmpty) {
        throw StateError(
          'goals.csv contains an automatic entry without a prerequisite.',
        );
      }
      if (activationDate == null && prerequisiteIds.isEmpty) {
        throw StateError(
          'goals.csv contains a locked entry without a prerequisite.',
        );
      }
      if (activationDate == null &&
          prerequisiteIds.every(
            (id) => goalsById[id]![MotionDbColumns.goalStatus] == 'achieved',
          )) {
        throw StateError(
          'The backup contains a locked entry whose prerequisites are complete.',
        );
      }
    }
    return validated;
  }

  List<Map<String, Object?>> _validateGoalCheckInRows(
    List<Map<String, String>> rows,
    String currentUser,
    List<Map<String, Object?>> goals,
  ) {
    final goalsById = {
      for (final goal in goals) goal[MotionDbColumns.id]! as int: goal,
    };
    final keys = <String>{};
    return rows.indexed.map((entry) {
      final rowNumber = entry.$1 + 2;
      final row = entry.$2;
      _validateUser(row, currentUser, 'goal_check_ins.csv', rowNumber);
      final goalId = _positiveInt(
        row[MotionDbColumns.goalId],
        fileName: 'goal_check_ins.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.goalId,
      );
      final goal = goalsById[goalId];
      if (goal == null) {
        throw StateError(
          'goal_check_ins.csv, row $rowNumber, references missing timeline $goalId.',
        );
      }
      final date = _strictDate(
        row[MotionDbColumns.date],
        fileName: 'goal_check_ins.csv',
        rowNumber: rowNumber,
        columnName: MotionDbColumns.date,
      );
      final key = '$goalId|$date';
      if (!keys.add(key)) {
        throw StateError(
          'goal_check_ins.csv contains duplicate check-in $date for timeline $goalId.',
        );
      }
      final startDate = goal[MotionDbColumns.goalStartDate]! as String;
      final endDate = goal[MotionDbColumns.goalCompletionDate] as String? ??
          goal[MotionDbColumns.goalFailureDate] as String?;
      if (date.compareTo(startDate) < 0 ||
          (endDate != null && date.compareTo(endDate) > 0)) {
        throw StateError(
          'goal_check_ins.csv, row $rowNumber, is outside the timeline date range.',
        );
      }
      return <String, Object?>{
        MotionDbColumns.goalId: goalId,
        MotionDbColumns.currentLoggedInUser: currentUser,
        MotionDbColumns.date: date,
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

  String? _optionalStrictDate(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _strictDate(
      text,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: columnName,
    );
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

  int _positiveInt(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final parsed = _nonNegativeInt(
      value,
      fileName: fileName,
      rowNumber: rowNumber,
      columnName: columnName,
    );
    if (parsed == 0) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "0".',
      );
    }
    return parsed;
  }

  int _nonNegativeInt(
    String? value, {
    required String fileName,
    required int rowNumber,
    required String columnName,
  }) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) {
      throw StateError(
        '$fileName, row $rowNumber, has invalid $columnName "$text".',
      );
    }
    return parsed;
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
  assigner('to_assign.csv'),
  timelineCollections('timeline_collections.csv'),
  goals('goals.csv'),
  goalCheckIns('goal_check_ins.csv'),
  goalPausePeriods('goal_pause_periods.csv'),
  goalDependencies('goal_dependencies.csv');

  const _BackupFileKind(this.label);

  final String label;
}
