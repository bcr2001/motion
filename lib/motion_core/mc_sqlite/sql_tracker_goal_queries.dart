part of 'sql_tracker_db.dart';

extension TrackerGoalQueries on TrackerDatabaseHelper {
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
    if (goalId == null) throw ArgumentError('A saved goal must have an ID.');
    try {
      final db = await database;
      await db.transaction((transaction) async {
        final updated = await transaction.update(
          MotionDbTables.goals,
          goal.toMap()..remove(MotionDbColumns.id),
          where: '${MotionDbColumns.id} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [goalId, goal.currentLoggedInUser],
        );
        if (updated != 1) throw StateError('Goal could not be found.');
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
      if (deleted != 1) throw StateError('Goal could not be found.');
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

  Future<bool> toggleGoalCheckIn({
    required MotionGoal goal,
    required DateTime date,
    required DateTime today,
  }) async {
    final goalId = goal.id;
    if (goalId == null) throw ArgumentError('A saved goal must have an ID.');
    if (goal.isAchieved) {
      throw StateError('Achieved goals are read-only. Reopen the goal first.');
    }
    final normalizedDate = MotionDateUtils.dateOnly(date);
    final normalizedToday = MotionDateUtils.dateOnly(today);
    if (normalizedDate.isBefore(goal.startDate) ||
        normalizedDate.isAfter(normalizedToday)) {
      throw StateError('Only elapsed goal dates can be checked in.');
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
      throw ArgumentError('A goal requires a current user.');
    }
    if (goal.name.trim().isEmpty) {
      throw ArgumentError('A goal name is required.');
    }
    final completionDate = goal.completionDate;
    if (goal.isAchieved && completionDate == null) {
      throw ArgumentError('An achieved goal requires a completion date.');
    }
    if (!goal.isAchieved && completionDate != null) {
      throw ArgumentError('An active goal cannot have a completion date.');
    }
    if (completionDate != null && completionDate.isBefore(goal.startDate)) {
      throw ArgumentError('Completion date cannot be before the start date.');
    }
  }
}
