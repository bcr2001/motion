part of 'sql_tracker_db.dart';

extension TrackerGoalQueries on TrackerDatabaseHelper {
  Future<List<MotionTimelineCollection>> getTimelineCollections({
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.timelineCollections,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        orderBy: '${MotionDbColumns.timelineCollectionName} COLLATE NOCASE',
      );
      return rows.map(MotionTimelineCollection.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getTimelineCollections',
        error,
        stackTrace,
      );
    }
  }

  Future<int> insertTimelineCollection(
    MotionTimelineCollection collection,
  ) async {
    _validateTimelineCollection(collection);
    try {
      final db = await database;
      await _ensureUniqueCollectionName(
        db,
        currentUser: collection.currentLoggedInUser,
        name: collection.name,
      );
      return db.insert(
        MotionDbTables.timelineCollections,
        collection.toMap()..remove(MotionDbColumns.id),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.insertTimelineCollection',
        error,
        stackTrace,
      );
    }
  }

  Future<void> updateTimelineCollection(
    MotionTimelineCollection collection,
  ) async {
    _validateTimelineCollection(collection);
    final collectionId = collection.id;
    if (collectionId == null) {
      throw ArgumentError('A saved collection must have an ID.');
    }
    try {
      final db = await database;
      await _ensureUniqueCollectionName(
        db,
        currentUser: collection.currentLoggedInUser,
        name: collection.name,
        excludingId: collectionId,
      );
      final updated = await db.update(
        MotionDbTables.timelineCollections,
        collection.toMap()..remove(MotionDbColumns.id),
        where: '${MotionDbColumns.id} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [collectionId, collection.currentLoggedInUser],
      );
      if (updated != 1) throw StateError('Collection could not be found.');
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.updateTimelineCollection',
        error,
        stackTrace,
      );
    }
  }

  Future<void> deleteTimelineCollection({
    required int collectionId,
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        MotionDbTables.timelineCollections,
        where: '${MotionDbColumns.id} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [collectionId, currentUser],
      );
      if (deleted != 1) throw StateError('Collection could not be found.');
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.deleteTimelineCollection',
        error,
        stackTrace,
      );
    }
  }

  Future<List<MotionGoal>> getGoals({required String currentUser}) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.goals,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        orderBy: "CASE WHEN ${MotionDbColumns.goalStatus} = 'active' "
            'THEN 0 ELSE 1 END, '
            '${MotionDbColumns.goalStartDate} DESC, ${MotionDbColumns.id} DESC',
      );
      return rows.map(MotionGoal.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.getGoals', error, stackTrace);
    }
  }

  Future<int> insertGoal(MotionGoal goal) async {
    _validateGoal(goal);
    try {
      final db = await database;
      await _ensureGoalCollectionOwnership(db, goal);
      return db.insert(
        MotionDbTables.goals,
        goal.toMap()..remove(MotionDbColumns.id),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.insertGoal', error, stackTrace);
    }
  }

  Future<void> updateGoal(MotionGoal goal) async {
    _validateGoal(goal);
    final goalId = goal.id;
    if (goalId == null) {
      throw ArgumentError('A saved timeline must have an ID.');
    }
    try {
      final db = await database;
      await _ensureGoalCollectionOwnership(db, goal);
      await db.transaction((transaction) async {
        final updated = await transaction.update(
          MotionDbTables.goals,
          goal.toMap()..remove(MotionDbColumns.id),
          where: '${MotionDbColumns.id} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [goalId, goal.currentLoggedInUser],
        );
        if (updated != 1) throw StateError('Timeline could not be found.');
        if (goal.isAchieved) {
          await transaction.update(
            MotionDbTables.goalPausePeriods,
            {
              MotionDbColumns.goalPauseResumeDate:
                  MotionDateUtils.formatDbDate(goal.completionDate!),
            },
            where: '${MotionDbColumns.goalId} = ? AND '
                '${MotionDbColumns.currentLoggedInUser} = ? AND '
                '${MotionDbColumns.goalPauseResumeDate} IS NULL',
            whereArgs: [goalId, goal.currentLoggedInUser],
          );
        }
        await transaction.delete(
          MotionDbTables.goalCheckIns,
          where: '${MotionDbColumns.goalId} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ? AND '
              '${MotionDbColumns.date} < ?',
          whereArgs: [
            goalId,
            goal.currentLoggedInUser,
            MotionDateUtils.formatDbDate(goal.startDate),
          ],
        );
      });
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.updateGoal', error, stackTrace);
    }
  }

  Future<void> deleteGoal({
    required int goalId,
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        MotionDbTables.goals,
        where: '${MotionDbColumns.id} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [goalId, currentUser],
      );
      if (deleted != 1) throw StateError('Timeline could not be found.');
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.deleteGoal', error, stackTrace);
    }
  }

  Future<List<GoalCheckIn>> getGoalCheckIns({
    required int goalId,
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.goalCheckIns,
        where: '${MotionDbColumns.goalId} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [goalId, currentUser],
        orderBy: '${MotionDbColumns.date} DESC',
      );
      return rows.map(GoalCheckIn.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getGoalCheckIns',
        error,
        stackTrace,
      );
    }
  }

  Future<List<GoalCheckIn>> getAllGoalCheckIns({
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.goalCheckIns,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        orderBy: '${MotionDbColumns.date} DESC',
      );
      return rows.map(GoalCheckIn.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getAllGoalCheckIns',
        error,
        stackTrace,
      );
    }
  }

  Future<List<GoalPausePeriod>> getAllGoalPausePeriods({
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.goalPausePeriods,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        orderBy: '${MotionDbColumns.goalPauseStartDate} DESC, '
            '${MotionDbColumns.id} DESC',
      );
      return rows.map(GoalPausePeriod.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getAllGoalPausePeriods',
        error,
        stackTrace,
      );
    }
  }

  Future<void> pauseGoal({
    required MotionGoal goal,
    required DateTime startDate,
    String reason = '',
  }) async {
    final goalId = goal.id;
    if (goalId == null) {
      throw ArgumentError('A saved goal must have an ID.');
    }
    if (!goal.isGoal) {
      throw StateError('Only goals can be paused.');
    }
    if (goal.isAchieved) {
      throw StateError('An achieved goal cannot be paused.');
    }
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    if (normalizedStart.isBefore(goal.startDate)) {
      throw ArgumentError('A pause cannot begin before the goal starts.');
    }
    try {
      final db = await database;
      await db.insert(
        MotionDbTables.goalPausePeriods,
        GoalPausePeriod(
          goalId: goalId,
          currentLoggedInUser: goal.currentLoggedInUser,
          startDate: normalizedStart,
          reason: reason.trim(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.pauseGoal', error, stackTrace);
    }
  }

  Future<void> resumeGoal({
    required MotionGoal goal,
    required DateTime resumeDate,
  }) async {
    final goalId = goal.id;
    if (goalId == null) {
      throw ArgumentError('A saved goal must have an ID.');
    }
    final normalizedResume = MotionDateUtils.dateOnly(resumeDate);
    try {
      final db = await database;
      final updated = await db.update(
        MotionDbTables.goalPausePeriods,
        {
          MotionDbColumns.goalPauseResumeDate:
              MotionDateUtils.formatDbDate(normalizedResume),
        },
        where: '${MotionDbColumns.goalId} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ? AND '
            '${MotionDbColumns.goalPauseResumeDate} IS NULL AND '
            '${MotionDbColumns.goalPauseStartDate} <= ?',
        whereArgs: [
          goalId,
          goal.currentLoggedInUser,
          MotionDateUtils.formatDbDate(normalizedResume),
        ],
      );
      if (updated != 1) {
        throw StateError('This goal does not have an active pause.');
      }
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.resumeGoal', error, stackTrace);
    }
  }

  Future<bool> toggleGoalCheckIn({
    required MotionGoal goal,
    required DateTime date,
    required DateTime today,
  }) async {
    final goalId = goal.id;
    if (goalId == null) {
      throw ArgumentError('A saved timeline must have an ID.');
    }
    if (goal.isAchieved) {
      throw StateError(
        'Completed timelines are read-only. Resume the timeline first.',
      );
    }
    if (!goal.isGoal) {
      throw StateError('Daily effort check-ins are only available for goals.');
    }
    final normalizedDate = MotionDateUtils.dateOnly(date);
    final normalizedToday = MotionDateUtils.dateOnly(today);
    if (normalizedDate.isBefore(goal.startDate) ||
        normalizedDate.isAfter(normalizedToday)) {
      throw StateError('Only elapsed timeline dates can be checked in.');
    }

    try {
      final db = await database;
      return db.transaction((transaction) async {
        final dateText = MotionDateUtils.formatDbDate(normalizedDate);
        final existing = await transaction.query(
          MotionDbTables.goalCheckIns,
          columns: [MotionDbColumns.goalId],
          where: '${MotionDbColumns.goalId} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ? AND '
              '${MotionDbColumns.date} = ?',
          whereArgs: [goalId, goal.currentLoggedInUser, dateText],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await transaction.delete(
            MotionDbTables.goalCheckIns,
            where: '${MotionDbColumns.goalId} = ? AND '
                '${MotionDbColumns.currentLoggedInUser} = ? AND '
                '${MotionDbColumns.date} = ?',
            whereArgs: [goalId, goal.currentLoggedInUser, dateText],
          );
          return false;
        }
        await transaction.insert(
          MotionDbTables.goalCheckIns,
          GoalCheckIn(
            goalId: goalId,
            currentLoggedInUser: goal.currentLoggedInUser,
            date: normalizedDate,
          ).toMap(),
        );
        return true;
      });
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.toggleGoalCheckIn',
        error,
        stackTrace,
      );
    }
  }

  void _validateGoal(MotionGoal goal) {
    if (goal.currentLoggedInUser.trim().isEmpty) {
      throw ArgumentError('A timeline requires a current user.');
    }
    if (goal.name.trim().isEmpty) {
      throw ArgumentError('A timeline name is required.');
    }
    final completionDate = goal.completionDate;
    if (goal.isAchieved && completionDate == null) {
      throw ArgumentError('A completed timeline requires a completion date.');
    }
    if (!goal.isAchieved && completionDate != null) {
      throw ArgumentError('An ongoing timeline cannot have a completion date.');
    }
    if (completionDate != null && completionDate.isBefore(goal.startDate)) {
      throw ArgumentError('Completion date cannot be before the start date.');
    }
    final deadlineDate = goal.deadlineDate;
    if (deadlineDate != null && deadlineDate.isBefore(goal.startDate)) {
      throw ArgumentError('Deadline cannot be before the start date.');
    }
    if (goal.isTimeline && deadlineDate != null) {
      throw ArgumentError('Timelines cannot have deadlines.');
    }
  }

  void _validateTimelineCollection(MotionTimelineCollection collection) {
    if (collection.currentLoggedInUser.trim().isEmpty) {
      throw ArgumentError('A collection requires a current user.');
    }
    if (collection.name.trim().isEmpty) {
      throw ArgumentError('Enter a collection name.');
    }
  }

  Future<void> _ensureGoalCollectionOwnership(
    DatabaseExecutor db,
    MotionGoal goal,
  ) async {
    final collectionId = goal.collectionId;
    if (collectionId == null) return;
    final rows = await db.query(
      MotionDbTables.timelineCollections,
      columns: [MotionDbColumns.id],
      where: '${MotionDbColumns.id} = ? AND '
          '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [collectionId, goal.currentLoggedInUser],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('The selected collection is unavailable.');
    }
  }

  Future<void> _ensureUniqueCollectionName(
    DatabaseExecutor db, {
    required String currentUser,
    required String name,
    int? excludingId,
  }) async {
    final rows = await db.query(
      MotionDbTables.timelineCollections,
      columns: [MotionDbColumns.id],
      where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
          '${MotionDbColumns.timelineCollectionName} = ? COLLATE NOCASE'
          '${excludingId == null ? '' : ' AND ${MotionDbColumns.id} != ?'}',
      whereArgs: [
        currentUser,
        name.trim(),
        if (excludingId != null) excludingId,
      ],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw StateError('A collection with this name already exists.');
    }
  }
}
