import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/current_user_guard.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum GoalFilter { all, active, achieved }

class GoalTrackerProvider extends ChangeNotifier with WidgetsBindingObserver {
  GoalTrackerProvider({
    required UserUidProvider userUidProvider,
    TrackerDatabaseHelper? databaseHelper,
    DateTime Function()? now,
  })  : _userUidProvider = userUidProvider,
        _databaseHelper = databaseHelper ?? TrackerDatabaseHelper(),
        _now = now ?? DateTime.now {
    _userUidProvider.addListener(_handleUserChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final UserUidProvider _userUidProvider;
  final TrackerDatabaseHelper _databaseHelper;
  final DateTime Function() _now;
  final Map<int, List<GoalCheckIn>> _checkIns = {};
  final Map<int, List<GoalPausePeriod>> _pausePeriods = {};
  List<MotionGoal> _goals = const [];
  List<MotionTimelineCollection> _collections = const [];
  GoalFilter _filter = GoalFilter.all;
  bool _showAllCollections = true;
  int? _selectedCollectionId;
  bool _isLoading = false;
  int _activeMutations = 0;
  Object? _error;
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
  DateTime get today => MotionDateUtils.today(now: _now);

  List<MotionGoal> get filteredGoals {
    final statusFiltered = switch (_filter) {
      GoalFilter.all => goals,
      GoalFilter.active =>
        goals.where((goal) => !goal.isAchieved).toList(growable: false),
      GoalFilter.achieved =>
        goals.where((goal) => goal.isAchieved).toList(growable: false),
    };
    if (_showAllCollections) return statusFiltered;
    return statusFiltered
        .where((goal) => goal.collectionId == _selectedCollectionId)
        .toList(growable: false);
  }

  int get activeCount => _goals.where((goal) => !goal.isAchieved).length;
  int get achievedCount => _goals.where((goal) => goal.isAchieved).length;

  List<GoalCheckIn> checkInsFor(int goalId) =>
      List.unmodifiable(_checkIns[goalId] ?? const []);

  List<GoalPausePeriod> pausePeriodsFor(int goalId) =>
      List.unmodifiable(_pausePeriods[goalId] ?? const []);

  bool isPaused(MotionGoal goal) =>
      (_pausePeriods[goal.id] ?? const []).any((period) => period.isOpen);

  bool isDatePaused(MotionGoal goal, DateTime date) {
    final normalizedDate = MotionDateUtils.dateOnly(date);
    return (_pausePeriods[goal.id] ?? const []).any((period) {
      final resumeDate = period.resumeDate;
      return !normalizedDate.isBefore(period.startDate) &&
          (resumeDate == null || normalizedDate.isBefore(resumeDate));
    });
  }

  int pausedDaysFor(MotionGoal goal) {
    final endDate = goal.completionDate ?? today;
    var pausedDays = 0;
    for (final period in _pausePeriods[goal.id] ?? const <GoalPausePeriod>[]) {
      final start = period.startDate.isBefore(goal.startDate)
          ? goal.startDate
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
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final collections =
          await _databaseHelper.getTimelineCollections(currentUser: user);
      final goals = await _databaseHelper.getGoals(currentUser: user);
      final checkIns = await _databaseHelper.getAllGoalCheckIns(
        currentUser: user,
      );
      final pausePeriods = await _databaseHelper.getAllGoalPausePeriods(
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
    TimelineEntryType entryType = TimelineEntryType.timeline,
    int? collectionId,
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
    _validateTimelineDates(
      startDate: normalizedStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      today: today,
    );
    if (entryType == TimelineEntryType.timeline && normalizedDeadline != null) {
      throw ArgumentError('Timelines cannot have deadlines.');
    }
    _validateCollectionSelection(collectionId);
    final goal = MotionGoal(
      currentLoggedInUser: user,
      name: normalizedName,
      description: description.trim(),
      startDate: normalizedStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      status: normalizedCompletion == null
          ? GoalStatus.active
          : GoalStatus.achieved,
      entryType: entryType,
      collectionId: collectionId,
      createdAtEpochMs: now.millisecondsSinceEpoch,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
    );
    return _runMutation(() async {
      final id = await _databaseHelper.insertGoal(goal);
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
    required TimelineEntryType entryType,
    int? collectionId,
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
    if (entryType == TimelineEntryType.timeline &&
        (_pausePeriods[goal.id!] ?? const []).isNotEmpty) {
      throw StateError(
        'A goal with pause history cannot be changed into a timeline.',
      );
    }
    if (entryType == TimelineEntryType.timeline && normalizedDeadline != null) {
      throw ArgumentError('Timelines cannot have deadlines.');
    }
    _validateTimelineDates(
      startDate: normalizedStart,
      completionDate: normalizedCompletion,
      deadlineDate: normalizedDeadline,
      today: today,
      checkIns: _checkIns[goal.id!] ?? const [],
      pausePeriods: _pausePeriods[goal.id!] ?? const [],
    );
    await _runMutation(() async {
      await _databaseHelper.updateGoal(goal.copyWith(
        name: normalizedName,
        description: description.trim(),
        startDate: normalizedStart,
        completionDate: normalizedCompletion,
        clearCompletionDate: normalizedCompletion == null,
        deadlineDate: normalizedDeadline,
        clearDeadlineDate: normalizedDeadline == null,
        status: normalizedCompletion == null
            ? GoalStatus.active
            : GoalStatus.achieved,
        entryType: entryType,
        collectionId: collectionId,
        clearCollectionId: collectionId == null,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      ));
      await refresh();
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
    if (startDate.isAfter(today)) {
      throw ArgumentError('Starting date cannot be in the future.');
    }
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
    await _runMutation(() async {
      await _databaseHelper.updateGoal(goal.copyWith(
        completionDate: today,
        status: GoalStatus.achieved,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      ));
      await refresh();
    });
  }

  Future<void> pauseGoal(MotionGoal goal, {String reason = ''}) async {
    _requireCurrentGoalOwner(goal);
    if (!goal.isGoal) throw StateError('Only goals can be paused.');
    if (goal.isAchieved) throw StateError('An achieved goal cannot be paused.');
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
