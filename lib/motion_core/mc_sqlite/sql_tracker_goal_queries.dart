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
      final linkedEntries = await db.rawQuery('''
        SELECT 1
        FROM ${MotionDbTables.goalDependencies} dependency
        JOIN ${MotionDbTables.goals} dependent
          ON dependent.${MotionDbColumns.id} =
            dependency.${MotionDbColumns.dependentGoalId}
        WHERE dependent.${MotionDbColumns.timelineCollectionId} = ?
          AND dependency.${MotionDbColumns.currentLoggedInUser} = ?
        LIMIT 1
      ''', [collectionId, currentUser]);
      if (linkedEntries.isNotEmpty) {
        throw StateError(
          'Unlink this collection progression before deleting the collection.',
        );
      }
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
        orderBy: "CASE WHEN ${MotionDbColumns.goalStatus} = 'active' AND "
            '${MotionDbColumns.goalFailureDate} IS NULL THEN 0 ELSE 1 END, '
            '${MotionDbColumns.goalStartDate} DESC, ${MotionDbColumns.id} DESC',
      );
      return rows.map(MotionGoal.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError('TrackerDatabaseHelper.getGoals', error, stackTrace);
    }
  }

  Future<List<GoalDependency>> getGoalDependencies({
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        MotionDbTables.goalDependencies,
        where: '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [currentUser],
        orderBy: '${MotionDbColumns.dependentGoalId}, '
            '${MotionDbColumns.prerequisiteGoalId}',
      );
      return rows.map(GoalDependency.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.getGoalDependencies',
        error,
        stackTrace,
      );
    }
  }

  Future<int> insertGoal(MotionGoal goal) async {
    return insertGoalWithDependencies(goal: goal);
  }

  Future<int> insertGoalWithDependencies({
    required MotionGoal goal,
    List<int> prerequisiteGoalIds = const [],
    int? replacesFailedGoalId,
  }) async {
    _validateGoal(goal);
    try {
      final db = await database;
      return db.transaction((transaction) async {
        await _ensureGoalCollectionOwnership(transaction, goal);
        final prerequisites = await _validatedPrerequisites(
          transaction,
          goal: goal,
          prerequisiteGoalIds: prerequisiteGoalIds,
        );
        final activationDate = _activationDateFor(
          goal.startDate,
          prerequisites,
          startsAutomatically: goal.startsAutomaticallyAfterPrerequisites,
        );
        if (goal.hasEnded && activationDate == null) {
          throw StateError(
            'A finished entry cannot depend on an unfinished prerequisite.',
          );
        }
        final endDate = goal.completionDate ?? goal.failureDate;
        if (endDate != null &&
            activationDate != null &&
            activationDate.isAfter(endDate)) {
          throw StateError(
            'This entry finished before its prerequisite was completed.',
          );
        }
        final storedStart = goal.startsAutomaticallyAfterPrerequisites &&
                activationDate != null &&
                activationDate.isBefore(goal.startDate)
            ? activationDate
            : goal.startDate;
        final storedGoal = goal.copyWith(
          startDate: storedStart,
          activationDate: activationDate,
          clearActivationDate: activationDate == null,
        );
        _validateGoal(storedGoal);
        final goalId = await transaction.insert(
          MotionDbTables.goals,
          storedGoal.toMap()..remove(MotionDbColumns.id),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceGoalDependencies(
          transaction,
          goalId: goalId,
          currentUser: goal.currentLoggedInUser,
          prerequisiteGoalIds: prerequisiteGoalIds,
        );
        if (replacesFailedGoalId != null) {
          await _replaceFailedAttemptInProgressions(
            transaction,
            failedGoalId: replacesFailedGoalId,
            retryGoalId: goalId,
            currentUser: goal.currentLoggedInUser,
          );
        }
        return goalId;
      });
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.insertGoalWithDependencies',
        error,
        stackTrace,
      );
    }
  }

  Future<void> updateGoal(MotionGoal goal) async {
    if (goal.activationDate != null &&
        goal.activationDate!.isBefore(goal.startDate)) {
      goal = goal.copyWith(activationDate: goal.startDate);
    }
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
        if (goal.hasEnded) {
          final endDate = goal.completionDate ?? goal.failureDate!;
          await transaction.update(
            MotionDbTables.goalPausePeriods,
            {
              MotionDbColumns.goalPauseResumeDate:
                  MotionDateUtils.formatDbDate(endDate),
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

  Future<List<int>> updateGoalWithDependencies({
    required MotionGoal goal,
    required List<int> prerequisiteGoalIds,
  }) async {
    final goalId = goal.id;
    if (goalId == null) {
      throw ArgumentError('A saved timeline must have an ID.');
    }
    try {
      final db = await database;
      return db.transaction((transaction) async {
        await _ensureGoalCollectionOwnership(transaction, goal);
        final existingRows = await transaction.query(
          MotionDbTables.goals,
          where: '${MotionDbColumns.id} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [goalId, goal.currentLoggedInUser],
          limit: 1,
        );
        if (existingRows.isEmpty) {
          throw StateError('Timeline could not be found.');
        }
        final existingGoal = MotionGoal.fromMap(existingRows.single);
        final existingDependencyRows = await transaction.query(
          MotionDbTables.goalDependencies,
          columns: [MotionDbColumns.prerequisiteGoalId],
          where: '${MotionDbColumns.dependentGoalId} = ? AND '
              '${MotionDbColumns.currentLoggedInUser} = ?',
          whereArgs: [goalId, goal.currentLoggedInUser],
        );
        final existingIds = existingDependencyRows
            .map((row) =>
                (row[MotionDbColumns.prerequisiteGoalId] as num).toInt())
            .toSet();
        final incomingIds = prerequisiteGoalIds.toSet();
        final prerequisites = await _validatedPrerequisites(
          transaction,
          goal: goal,
          prerequisiteGoalIds: prerequisiteGoalIds,
        );
        await _ensureNoDependencyCycle(
          transaction,
          goalId: goalId,
          prerequisiteGoalIds: prerequisiteGoalIds,
        );
        final dependenciesUnchanged =
            existingIds.length == incomingIds.length &&
                existingIds.containsAll(incomingIds);
        final allPrerequisitesComplete =
            prerequisites.every((entry) => entry.isAchieved);
        final activationDate = allPrerequisitesComplete
            ? _activationDateFor(
                goal.startDate,
                prerequisites,
                startsAutomatically: goal.startsAutomaticallyAfterPrerequisites,
              )
            : dependenciesUnchanged &&
                    incomingIds.isNotEmpty &&
                    existingGoal.activationDate != null
                ? _laterGoalDate(goal.startDate, existingGoal.activationDate!)
                : null;
        if (goal.hasEnded && activationDate == null) {
          throw StateError(
            'A finished entry cannot depend on an unfinished prerequisite.',
          );
        }
        final endDate = goal.completionDate ?? goal.failureDate;
        if (endDate != null &&
            activationDate != null &&
            activationDate.isAfter(endDate)) {
          throw StateError(
            'This entry finished before its prerequisite was completed.',
          );
        }
        final storedStart = goal.startsAutomaticallyAfterPrerequisites &&
                activationDate != null &&
                activationDate.isBefore(goal.startDate)
            ? activationDate
            : goal.startDate;
        final storedGoal = goal.copyWith(
          startDate: storedStart,
          activationDate: activationDate,
          clearActivationDate: activationDate == null,
        );
        _validateGoal(storedGoal);
        await _updateGoalInTransaction(transaction, storedGoal);
        await _replaceGoalDependencies(
          transaction,
          goalId: goalId,
          currentUser: goal.currentLoggedInUser,
          prerequisiteGoalIds: prerequisiteGoalIds,
        );
        if (!storedGoal.isAchieved) return const <int>[];
        return _unlockEligibleGoals(
          transaction,
          currentUser: storedGoal.currentLoggedInUser,
          updatedAtEpochMs: storedGoal.updatedAtEpochMs,
        );
      });
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.updateGoalWithDependencies',
        error,
        stackTrace,
      );
    }
  }

  Future<List<int>> markGoalAchievedAndUnlockDependents(
    MotionGoal goal,
  ) async {
    _validateGoal(goal);
    if (!goal.isAchieved || goal.completionDate == null || goal.id == null) {
      throw ArgumentError('The completed timeline details are invalid.');
    }
    try {
      final db = await database;
      return db.transaction((transaction) async {
        await _updateGoalInTransaction(transaction, goal);
        return _unlockEligibleGoals(
          transaction,
          currentUser: goal.currentLoggedInUser,
          updatedAtEpochMs: goal.updatedAtEpochMs,
        );
      });
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.markGoalAchievedAndUnlockDependents',
        error,
        stackTrace,
      );
    }
  }

  Future<List<int>> reconcileGoalDependencyActivations({
    required String currentUser,
    required int updatedAtEpochMs,
  }) async {
    try {
      final db = await database;
      return db.transaction(
        (transaction) => _unlockEligibleGoals(
          transaction,
          currentUser: currentUser,
          updatedAtEpochMs: updatedAtEpochMs,
        ),
      );
    } catch (error, stackTrace) {
      logDatabaseError(
        'TrackerDatabaseHelper.reconcileGoalDependencyActivations',
        error,
        stackTrace,
      );
    }
  }

  Future<void> deleteGoal({
    required int goalId,
    required String currentUser,
  }) async {
    try {
      final db = await database;
      final dependents = await db.query(
        MotionDbTables.goalDependencies,
        columns: [MotionDbColumns.dependentGoalId],
        where: '${MotionDbColumns.prerequisiteGoalId} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [goalId, currentUser],
        limit: 1,
      );
      if (dependents.isNotEmpty) {
        throw StateError(
          'Remove this entry from its linked progression before deleting it.',
        );
      }
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
    if (goal.hasEnded) {
      throw StateError('A finished goal cannot be paused.');
    }
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    if (goal.isLocked) {
      throw StateError('A locked goal cannot be paused.');
    }
    if (normalizedStart.isBefore(goal.effectiveStartDate)) {
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
    if (goal.hasEnded) {
      throw StateError(
        'Finished goals are read-only. Start a new attempt to continue.',
      );
    }
    if (!goal.isGoal) {
      throw StateError('Daily effort check-ins are only available for goals.');
    }
    final normalizedDate = MotionDateUtils.dateOnly(date);
    final normalizedToday = MotionDateUtils.dateOnly(today);
    if (goal.isLocked) {
      throw StateError('A locked goal cannot be checked in.');
    }
    if (normalizedDate.isBefore(goal.effectiveStartDate) ||
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
    final failureDate = goal.failureDate;
    if (goal.isFailed && failureDate == null) {
      throw ArgumentError('A failed goal requires a failure date.');
    }
    if (!goal.isFailed && failureDate != null) {
      throw ArgumentError('Only a failed goal can have a failure date.');
    }
    if (failureDate != null && failureDate.isBefore(goal.startDate)) {
      throw ArgumentError('Failure date cannot be before the start date.');
    }
    if (goal.isFailed && !goal.isGoal) {
      throw ArgumentError('Only goals can be marked as failed.');
    }
    if (goal.failureReason.length > 200) {
      throw ArgumentError('Failure notes can contain up to 200 characters.');
    }
    if (goal.targetDays != null && goal.targetDays! <= 0) {
      throw ArgumentError('Required duration must be at least one day.');
    }
    if (goal.isTimeline && goal.targetDays != null) {
      throw ArgumentError('Timelines cannot have a required duration.');
    }
    if (goal.isTimeline && goal.retryOfGoalId != null) {
      throw ArgumentError('Only goals can be retries.');
    }
    final activationDate = goal.activationDate;
    if (goal.hasEnded && activationDate == null) {
      throw ArgumentError('A finished entry must have started.');
    }
    if (activationDate != null && activationDate.isBefore(goal.startDate)) {
      throw ArgumentError(
          'Activation date cannot be before the planned start.');
    }
  }

  Future<void> _updateGoalInTransaction(
    DatabaseExecutor transaction,
    MotionGoal goal,
  ) async {
    final goalId = goal.id!;
    final updated = await transaction.update(
      MotionDbTables.goals,
      goal.toMap()..remove(MotionDbColumns.id),
      where: '${MotionDbColumns.id} = ? AND '
          '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [goalId, goal.currentLoggedInUser],
    );
    if (updated != 1) throw StateError('Timeline could not be found.');
    if (goal.hasEnded) {
      final endDate = goal.completionDate ?? goal.failureDate!;
      await transaction.update(
        MotionDbTables.goalPausePeriods,
        {
          MotionDbColumns.goalPauseResumeDate:
              MotionDateUtils.formatDbDate(endDate),
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
        MotionDateUtils.formatDbDate(goal.effectiveStartDate),
      ],
    );
  }

  Future<List<MotionGoal>> _validatedPrerequisites(
    DatabaseExecutor db, {
    required MotionGoal goal,
    required List<int> prerequisiteGoalIds,
  }) async {
    final uniqueIds = prerequisiteGoalIds.toSet().toList(growable: false);
    if (uniqueIds.length != prerequisiteGoalIds.length) {
      throw ArgumentError('A prerequisite can only be linked once.');
    }
    if (goal.startsAutomaticallyAfterPrerequisites && uniqueIds.isEmpty) {
      throw StateError(
        'Automatic progression requires at least one prerequisite.',
      );
    }
    if (goal.id != null && uniqueIds.contains(goal.id)) {
      throw StateError('An entry cannot depend on itself.');
    }
    if (uniqueIds.isNotEmpty && goal.collectionId == null) {
      throw StateError(
        'Choose a collection before adding a prerequisite.',
      );
    }
    final prerequisites = <MotionGoal>[];
    for (final prerequisiteId in uniqueIds) {
      final rows = await db.query(
        MotionDbTables.goals,
        where: '${MotionDbColumns.id} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ?',
        whereArgs: [prerequisiteId, goal.currentLoggedInUser],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('The selected prerequisite is unavailable.');
      }
      final prerequisite = MotionGoal.fromMap(rows.single);
      if (prerequisite.collectionId != goal.collectionId) {
        throw StateError(
          'Linked entries must belong to the same collection.',
        );
      }
      prerequisites.add(prerequisite);
    }
    return prerequisites;
  }

  DateTime? _activationDateFor(
    DateTime plannedStart,
    List<MotionGoal> prerequisites, {
    required bool startsAutomatically,
  }) {
    if (prerequisites.isEmpty) return MotionDateUtils.dateOnly(plannedStart);
    if (prerequisites.any((entry) => !entry.isAchieved)) return null;
    DateTime? latestCompletion;
    for (final prerequisite in prerequisites) {
      final completionDate = prerequisite.completionDate;
      if (completionDate != null &&
          (latestCompletion == null ||
              completionDate.isAfter(latestCompletion))) {
        latestCompletion = completionDate;
      }
    }
    if (latestCompletion == null) return null;
    if (startsAutomatically) {
      return MotionDateUtils.dateOnly(latestCompletion);
    }
    return _laterGoalDate(
      MotionDateUtils.dateOnly(plannedStart),
      latestCompletion,
    );
  }

  DateTime _laterGoalDate(DateTime first, DateTime second) {
    return first.isAfter(second) ? first : second;
  }

  Future<List<int>> _unlockEligibleGoals(
    DatabaseExecutor db, {
    required String currentUser,
    required int updatedAtEpochMs,
  }) async {
    final candidateRows = await db.query(
      MotionDbTables.goals,
      where: '${MotionDbColumns.currentLoggedInUser} = ? AND '
          '${MotionDbColumns.goalStatus} = ? AND '
          '${MotionDbColumns.goalFailureDate} IS NULL AND '
          '${MotionDbColumns.goalActivationDate} IS NULL',
      whereArgs: [currentUser, GoalStatus.active.name],
    );
    final unlockedIds = <int>[];
    for (final row in candidateRows) {
      final dependent = MotionGoal.fromMap(row);
      final dependentId = dependent.id;
      if (dependentId == null) continue;
      final prerequisiteRows = await db.rawQuery('''
        SELECT prerequisite.*
        FROM ${MotionDbTables.goalDependencies} dependency
        JOIN ${MotionDbTables.goals} prerequisite
          ON prerequisite.${MotionDbColumns.id} =
            dependency.${MotionDbColumns.prerequisiteGoalId}
        WHERE dependency.${MotionDbColumns.dependentGoalId} = ?
          AND dependency.${MotionDbColumns.currentLoggedInUser} = ?
      ''', [dependentId, currentUser]);
      if (prerequisiteRows.isEmpty) continue;
      final prerequisites =
          prerequisiteRows.map(MotionGoal.fromMap).toList(growable: false);
      final activationDate = _activationDateFor(
        dependent.startDate,
        prerequisites,
        startsAutomatically: dependent.startsAutomaticallyAfterPrerequisites,
      );
      if (activationDate == null) continue;
      final updated = await db.update(
        MotionDbTables.goals,
        {
          if (dependent.startsAutomaticallyAfterPrerequisites &&
              activationDate.isBefore(dependent.startDate))
            MotionDbColumns.goalStartDate:
                MotionDateUtils.formatDbDate(activationDate),
          MotionDbColumns.goalActivationDate:
              MotionDateUtils.formatDbDate(activationDate),
          MotionDbColumns.goalUpdatedAtEpochMs: updatedAtEpochMs,
        },
        where: '${MotionDbColumns.id} = ? AND '
            '${MotionDbColumns.currentLoggedInUser} = ? AND '
            '${MotionDbColumns.goalActivationDate} IS NULL',
        whereArgs: [dependentId, currentUser],
      );
      if (updated == 1) unlockedIds.add(dependentId);
    }
    return unlockedIds;
  }

  Future<void> _replaceGoalDependencies(
    DatabaseExecutor db, {
    required int goalId,
    required String currentUser,
    required List<int> prerequisiteGoalIds,
  }) async {
    await db.delete(
      MotionDbTables.goalDependencies,
      where: '${MotionDbColumns.dependentGoalId} = ? AND '
          '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [goalId, currentUser],
    );
    for (final prerequisiteId in prerequisiteGoalIds.toSet()) {
      await db.insert(
        MotionDbTables.goalDependencies,
        GoalDependency(
          dependentGoalId: goalId,
          prerequisiteGoalId: prerequisiteId,
          currentLoggedInUser: currentUser,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _replaceFailedAttemptInProgressions(
    DatabaseExecutor db, {
    required int failedGoalId,
    required int retryGoalId,
    required String currentUser,
  }) async {
    final failedRows = await db.query(
      MotionDbTables.goals,
      where: '${MotionDbColumns.id} = ? AND '
          '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [failedGoalId, currentUser],
      limit: 1,
    );
    if (failedRows.isEmpty || !MotionGoal.fromMap(failedRows.single).isFailed) {
      throw StateError('The previous failed attempt is unavailable.');
    }
    await db.update(
      MotionDbTables.goalDependencies,
      {MotionDbColumns.prerequisiteGoalId: retryGoalId},
      where: '${MotionDbColumns.prerequisiteGoalId} = ? AND '
          '${MotionDbColumns.currentLoggedInUser} = ?',
      whereArgs: [failedGoalId, currentUser],
    );
  }

  Future<void> _ensureNoDependencyCycle(
    DatabaseExecutor db, {
    required int goalId,
    required List<int> prerequisiteGoalIds,
  }) async {
    if (prerequisiteGoalIds.isEmpty) return;
    final dependencies = await db.query(MotionDbTables.goalDependencies);
    final graph = <int, Set<int>>{};
    for (final row in dependencies) {
      final dependent = (row[MotionDbColumns.dependentGoalId] as num).toInt();
      final prerequisite =
          (row[MotionDbColumns.prerequisiteGoalId] as num).toInt();
      graph.putIfAbsent(dependent, () => <int>{}).add(prerequisite);
    }
    graph[goalId] = prerequisiteGoalIds.toSet();

    bool reachesGoal(int current, Set<int> visited) {
      if (current == goalId) return true;
      if (!visited.add(current)) return false;
      return (graph[current] ?? const <int>{})
          .any((next) => reachesGoal(next, visited));
    }

    for (final prerequisiteId in prerequisiteGoalIds) {
      if (reachesGoal(prerequisiteId, <int>{})) {
        throw StateError('This link would create a circular progression.');
      }
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
