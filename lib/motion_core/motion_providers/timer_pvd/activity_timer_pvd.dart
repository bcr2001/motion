import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:motion/motion_core/mc_sql_table/activity_timer_session.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_services/activity_timer_notification_bridge.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

typedef MotionClock = DateTime Function();

class ActivityTimerAlreadyRunning implements Exception {
  final ActivityTimerSession session;

  const ActivityTimerAlreadyRunning(this.session);
}

class ActivityTimerFinishResult {
  final List<Subcategories> entries;
  final int totalSeconds;

  const ActivityTimerFinishResult({
    required this.entries,
    required this.totalSeconds,
  });
}

class ActivityTimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  ActivityTimerProvider({
    required UserUidProvider userUidProvider,
    required SubcategoryTrackerDatabaseProvider subcategoryProvider,
    TrackerDatabaseHelper? databaseHelper,
    ActivityTimerNotificationBridge? notificationBridge,
    MotionClock? clock,
  })  : _userUidProvider = userUidProvider,
        _subcategoryProvider = subcategoryProvider,
        _databaseHelper = databaseHelper ?? TrackerDatabaseHelper(),
        _notificationBridge =
            notificationBridge ?? PlatformActivityTimerNotificationBridge(),
        _clock = clock ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    _userUidProvider.addListener(_handleUserChanged);
  }

  static const int standardReminderSeconds = 2 * 60 * 60;
  static const int sleepReminderSeconds = 10 * 60 * 60;
  static const int reviewRequiredSeconds = 18 * 60 * 60;

  final UserUidProvider _userUidProvider;
  final SubcategoryTrackerDatabaseProvider _subcategoryProvider;
  final TrackerDatabaseHelper _databaseHelper;
  final ActivityTimerNotificationBridge _notificationBridge;
  final MotionClock _clock;

  ActivityTimerSession? _session;
  Timer? _ticker;
  bool _isInitialized = false;
  bool _isBusy = false;
  String? _loadedUser;
  int _restoreGeneration = 0;
  bool? _notificationPermissionGranted;

  ActivityTimerSession? get session => _session;
  bool get hasActiveTimer => _session != null;
  bool get isBusy => _isBusy;
  bool get isInitialized => _isInitialized;
  bool get isRunning => _session?.isRunning ?? false;
  bool get isPaused => hasActiveTimer && !isRunning;
  bool? get notificationPermissionGranted => _notificationPermissionGranted;

  int get elapsedSeconds => _session?.elapsedSecondsAt(_clock()) ?? 0;

  bool get needsReview => elapsedSeconds >= reviewRequiredSeconds;

  bool get isReminderDue {
    final activeSession = _session;
    return activeSession != null &&
        activeSession.isRunning &&
        elapsedSeconds >= activeSession.nextReminderAtSeconds;
  }

  bool isActiveFor({
    required String mainCategoryName,
    required String subcategoryName,
  }) {
    return _session?.mainCategoryName == mainCategoryName &&
        _session?.subcategoryName == subcategoryName;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _restoreForCurrentUser();
  }

  Future<void> start({
    required String mainCategoryName,
    required String subcategoryName,
  }) async {
    if (_isBusy) return;
    await _runBusy(() async {
      final currentUser = _userUidProvider.userUid;
      if (currentUser == null || currentUser.trim().isEmpty) {
        throw StateError('The user account is still loading.');
      }

      if (_loadedUser != currentUser) {
        await _restoreForCurrentUser();
      }
      final existingSession = _session;
      if (existingSession != null) {
        throw ActivityTimerAlreadyRunning(existingSession);
      }

      _notificationPermissionGranted = await _requestNotificationPermission();

      final now = _clock();
      final reminderSeconds = mainCategoryName == MotionCategories.sleep
          ? sleepReminderSeconds
          : standardReminderSeconds;
      final nextSession = ActivityTimerSession(
        currentLoggedInUser: currentUser,
        mainCategoryName: mainCategoryName,
        subcategoryName: subcategoryName,
        startedAtEpochMs: now.millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs: now.millisecondsSinceEpoch,
        completedSegments: const [],
        status: ActivityTimerStatus.running,
        updatedAtEpochMs: now.millisecondsSinceEpoch,
        nextReminderAtSeconds: reminderSeconds,
      );

      await _databaseHelper.saveActiveTimerSession(nextSession);
      _loadedUser = currentUser;
      _session = nextSession;
      _startTicker();
      await _syncSystemNotification(nextSession);
    });
  }

  Future<void> pause() async {
    final activeSession = _session;
    if (_isBusy || activeSession == null || !activeSession.isRunning) return;

    final now = _clock();
    final segments = activeSession.segmentsEndingAt(now);
    final pausedSession = activeSession.copyWith(
      currentSegmentStartedAtEpochMs: null,
      completedSegments: segments,
      status: ActivityTimerStatus.paused,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
    );

    await _runBusy(() async {
      await _databaseHelper.saveActiveTimerSession(pausedSession);
      _session = pausedSession;
      _stopTicker();
      await _syncSystemNotification(pausedSession);
    });
  }

  Future<void> resume() async {
    final activeSession = _session;
    if (_isBusy || activeSession == null || activeSession.isRunning) return;

    final now = _clock();
    final resumedSession = activeSession.copyWith(
      currentSegmentStartedAtEpochMs: now.millisecondsSinceEpoch,
      status: ActivityTimerStatus.running,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
    );

    await _runBusy(() async {
      if (_notificationPermissionGranted != true) {
        _notificationPermissionGranted = await _requestNotificationPermission();
      }
      await _databaseHelper.saveActiveTimerSession(resumedSession);
      _session = resumedSession;
      _startTicker();
      await _syncSystemNotification(resumedSession);
    });
  }

  Future<void> acknowledgeReminder() async {
    final activeSession = _session;
    if (activeSession == null) return;
    final interval = activeSession.mainCategoryName == MotionCategories.sleep
        ? sleepReminderSeconds
        : standardReminderSeconds;
    final updatedSession = activeSession.copyWith(
      nextReminderAtSeconds: elapsedSeconds + interval,
      updatedAtEpochMs: _clock().millisecondsSinceEpoch,
    );
    await _databaseHelper.saveActiveTimerSession(updatedSession);
    _session = updatedSession;
    notifyListeners();
  }

  Future<void> discard() async {
    final activeSession = _session;
    if (_isBusy || activeSession == null) return;
    await _runBusy(() async {
      await _databaseHelper.deleteActiveTimerSession(
        currentUser: activeSession.currentLoggedInUser,
      );
      _clearSession();
      await _stopSystemNotification();
    });
  }

  Future<ActivityTimerFinishResult> finish({int? correctedSeconds}) async {
    final activeSession = _session;
    if (activeSession == null) {
      throw StateError('There is no active timer to finish.');
    }
    if (_isBusy) {
      throw StateError('The timer is already being updated.');
    }

    final now = _clock();
    final exactSegments = activeSession.segmentsEndingAt(now);
    final exactSeconds = activeSession.elapsedSecondsAt(now);
    final totalSeconds = correctedSeconds ?? exactSeconds;
    if (totalSeconds <= 0) {
      throw StateError('The timer duration must be greater than zero.');
    }

    final segments = correctedSeconds == null
        ? exactSegments
        : [
            ActivityTimerSegment(
              startedAtEpochMs: activeSession.startedAtEpochMs,
              endedAtEpochMs:
                  activeSession.startedAtEpochMs + totalSeconds * 1000,
            ),
          ];
    final secondsByDate = splitTimerSegmentsByDate(segments);
    final entries = secondsByDate.entries
        .where((entry) => entry.value > 0)
        .map((entry) => Subcategories(
              date: entry.key,
              mainCategoryName: activeSession.mainCategoryName,
              subcategoryName: activeSession.subcategoryName,
              timeSpent: entry.value / 60,
              currentLoggedInUser: activeSession.currentLoggedInUser,
            ))
        .toList(growable: false);

    if (entries.isEmpty) {
      throw StateError('The timer did not contain any trackable time.');
    }

    late List<Subcategories> savedEntries;
    await _runBusy(() async {
      savedEntries = await _subcategoryProvider.completeActivityTimer(
        currentUser: activeSession.currentLoggedInUser,
        entries: entries,
      );
      _clearSession();
      await _stopSystemNotification();
    });
    return ActivityTimerFinishResult(
      entries: savedEntries,
      totalSeconds: totalSeconds,
    );
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    _isBusy = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _handleUserChanged() {
    unawaited(_restoreForCurrentUser());
  }

  Future<void> _restoreForCurrentUser() async {
    final currentUser = _userUidProvider.userUid;
    final generation = ++_restoreGeneration;
    if (currentUser == null) {
      _loadedUser = null;
      _clearSession();
      await _stopSystemNotification();
      notifyListeners();
      return;
    }
    if (_loadedUser == currentUser && _session != null) return;

    final restoredSession = await _databaseHelper.getActiveTimerSession(
      currentUser: currentUser,
    );
    if (generation != _restoreGeneration ||
        _userUidProvider.userUid != currentUser) {
      return;
    }
    _loadedUser = currentUser;
    _session = restoredSession;
    if (restoredSession?.isRunning ?? false) {
      _startTicker();
    } else {
      _stopTicker();
    }
    if (restoredSession == null) {
      await _stopSystemNotification();
    } else {
      await _syncSystemNotification(restoredSession);
    }
    notifyListeners();
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      return await _notificationBridge.requestPermission();
    } catch (error) {
      debugPrint('Activity timer notification permission failed: $error');
      return false;
    }
  }

  Future<void> _syncSystemNotification(
    ActivityTimerSession activeSession,
  ) async {
    try {
      await _notificationBridge.sync(
        session: activeSession,
        elapsedSeconds: activeSession.elapsedSecondsAt(_clock()),
      );
    } catch (error) {
      debugPrint('Activity timer notification update failed: $error');
    }
  }

  Future<void> _stopSystemNotification() async {
    try {
      await _notificationBridge.stop();
    } catch (error) {
      debugPrint('Activity timer notification stop failed: $error');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _clearSession() {
    _session = null;
    _stopTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_session?.isRunning ?? false) _startTicker();
      notifyListeners();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userUidProvider.removeListener(_handleUserChanged);
    _stopTicker();
    super.dispose();
  }
}

Map<String, double> splitTimerSegmentsByDate(
  List<ActivityTimerSegment> segments,
) {
  final secondsByDate = <String, double>{};
  for (final segment in segments) {
    var cursor = DateTime.fromMillisecondsSinceEpoch(segment.startedAtEpochMs);
    final end = DateTime.fromMillisecondsSinceEpoch(segment.endedAtEpochMs);
    if (!end.isAfter(cursor)) continue;

    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final boundary = end.isBefore(nextMidnight) ? end : nextMidnight;
      final seconds = boundary.difference(cursor).inMilliseconds / 1000;
      final date = MotionDateUtils.formatDbDate(cursor);
      secondsByDate[date] = (secondsByDate[date] ?? 0) + seconds;
      cursor = boundary;
    }
  }
  return secondsByDate;
}

String formatActivityTimerDuration(int totalSeconds) {
  final safeSeconds = totalSeconds.clamp(0, 1 << 31).toInt();
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  final seconds = safeSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
