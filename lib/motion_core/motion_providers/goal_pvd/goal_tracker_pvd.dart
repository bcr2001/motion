import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/current_user_guard.dart';
import 'package:motion/motion_core/motion_services/goal_start_reminder_bridge.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum GoalFilter { all, active, achieved, failed }

class GoalTrackerProvider extends ChangeNotifier with WidgetsBindingObserver {
  GoalTrackerProvider({
    required UserUidProvider userUidProvider,
    TrackerDatabaseHelper? databaseHelper,
    GoalStartReminderBridge? reminderBridge,
    DateTime Function()? now,
  })  : _userUidProvider = userUidProvider,
        _databaseHelper = databaseHelper ?? TrackerDatabaseHelper(),
        _reminderBridge = reminderBridge ?? PlatformGoalStartReminderBridge(),
        _now = now ?? DateTime.now {
    _userUidProvider.addListener(_handleUserChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final UserUidProvider _userUidProvider;
  final TrackerDatabaseHelper _databaseHelper;
  final GoalStartReminderBridge _reminderBridge;
  final DateTime Function() _now;
  final Map<int, List<GoalCheckIn>> _checkIns = {};
  final Map<int, List<GoalPausePeriod>> _pausePeriods = {};
  final Map<int, List<int>> _prerequisiteIds = {};
  List<MotionGoal> _goals = const [];
  List<MotionTimelineCollection> _collections = const [];
  GoalFilter _filter = GoalFilter.all;
  bool _showAllCollections = true;
  int? _selectedCollectionId;
  bool _isLoading = false;
  int _activeMutations = 0;
  Object? _error;
  bool? _reminderPermissionGranted;
  String? _loadedUser;
  Timer? _midnightTimer;
  int _loadGeneration = 0;

  List<MotionGoal> get goals => List.unmodifiable(_goals);
  List<MotionTimelineCollection> get collections =>
      List.unmodifiable(_collections);
  GoalFilter get filter => _filter;
  bool get showAllCollections => _showAllCollections;
  int? get selectedCollectionId => _selectedCollectionId;
  bool get isLoading => _isLoading;
  bool get isSaving => _activeMutations > 0;
  Object? get error => _error;
  bool? get reminderPermissionGranted => _reminderPermissionGranted;
  DateTime get today => MotionDateUtils.today(now: _now);

  List<MotionGoal> get filteredGoals {
    final statusFiltered = switch (_filter) {
      GoalFilter.all => goals,
      GoalFilter.active =>
        goals.where((goal) => goal.isActive).toList(growable: false),
      GoalFilter.achieved =>
        goals.where((goal) => goal.isAchieved).toList(growable: false),
      GoalFilter.failed =>
        goals.where((goal) => goal.isFailed).toList(growable: false),
    };
    if (_showAllCollections) return statusFiltered;
    return statusFiltered
        .where((goal) => goal.collectionId == _selectedCollectionId)
        .toList(growable: false);
  }

  int get activeCount => _goals.where((goal) => goal.isActive).length;
  int get achievedCount => _goals.where((goal) => goal.isAchieved).length;
  int get failedCount => _goals.where((goal) => goal.isFailed).length;

  List<GoalCheckIn> checkInsFor(int goalId) =>
      List.unmodifiable(_checkIns[goalId] ?? const []);

  List<GoalPausePeriod> pausePeriodsFor(int goalId) =>
      List.unmodifiable(_pausePeriods[goalId] ?? const []);

  bool isPaused(MotionGoal goal) =>
      (_pausePeriods[goal.id] ?? const []).any((period) => period.isOpen);

  bool isLocked(MotionGoal goal) => goal.isLocked;

  bool isUpcoming(MotionGoal goal) => goal.isUpcomingAt(today);

  List<int> prerequisiteIdsFor(MotionGoal goal) =>
      List.unmodifiable(_prerequisiteIds[goal.id] ?? const []);

  List<MotionGoal> prerequisitesFor(MotionGoal goal) => prerequisiteIdsFor(goal)
      .map(goalById)
      .whereType<MotionGoal>()
      .toList(growable: false);

  List<MotionGoal> dependentsFor(MotionGoal goal) {
    final goalId = goal.id;
    if (goalId == null) return const [];
    return _goals
        .where((entry) =>
            (_prerequisiteIds[entry.id] ?? const []).contains(goalId))
        .toList(growable: false);
  }

  int? primaryPrerequisiteIdFor(MotionGoal goal) {
    final ids = _prerequisiteIds[goal.id] ?? const [];
    return ids.isEmpty ? null : ids.first;
  }

  MotionGoal? primaryPrerequisiteFor(MotionGoal goal) {
    final id = primaryPrerequisiteIdFor(goal);
    return id == null ? null : goalById(id);
  }

  bool canEditPrerequisite(MotionGoal goal) {
    return prerequisiteIdsFor(goal).length <= 1 &&
        goal.isActive &&
        (goal.isLocked || goal.isUpcomingAt(today));
  }

  Set<int> invalidPrerequisiteIdsFor(MotionGoal? goal) {
    final invalid = <int>{};
    final goalId = goal?.id;
    if (goalId == null) return invalid;
    invalid.add(goalId);
    void addDescendants(int prerequisiteId) {
      for (final entry in _goals) {
        final entryId = entry.id;
        if (entryId == null || invalid.contains(entryId)) continue;
        if ((_prerequisiteIds[entryId] ?? const []).contains(prerequisiteId)) {
          invalid.add(entryId);
          addDescendants(entryId);
        }
      }
    }

    addDescendants(goalId);
    return invalid;
  }

  bool isDatePaused(MotionGoal goal, DateTime date) {
    final normalizedDate = MotionDateUtils.dateOnly(date);
    return (_pausePeriods[goal.id] ?? const []).any((period) {
      final resumeDate = period.resumeDate;
      return !normalizedDate.isBefore(period.startDate) &&
          (resumeDate == null || normalizedDate.isBefore(resumeDate));
    });
  }

  int pausedDaysFor(MotionGoal goal) {
    final endDate = goal.completionDate ?? goal.failureDate ?? today;
    var pausedDays = 0;
    for (final period in _pausePeriods[goal.id] ?? const <GoalPausePeriod>[]) {
      final start = period.startDate.isBefore(goal.effectiveStartDate)
          ? goal.effectiveStartDate
          : period.startDate;
      final rawEnd = period.resumeDate ?? endDate;
      final end = rawEnd.isAfter(endDate) ? endDate : rawEnd;
      if (end.isAfter(start)) pausedDays += end.difference(start).inDays;
    }
    return pausedDays;
  }

  int activeDaysFor(MotionGoal goal) {
    if (!goal.isGoal) return goal.elapsedDaysAt(today);
    final activeDays = goal.elapsedDaysAt(today) - pausedDaysFor(goal);
    return activeDays < 0 ? 0 : activeDays;
  }

  bool isCheckedIn(int goalId, DateTime date) {
    return (_checkIns[goalId] ?? const []).any(
      (checkIn) => MotionDateUtils.isSameDate(checkIn.date, date),
    );
  }

  MotionGoal? goalById(int goalId) {
    for (final goal in _goals) {
      if (goal.id == goalId) return goal;
    }
    return null;
  }

  int attemptNumberFor(MotionGoal goal) {
    var attempt = 1;
    var current = goal;
    final visited = <int>{};
    while (
        current.retryOfGoalId != null && visited.add(current.retryOfGoalId!)) {
      final previous = goalById(current.retryOfGoalId!);
      if (previous == null) break;
      attempt++;
      current = previous;
    }
    return attempt;
  }

  bool isPartOfAttemptSeries(MotionGoal goal) {
    final goalId = goal.id;
    return goal.retryOfGoalId != null ||
        (goalId != null &&
            _goals.any((candidate) => candidate.retryOfGoalId == goalId));
  }

  bool canMarkAchieved(MotionGoal goal) {
    final targetDays = goal.targetDays;
    return goal.isActive &&
        !goal.isLocked &&
        !isUpcoming(goal) &&
        (targetDays == null || activeDaysFor(goal) >= targetDays);
  }

  MotionTimelineCollection? collectionById(int? collectionId) {
    if (collectionId == null) return null;
    for (final collection in _collections) {
      if (collection.id == collectionId) return collection;
    }
    return null;
  }

  int entryCountForCollection(int? collectionId) {
    return _goals.where((goal) => goal.collectionId == collectionId).length;
  }

  void setFilter(GoalFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void showEveryCollection() {
    if (_showAllCollections) return;
    _showAllCollections = true;
    _selectedCollectionId = null;
    notifyListeners();
  }

  void filterByCollection(int? collectionId) {
    if (!_showAllCollections && _selectedCollectionId == collectionId) return;
    _showAllCollections = false;
    _selectedCollectionId = collectionId;
    notifyListeners();
  }

  Future<void> initialize() async {
    await refresh();
    _scheduleMidnightRefresh();
  }

  Future<void> refresh() async {
    final loadGeneration = ++_loadGeneration;
    final user = _userUidProvider.userUid?.trim();
    if (user == null || user.isEmpty) {
      _loadedUser = null;
      _goals = const [];
      _collections = const [];
      _checkIns.clear();
      _pausePeriods.clear();
      _prerequisiteIds.clear();
      _isLoading = false;
      await _syncStartRemindersSafely();
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final reconciledGoalIds =
          await _databaseHelper.reconcileGoalDependencyActivations(
        currentUser: user,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      );
      final collections =
          await _databaseHelper.getTimelineCollections(currentUser: user);
      final goals = await _databaseHelper.getGoals(currentUser: user);
      final checkIns = await _databaseHelper.getAllGoalCheckIns(
        currentUser: user,
      );
      final pausePeriods = await _databaseHelper.getAllGoalPausePeriods(
        currentUser: user,
      );
      final dependencies = await _databaseHelper.getGoalDependencies(
        currentUser: user,
      );
      if (loadGeneration != _loadGeneration ||
          _userUidProvider.userUid?.trim() != user) {
        return;
      }
      _goals = goals;
      _collections = collections;
      _loadedUser = user;
      if (!_showAllCollections &&
          _selectedCollectionId != null &&
          collectionById(_selectedCollectionId) == null) {
        _showAllCollections = true;
        _selectedCollectionId = null;
      }
      _checkIns.clear();
      for (final checkIn in checkIns) {
        _checkIns.putIfAbsent(checkIn.goalId, () => []).add(checkIn);
      }
      _pausePeriods.clear();
      for (final period in pausePeriods) {
        _pausePeriods.putIfAbsent(period.goalId, () => []).add(period);
      }
      _prerequisiteIds.clear();
      for (final dependency in dependencies) {
        _prerequisiteIds
            .putIfAbsent(dependency.dependentGoalId, () => [])
            .add(dependency.prerequisiteGoalId);
      }
      await _syncStartRemindersSafely();
      for (final goalId in reconciledGoalIds) {
        final unlocked = goalById(goalId);
        if (unlocked != null) await _notifyUnlockedSafely(unlocked);
      }
    } catch (error) {
      if (loadGeneration == _loadGeneration) _error = error;
    } finally {
      if (loadGeneration == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<MotionGoal> createGoal({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? completionDate,
    DateTime? deadlineDate,
    int? targetDays,
    int? retryOfGoalId,
    TimelineEntryType entryType = TimelineEntryType.timeline,
    int? collectionId,
    int? prerequisiteId,
    bool? startsAutomaticallyAfterPrerequisites,
  }) async {
    final user = requireCurrentUser(_userUidProvider.userUid ?? '');
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Enter what you are tracking.');
    }
    final now = _now();
    final today = MotionDateUtils.dateOnly(now);
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    final normalizedCompletion = completionDate == null
        ? null
        : MotionDateUtils.dateOnly(completionDate);
    final normalizedDeadline =
        deadlineDate == null ? null : MotionDateUtils.dateOnly(deadlineDate);
    if (entryType == TimelineEntryType.timeline && normalizedDeadline != null) {
      throw ArgumentError('Timelines cannot have deadlines.');
    }
    if (targetDays != null && targetDays <= 0) {
      throw ArgumentError('Required duration must be at least one day.');
    }
    if (entryType == TimelineEntryType.timeline && targetDays != null) {
      throw ArgumentError('Timelines cannot have a required duration.');
    }
    _validateCollectionSelection(collectionId);
    final prerequisite = _validatePrerequisiteSelection(
      prerequisiteId: prerequisiteId,
      collectionId: collectionId,
    );
    final automaticStart =
        prerequisite != null && (startsAutomaticallyAfterPrerequisites ?? true);
    final storedStart = automaticStart && prerequisite.isAchieved
        ? prerequisite.completionDate!
        : normalizedStart;
    _validateTimelineDates(
      startDate: storedStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      today: today,
    );
    final activationDate = prerequisite == null
        ? storedStart
        : prerequisite.isAchieved
            ? automaticStart
                ? prerequisite.completionDate!
                : _laterDate(storedStart, prerequisite.completionDate!)
            : null;
    if (normalizedCompletion != null && activationDate == null) {
      throw StateError(
        'A completed entry cannot depend on an unfinished prerequisite.',
      );
    }
    if (activationDate != null && activationDate.isAfter(today)) {
      await _requestReminderPermissionSafely();
    }
    final goal = MotionGoal(
      currentLoggedInUser: user,
      name: normalizedName,
      description: description.trim(),
      startDate: storedStart,
      activationDate: activationDate,
      startsAutomaticallyAfterPrerequisites: automaticStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      targetDays: targetDays,
      retryOfGoalId: retryOfGoalId,
      status: normalizedCompletion == null
          ? GoalStatus.active
          : GoalStatus.achieved,
      entryType: entryType,
      collectionId: collectionId,
      createdAtEpochMs: now.millisecondsSinceEpoch,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
    );
    return _runMutation(() async {
      final id = await _databaseHelper.insertGoalWithDependencies(
        goal: goal,
        prerequisiteGoalIds:
            prerequisiteId == null ? const [] : [prerequisiteId],
        replacesFailedGoalId: retryOfGoalId,
      );
      await refresh();
      if (_userUidProvider.userUid?.trim() != user) {
        throw StateError(
          'The signed-in Motion account changed. Refresh and try again.',
        );
      }
      return goalById(id) ?? goal.copyWith(id: id);
    });
  }

  Future<void> editGoal({
    required MotionGoal goal,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime? completionDate,
    required DateTime? deadlineDate,
    int? targetDays,
    required TimelineEntryType entryType,
    int? collectionId,
    int? prerequisiteId,
    bool? startsAutomaticallyAfterPrerequisites,
  }) async {
    _requireCurrentGoalOwner(goal);
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Enter what you are tracking.');
    }
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    final normalizedCompletion = completionDate == null
        ? null
        : MotionDateUtils.dateOnly(completionDate);
    final normalizedDeadline =
        deadlineDate == null ? null : MotionDateUtils.dateOnly(deadlineDate);
    _validateCollectionSelection(collectionId);
    final existingPrerequisiteId = primaryPrerequisiteIdFor(goal);
    final existingPrerequisiteIds = prerequisiteIdsFor(goal);
    if (prerequisiteId != existingPrerequisiteId &&
        !canEditPrerequisite(goal)) {
      throw StateError(
        'A prerequisite cannot be changed after this entry has started.',
      );
    }
    final selectedPrerequisite = _validatePrerequisiteSelection(
      prerequisiteId: prerequisiteId,
      collectionId: collectionId,
      editingGoal: goal,
    );
    final automaticStart = selectedPrerequisite != null &&
        (startsAutomaticallyAfterPrerequisites ??
            goal.startsAutomaticallyAfterPrerequisites);
    if (automaticStart != goal.startsAutomaticallyAfterPrerequisites &&
        !canEditPrerequisite(goal)) {
      throw StateError(
        'The automatic start rule cannot change after this entry starts.',
      );
    }
    final storedStart = automaticStart && selectedPrerequisite.isAchieved
        ? selectedPrerequisite.completionDate!
        : normalizedStart;
    if (entryType == TimelineEntryType.timeline &&
        (_pausePeriods[goal.id!] ?? const []).isNotEmpty) {
      throw StateError(
        'A goal with pause history cannot be changed into a timeline.',
      );
    }
    if (entryType == TimelineEntryType.timeline && normalizedDeadline != null) {
      throw ArgumentError('Timelines cannot have deadlines.');
    }
    if (targetDays != null && targetDays <= 0) {
      throw ArgumentError('Required duration must be at least one day.');
    }
    if (entryType == TimelineEntryType.timeline && targetDays != null) {
      throw ArgumentError('Timelines cannot have a required duration.');
    }
    _validateTimelineDates(
      startDate: storedStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      today: today,
      checkIns: _checkIns[goal.id!] ?? const [],
      pausePeriods: _pausePeriods[goal.id!] ?? const [],
    );
    final expectedActivation = selectedPrerequisite == null
        ? storedStart
        : selectedPrerequisite.isAchieved
            ? automaticStart
                ? selectedPrerequisite.completionDate!
                : _laterDate(
                    storedStart,
                    selectedPrerequisite.completionDate!,
                  )
            : goal.activationDate;
    if (expectedActivation != null && expectedActivation.isAfter(today)) {
      await _requestReminderPermissionSafely();
    }
    await _runMutation(() async {
      final prerequisiteIds = existingPrerequisiteIds.length > 1 &&
              prerequisiteId == existingPrerequisiteId
          ? existingPrerequisiteIds
          : prerequisiteId == null
              ? const <int>[]
              : <int>[prerequisiteId];
      final unlockedIds = await _databaseHelper.updateGoalWithDependencies(
        goal: goal.copyWith(
          name: normalizedName,
          description: description.trim(),
          startDate: storedStart,
          startsAutomaticallyAfterPrerequisites: automaticStart,
          completionDate: normalizedCompletion,
          clearCompletionDate: normalizedCompletion == null,
          deadlineDate: normalizedDeadline,
          clearDeadlineDate: normalizedDeadline == null,
          targetDays: targetDays,
          clearTargetDays: targetDays == null,
          status: goal.isFailed
              ? GoalStatus.failed
              : normalizedCompletion == null
                  ? GoalStatus.active
                  : GoalStatus.achieved,
          entryType: entryType,
          collectionId: collectionId,
          clearCollectionId: collectionId == null,
          updatedAtEpochMs: _now().millisecondsSinceEpoch,
        ),
        prerequisiteGoalIds: prerequisiteIds,
      );
      await refresh();
      for (final goalId in unlockedIds) {
        final unlocked = goalById(goalId);
        if (unlocked != null) await _notifyUnlockedSafely(unlocked);
      }
    });
  }

  void _validateTimelineDates({
    required DateTime startDate,
    required DateTime? completionDate,
    required DateTime? deadlineDate,
    required DateTime today,
    List<GoalCheckIn> checkIns = const [],
    List<GoalPausePeriod> pausePeriods = const [],
  }) {
    if (completionDate != null && completionDate.isAfter(today)) {
      throw ArgumentError('Ending date cannot be in the future.');
    }
    if (completionDate != null && completionDate.isBefore(startDate)) {
      throw ArgumentError('Ending date cannot be before the start date.');
    }
    if (deadlineDate != null && deadlineDate.isBefore(startDate)) {
      throw ArgumentError('Deadline cannot be before the start date.');
    }
    for (final checkIn in checkIns) {
      if (checkIn.date.isBefore(startDate)) {
        throw ArgumentError(
          'Starting date cannot be after an existing check-in.',
        );
      }
      if (completionDate != null && checkIn.date.isAfter(completionDate)) {
        throw ArgumentError(
          'Ending date cannot be before an existing check-in.',
        );
      }
    }
    for (final period in pausePeriods) {
      if (period.startDate.isBefore(startDate)) {
        throw ArgumentError(
          'Starting date cannot be after an existing pause.',
        );
      }
      final pauseEnd = period.resumeDate;
      if (completionDate != null &&
          (period.startDate.isAfter(completionDate) ||
              (pauseEnd != null && pauseEnd.isAfter(completionDate)))) {
        throw ArgumentError(
          'Ending date cannot be before an existing pause.',
        );
      }
    }
  }

  Future<void> deleteGoal(MotionGoal goal) async {
    _requireCurrentGoalOwner(goal);
    await _runMutation(() async {
      await _databaseHelper.deleteGoal(
        goalId: goal.id!,
        currentUser: goal.currentLoggedInUser,
      );
      await refresh();
    });
  }

  Future<MotionTimelineCollection> createCollection(String name) async {
    final user = requireCurrentUser(_userUidProvider.userUid ?? '');
    final normalizedName = _normalizedCollectionName(name);
    final now = _now().millisecondsSinceEpoch;
    final collection = MotionTimelineCollection(
      currentLoggedInUser: user,
      name: normalizedName,
      createdAtEpochMs: now,
      updatedAtEpochMs: now,
    );
    return _runMutation(() async {
      final id = await _databaseHelper.insertTimelineCollection(collection);
      await refresh();
      if (_userUidProvider.userUid?.trim() != user) {
        throw StateError(
          'The signed-in Motion account changed. Refresh and try again.',
        );
      }
      return collectionById(id) ?? collection.copyWith(id: id);
    });
  }

  Future<void> renameCollection(
    MotionTimelineCollection collection,
    String name,
  ) async {
    _requireCurrentCollectionOwner(collection);
    final normalizedName = _normalizedCollectionName(name);
    await _runMutation(() async {
      await _databaseHelper.updateTimelineCollection(collection.copyWith(
        name: normalizedName,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      ));
      await refresh();
    });
  }

  Future<void> deleteCollection(
    MotionTimelineCollection collection,
  ) async {
    _requireCurrentCollectionOwner(collection);
    await _runMutation(() async {
      await _databaseHelper.deleteTimelineCollection(
        collectionId: collection.id!,
        currentUser: collection.currentLoggedInUser,
      );
      if (_selectedCollectionId == collection.id) {
        _showAllCollections = true;
        _selectedCollectionId = null;
      }
      await refresh();
    });
  }

  Future<void> toggleCheckIn(MotionGoal goal, DateTime date) async {
    _requireCurrentGoalOwner(goal);
    if (goal.isLocked) {
      throw StateError('Complete the prerequisite before checking in.');
    }
    if (isDatePaused(goal, date)) {
      throw StateError('Effort cannot be marked on a paused day.');
    }
    await _runMutation(() async {
      await _databaseHelper.toggleGoalCheckIn(
        goal: goal,
        date: date,
        today: today,
      );
      final checkIns = await _databaseHelper.getGoalCheckIns(
        goalId: goal.id!,
        currentUser: goal.currentLoggedInUser,
      );
      _requireCurrentGoalOwner(goal);
      _checkIns[goal.id!] = checkIns;
      notifyListeners();
    });
  }

  Future<void> markAchieved(MotionGoal goal) async {
    _requireCurrentGoalOwner(goal);
    if (!goal.isActive) {
      throw StateError('Only an active entry can be completed.');
    }
    if (goal.isLocked) {
      throw StateError('Complete the prerequisite before this entry starts.');
    }
    if (isUpcoming(goal)) {
      throw StateError('This entry has not started yet.');
    }
    final targetDays = goal.targetDays;
    final activeDays = activeDaysFor(goal);
    if (targetDays != null && activeDays < targetDays) {
      final remaining = targetDays - activeDays;
      throw StateError(
        '$remaining more active ${remaining == 1 ? 'day is' : 'days are'} required before this goal can be achieved.',
      );
    }
    await _runMutation(() async {
      final unlockedIds =
          await _databaseHelper.markGoalAchievedAndUnlockDependents(
        goal.copyWith(
          completionDate: today,
          status: GoalStatus.achieved,
          updatedAtEpochMs: _now().millisecondsSinceEpoch,
        ),
      );
      await refresh();
      for (final unlockedId in unlockedIds) {
        final unlocked = goalById(unlockedId);
        if (unlocked != null) {
          await _notifyUnlockedSafely(unlocked);
        }
      }
    });
  }

  Future<void> markFailed(MotionGoal goal, {String reason = ''}) async {
    _requireCurrentGoalOwner(goal);
    if (!goal.isGoal) throw StateError('Only goals can be marked as failed.');
    if (!goal.isActive) throw StateError('This goal has already ended.');
    if (goal.isLocked) {
      throw StateError('This goal has not started because it is still locked.');
    }
    if (isUpcoming(goal)) throw StateError('This goal has not started yet.');
    final normalizedReason = reason.trim();
    if (normalizedReason.length > 200) {
      throw ArgumentError('Failure notes can contain up to 200 characters.');
    }
    await _runMutation(() async {
      await _databaseHelper.updateGoal(
        goal.copyWith(
          failureDate: today,
          failureReason: normalizedReason,
          status: GoalStatus.failed,
          updatedAtEpochMs: _now().millisecondsSinceEpoch,
        ),
      );
      await refresh();
    });
  }

  Future<MotionGoal> retryGoal(
    MotionGoal failedGoal, {
    required DateTime startDate,
  }) async {
    _requireCurrentGoalOwner(failedGoal);
    if (!failedGoal.isFailed || !failedGoal.isGoal || failedGoal.id == null) {
      throw StateError('Only a failed goal can be tried again.');
    }
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    final originalDeadline = failedGoal.deadlineDate;
    final deadlineSpan =
        originalDeadline?.difference(failedGoal.effectiveStartDate).inDays;
    final retryDeadline = deadlineSpan == null
        ? null
        : normalizedStart.add(Duration(days: deadlineSpan));
    return createGoal(
      name: failedGoal.name,
      description: failedGoal.description,
      startDate: normalizedStart,
      deadlineDate: retryDeadline,
      targetDays: failedGoal.targetDays,
      retryOfGoalId: failedGoal.id,
      entryType: TimelineEntryType.goal,
      collectionId: failedGoal.collectionId,
      prerequisiteId: primaryPrerequisiteIdFor(failedGoal),
      startsAutomaticallyAfterPrerequisites:
          failedGoal.startsAutomaticallyAfterPrerequisites,
    );
  }

  Future<void> pauseGoal(MotionGoal goal, {String reason = ''}) async {
    _requireCurrentGoalOwner(goal);
    if (!goal.isGoal) throw StateError('Only goals can be paused.');
    if (goal.hasEnded) throw StateError('A finished goal cannot be paused.');
    if (goal.isLocked) {
      throw StateError('Complete the prerequisite before this goal starts.');
    }
    if (isUpcoming(goal)) throw StateError('This goal has not started yet.');
    if (isPaused(goal)) throw StateError('This goal is already paused.');
    final normalizedReason = reason.trim();
    if (normalizedReason.length > 200) {
      throw ArgumentError('Pause notes can contain up to 200 characters.');
    }
    await _runMutation(() async {
      await _databaseHelper.pauseGoal(
        goal: goal,
        startDate: today,
        reason: normalizedReason,
      );
      await refresh();
    });
  }

  Future<void> resumePausedGoal(MotionGoal goal) async {
    _requireCurrentGoalOwner(goal);
    if (!isPaused(goal)) throw StateError('This goal is not paused.');
    await _runMutation(() async {
      await _databaseHelper.resumeGoal(goal: goal, resumeDate: today);
      await refresh();
    });
  }

  Future<void> reopenGoal(MotionGoal goal) async {
    _requireCurrentGoalOwner(goal);
    if (!goal.isAchieved) {
      throw StateError('Only an achieved entry can be reopened.');
    }
    await _runMutation(() async {
      await _databaseHelper.updateGoal(goal.copyWith(
        clearCompletionDate: true,
        status: GoalStatus.active,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      ));
      await refresh();
    });
  }

  Future<T> _runMutation<T>(Future<T> Function() operation) async {
    _activeMutations++;
    _error = null;
    notifyListeners();
    try {
      return await operation();
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _activeMutations--;
      notifyListeners();
    }
  }

  Future<void> _requestReminderPermissionSafely() async {
    try {
      _reminderPermissionGranted = await _reminderBridge.requestPermission();
    } catch (error) {
      debugPrint('Goal reminder permission failed: $error');
      _reminderPermissionGranted = false;
    }
  }

  Future<void> _syncStartRemindersSafely() async {
    try {
      final reminders = _goals
          .where(
            (goal) =>
                goal.id != null &&
                !goal.isLocked &&
                goal.isActive &&
                goal.effectiveStartDate.isAfter(today),
          )
          .map(
            (goal) => GoalStartReminder(
              goalId: goal.id!,
              name: goal.name,
              entryType: goal.entryType,
              startDate: goal.effectiveStartDate,
            ),
          )
          .toList(growable: false);
      await _reminderBridge.sync(reminders);
    } catch (error) {
      debugPrint('Goal reminder synchronization failed: $error');
    }
  }

  Future<void> _notifyUnlockedSafely(MotionGoal goal) async {
    try {
      await _reminderBridge.notifyUnlocked(goal);
    } catch (error) {
      debugPrint('Goal unlock notification failed: $error');
    }
  }

  void _requireCurrentGoalOwner(MotionGoal goal) {
    final currentUser = requireCurrentUser(_userUidProvider.userUid ?? '');
    if (goal.currentLoggedInUser != currentUser) {
      throw StateError(
        'This timeline belongs to a different Motion account. Refresh and try again.',
      );
    }
  }

  void _requireCurrentCollectionOwner(
    MotionTimelineCollection collection,
  ) {
    final currentUser = requireCurrentUser(_userUidProvider.userUid ?? '');
    if (collection.currentLoggedInUser != currentUser) {
      throw StateError(
        'This collection belongs to a different Motion account. Refresh and try again.',
      );
    }
  }

  void _validateCollectionSelection(int? collectionId) {
    if (collectionId != null && collectionById(collectionId) == null) {
      throw StateError('The selected collection is unavailable.');
    }
  }

  MotionGoal? _validatePrerequisiteSelection({
    required int? prerequisiteId,
    required int? collectionId,
    MotionGoal? editingGoal,
  }) {
    if (prerequisiteId == null) return null;
    if (collectionId == null) {
      throw StateError(
        'Choose a collection before adding a prerequisite.',
      );
    }
    final prerequisite = goalById(prerequisiteId);
    if (prerequisite == null) {
      throw StateError('The selected prerequisite is unavailable.');
    }
    if (prerequisite.collectionId != collectionId) {
      throw StateError('Linked entries must belong to the same collection.');
    }
    if (editingGoal != null &&
        invalidPrerequisiteIdsFor(editingGoal).contains(prerequisiteId)) {
      throw StateError('This link would create a circular progression.');
    }
    return prerequisite;
  }

  DateTime _laterDate(DateTime first, DateTime second) {
    return first.isAfter(second) ? first : second;
  }

  String _normalizedCollectionName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError('Enter a collection name.');
    if (normalized.length > 60) {
      throw ArgumentError('Collection names can contain up to 60 characters.');
    }
    return normalized;
  }

  void _handleUserChanged() {
    final user = _userUidProvider.userUid?.trim();
    if (user == _loadedUser) return;
    unawaited(refresh());
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = _now();
    final nextDay = DateTime(now.year, now.month, now.day + 1, 0, 0, 2);
    _midnightTimer = Timer(nextDay.difference(now), () {
      notifyListeners();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notifyListeners();
      _scheduleMidnightRefresh();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _userUidProvider.removeListener(_handleUserChanged);
    super.dispose();
  }
}
