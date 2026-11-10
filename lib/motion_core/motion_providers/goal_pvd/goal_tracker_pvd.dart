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
  List<MotionGoal> _goals = const [];
  GoalFilter _filter = GoalFilter.all;
  bool _isLoading = false;
  int _activeMutations = 0;
  Object? _error;
  String? _loadedUser;
  Timer? _midnightTimer;
  int _loadGeneration = 0;

  List<MotionGoal> get goals => List.unmodifiable(_goals);
  GoalFilter get filter => _filter;
  bool get isLoading => _isLoading;
  bool get isSaving => _activeMutations > 0;
  Object? get error => _error;
  DateTime get today => MotionDateUtils.today(now: _now);

  List<MotionGoal> get filteredGoals {
    return switch (_filter) {
      GoalFilter.all => goals,
      GoalFilter.active =>
        goals.where((goal) => !goal.isAchieved).toList(growable: false),
      GoalFilter.achieved =>
        goals.where((goal) => goal.isAchieved).toList(growable: false),
    };
  }

  int get activeCount => _goals.where((goal) => !goal.isAchieved).length;
  int get achievedCount => _goals.where((goal) => goal.isAchieved).length;

  List<GoalCheckIn> checkInsFor(int goalId) =>
      List.unmodifiable(_checkIns[goalId] ?? const []);

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

  void setFilter(GoalFilter value) {
    if (_filter == value) return;
    _filter = value;
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
      _checkIns.clear();
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final goals = await _databaseHelper.getGoals(currentUser: user);
      final checkIns = await _databaseHelper.getAllGoalCheckIns(
        currentUser: user,
      );
      if (loadGeneration != _loadGeneration ||
          _userUidProvider.userUid?.trim() != user) {
        return;
      }
      _goals = goals;
      _loadedUser = user;
      _checkIns.clear();
      for (final checkIn in checkIns) {
        _checkIns.putIfAbsent(checkIn.goalId, () => []).add(checkIn);
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
  }) async {
    final user = requireCurrentUser(_userUidProvider.userUid ?? '');
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Enter a goal name.');
    final now = _now();
    final goal = MotionGoal(
      currentLoggedInUser: user,
      name: normalizedName,
      description: description.trim(),
      startDate: MotionDateUtils.dateOnly(startDate),
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
  }) async {
    _requireCurrentGoalOwner(goal);
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Enter a goal name.');
    final normalizedStart = MotionDateUtils.dateOnly(startDate);
    if (goal.completionDate != null &&
        normalizedStart.isAfter(goal.completionDate!)) {
      throw ArgumentError('Start date cannot be after completion.');
    }
    await _runMutation(() async {
      await _databaseHelper.updateGoal(goal.copyWith(
        name: normalizedName,
        description: description.trim(),
        startDate: normalizedStart,
        updatedAtEpochMs: _now().millisecondsSinceEpoch,
      ));
      await refresh();
    });
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

  Future<void> toggleCheckIn(MotionGoal goal, DateTime date) async {
    _requireCurrentGoalOwner(goal);
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
        'This goal belongs to a different Motion account. Refresh and try again.',
      );
    }
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
