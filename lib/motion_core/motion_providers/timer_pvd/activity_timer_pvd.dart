import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:motion/motion_core/mc_sql_table/activity_timer_session.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
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

class PomodoroPhaseEvent {
  final PomodoroPhase completedPhase;
  final PomodoroPhase nextPhase;
  final int completedRound;

  const PomodoroPhaseEvent({
    required this.completedPhase,
    required this.nextPhase,
    required this.completedRound,
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

  static const int reviewRequiredSeconds = 18 * 60 * 60;
  static const int maximumTargetSeconds = 24 * 60 * 60;

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
  bool _isMarkingTargetReached = false;
  bool _hasPendingTargetReachedEvent = false;
  bool _isAdvancingPomodoro = false;
  PomodoroPhaseEvent? _pendingPomodoroPhaseEvent;

  ActivityTimerSession? get session => _session;
  bool get hasActiveTimer => _session != null;
  bool get isBusy => _isBusy;
  bool get isInitialized => _isInitialized;
  bool get isRunning => _session?.isRunning ?? false;
  bool get isPaused => hasActiveTimer && !isRunning;
  bool? get notificationPermissionGranted => _notificationPermissionGranted;

  int get elapsedSeconds => _session?.elapsedSecondsAt(_clock()) ?? 0;
  int? get targetSeconds => _session?.activeTargetSeconds;
  bool get isTimedSession => _session?.isTimed ?? false;
  bool get isPomodoroSession => _session?.isPomodoro ?? false;
  PomodoroPhase? get pomodoroPhase => _session?.pomodoroPhase;
  int get pomodoroCurrentRound => _session?.pomodoroCurrentRound ?? 0;
  int get pomodoroTotalRounds => _session?.pomodoroTotalRounds ?? 0;
  int get phaseElapsedSeconds => _session?.phaseElapsedSecondsAt(_clock()) ?? 0;
  bool get hasPendingPomodoroPhaseEvent => _pendingPomodoroPhaseEvent != null;
  bool get hasReachedTarget => _session?.targetReachedAt(_clock()) ?? false;
  bool get hasPendingTargetReachedEvent => _hasPendingTargetReachedEvent;
  int? get remainingTargetSeconds => _session?.remainingSecondsAt(_clock());
  DateTime? get expectedTargetEndAt => _session?.expectedEndAt(_clock());
  int get overtimeSeconds => _session?.overtimeSecondsAt(_clock()) ?? 0;

  bool get needsReview => elapsedSeconds >= reviewRequiredSeconds;

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
    int? targetSeconds,
    PomodoroConfiguration? pomodoro,
  }) async {
    if (_isBusy) return;
    if (targetSeconds != null && pomodoro != null) {
      throw StateError('Choose either a timed session or Pomodoro.');
    }
    if (targetSeconds != null &&
        (targetSeconds <= 0 || targetSeconds > maximumTargetSeconds)) {
      throw StateError('Timer targets must be between 1 second and 24 hours.');
    }
    if (pomodoro != null) {
      _validatePomodoroConfiguration(pomodoro);
    }
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

      _notificationPermissionGranted = await _requestNotificationPermission(
        requiresExactAlarm: targetSeconds != null || pomodoro != null,
      );

      final now = _clock();
      final nextSession = ActivityTimerSession(
        currentLoggedInUser: currentUser,
        mainCategoryName: mainCategoryName,
        subcategoryName: subcategoryName,
        startedAtEpochMs: now.millisecondsSinceEpoch,
        currentSegmentStartedAtEpochMs: now.millisecondsSinceEpoch,
        completedSegments: const [],
        status: ActivityTimerStatus.running,
        updatedAtEpochMs: now.millisecondsSinceEpoch,
        nextReminderAtSeconds: 0,
        targetSeconds: targetSeconds,
        mode: pomodoro != null
            ? ActivityTimerMode.pomodoro
            : targetSeconds != null
                ? ActivityTimerMode.timed
                : ActivityTimerMode.openEnded,
        pomodoroPhase: pomodoro == null ? null : PomodoroPhase.focus,
        pomodoroFocusSeconds: pomodoro?.focusSeconds ?? 0,
        pomodoroShortBreakSeconds: pomodoro?.shortBreakSeconds ?? 0,
        pomodoroLongBreakSeconds: pomodoro?.longBreakSeconds ?? 0,
        pomodoroTotalRounds: pomodoro?.totalRounds ?? 0,
        pomodoroCurrentRound: pomodoro == null ? 0 : 1,
        pomodoroPhaseStartedAtEpochMs:
            pomodoro == null ? null : now.millisecondsSinceEpoch,
      );

      await _databaseHelper.saveActiveTimerSession(nextSession);
      _loadedUser = currentUser;
      _session = nextSession;
      _startTicker();
      await _syncSystemNotification(nextSession);
    });
  }

  Future<void> pause() async {
    await _advancePomodoroPhasesIfNeeded();
    final activeSession = _session;
    if (_isBusy || activeSession == null || !activeSession.isRunning) return;

    final now = _clock();
    final segments = activeSession.segmentsEndingAt(now);
    final pausedSession = activeSession.copyWith(
      currentSegmentStartedAtEpochMs: null,
      completedSegments: segments,
      status: ActivityTimerStatus.paused,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
      pomodoroPhaseStartedAtEpochMs: activeSession.isPomodoro
          ? null
          : activeSession.pomodoroPhaseStartedAtEpochMs,
      pomodoroPhaseElapsedSeconds: activeSession.isPomodoro
          ? activeSession.phaseElapsedSecondsAt(now)
          : activeSession.pomodoroPhaseElapsedSeconds,
    );

    await _runBusy(() async {
      await _databaseHelper.saveActiveTimerSession(pausedSession);
      _session = pausedSession;
      if (_shouldTick(pausedSession)) {
        _startTicker();
      } else {
        _stopTicker();
      }
      await _syncSystemNotification(pausedSession);
    });
    _checkTargetReached();
  }

  Future<void> resume() async {
    final activeSession = _session;
    if (_isBusy ||
        activeSession == null ||
        activeSession.isRunning ||
        activeSession.isWaitingForPomodoroFocus ||
        activeSession.isPomodoroComplete) {
      return;
    }

    final now = _clock();
    final resumedSession = activeSession.copyWith(
      currentSegmentStartedAtEpochMs:
          !activeSession.isPomodoro || activeSession.isPomodoroFocus
              ? now.millisecondsSinceEpoch
              : null,
      status: ActivityTimerStatus.running,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
      pomodoroPhaseStartedAtEpochMs:
          activeSession.isPomodoro ? now.millisecondsSinceEpoch : null,
    );

    await _runBusy(() async {
      if (_notificationPermissionGranted != true) {
        _notificationPermissionGranted = await _requestNotificationPermission(
          requiresExactAlarm: activeSession.isTimed || activeSession.isPomodoro,
        );
      }
      await _databaseHelper.saveActiveTimerSession(resumedSession);
      _session = resumedSession;
      _startTicker();
      await _syncSystemNotification(resumedSession);
    });
    _checkTargetReached();
  }

  Future<void> startNextPomodoroFocus() async {
    final activeSession = _session;
    if (_isBusy ||
        activeSession == null ||
        !activeSession.isWaitingForPomodoroFocus) {
      return;
    }

    final now = _clock();
    final focusedSession = activeSession.copyWith(
      pomodoroPhase: PomodoroPhase.focus,
      pomodoroPhaseStartedAtEpochMs: now.millisecondsSinceEpoch,
      pomodoroPhaseElapsedSeconds: 0,
      currentSegmentStartedAtEpochMs: now.millisecondsSinceEpoch,
      status: ActivityTimerStatus.running,
      updatedAtEpochMs: now.millisecondsSinceEpoch,
      targetAlertTriggered: false,
    );

    await _runBusy(() async {
      await _databaseHelper.saveActiveTimerSession(focusedSession);
      _session = focusedSession;
      _startTicker();
      await _syncSystemNotification(focusedSession);
    });
  }

  ActivityTimerSession? consumeTargetReachedEvent() {
    if (!_hasPendingTargetReachedEvent) return null;
    _hasPendingTargetReachedEvent = false;
    return _session;
  }

  PomodoroPhaseEvent? consumePomodoroPhaseEvent() {
    final event = _pendingPomodoroPhaseEvent;
    _pendingPomodoroPhaseEvent = null;
    return event;
  }

  Future<void> dismissTargetAlert() async {
    try {
      await _notificationBridge.dismissTargetAlert();
    } catch (error) {
      debugPrint('Activity timer target alert dismissal failed: $error');
    }
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
    await _advancePomodoroPhasesIfNeeded();
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
    if (activeSession.isPomodoro &&
        correctedSeconds != null &&
        correctedSeconds != exactSeconds) {
      throw StateError('Pomodoro focus time cannot include break time.');
    }
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
    await _advancePomodoroPhasesIfNeeded(emitEvent: false);
    final currentSession = _session;
    if (_shouldTick(currentSession)) {
      _startTicker();
    } else {
      _stopTicker();
    }
    if (currentSession == null) {
      await _stopSystemNotification();
    } else {
      await _syncSystemNotification(currentSession);
    }
    _checkTargetReached();
    notifyListeners();
  }

  Future<bool> _requestNotificationPermission({
    required bool requiresExactAlarm,
  }) async {
    try {
      return await _notificationBridge.requestPermission(
        requiresExactAlarm: requiresExactAlarm,
      );
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
        elapsedSeconds: activeSession.phaseElapsedSecondsAt(_clock()),
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
      final activeSession = _session;
      if (activeSession?.isPomodoro == true) {
        unawaited(_advancePomodoroPhasesIfNeeded());
        notifyListeners();
      } else if (!_checkTargetReached()) {
        notifyListeners();
      }
    });
  }

  bool _shouldTick(ActivityTimerSession? session) {
    if (session == null) return false;
    if (session.isRunning) return true;
    return session.isTimed && !session.targetReachedAt(_clock());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _clearSession() {
    _session = null;
    _hasPendingTargetReachedEvent = false;
    _pendingPomodoroPhaseEvent = null;
    _isMarkingTargetReached = false;
    _isAdvancingPomodoro = false;
    _stopTicker();
  }

  bool _checkTargetReached() {
    final activeSession = _session;
    if (activeSession == null ||
        activeSession.isPomodoro ||
        activeSession.targetAlertTriggered ||
        _isMarkingTargetReached ||
        !activeSession.targetReachedAt(_clock())) {
      return false;
    }

    final elapsed = activeSession.elapsedSecondsAt(_clock());
    final updatedSession = activeSession.copyWith(
      targetAlertTriggered: true,
      updatedAtEpochMs: _clock().millisecondsSinceEpoch,
    );
    _session = updatedSession;
    _hasPendingTargetReachedEvent = true;
    _isMarkingTargetReached = true;
    notifyListeners();
    unawaited(_persistTargetReached(
      originalSession: activeSession,
      updatedSession: updatedSession,
      elapsedSeconds: elapsed,
    ));
    return true;
  }

  Future<void> _persistTargetReached({
    required ActivityTimerSession originalSession,
    required ActivityTimerSession updatedSession,
    required int elapsedSeconds,
  }) async {
    try {
      await _notificationBridge.targetReached(
        session: originalSession,
        elapsedSeconds: elapsedSeconds,
      );
    } catch (error) {
      debugPrint('Activity timer target alert failed: $error');
    }

    try {
      await _databaseHelper.markActivityTimerTargetAlertTriggered(
        currentUser: updatedSession.currentLoggedInUser,
        timerStartedAtEpochMs: updatedSession.startedAtEpochMs,
      );
    } catch (error) {
      debugPrint('Activity timer target state save failed: $error');
    } finally {
      _isMarkingTargetReached = false;
    }
  }

  void _validatePomodoroConfiguration(PomodoroConfiguration configuration) {
    if (configuration.focusSeconds <= 0 ||
        configuration.shortBreakSeconds <= 0 ||
        configuration.longBreakSeconds <= 0 ||
        configuration.totalRounds <= 0) {
      throw StateError(
          'Pomodoro durations and rounds must be greater than zero.');
    }
    if (configuration.focusSeconds > maximumTargetSeconds ||
        configuration.shortBreakSeconds > maximumTargetSeconds ||
        configuration.longBreakSeconds > maximumTargetSeconds ||
        configuration.totalFocusSeconds > maximumTargetSeconds) {
      throw StateError(
        'A Pomodoro plan cannot contain more than 24 tracked hours.',
      );
    }
  }

  Future<void> _advancePomodoroPhasesIfNeeded({
    bool emitEvent = true,
  }) async {
    if (_isAdvancingPomodoro) return;
    var activeSession = _session;
    if (activeSession == null ||
        !activeSession.isPomodoro ||
        !activeSession.isRunning ||
        !activeSession.targetReachedAt(_clock())) {
      return;
    }

    _isAdvancingPomodoro = true;
    PomodoroPhaseEvent? latestEvent;
    try {
      while (activeSession != null &&
          activeSession.isPomodoro &&
          activeSession.isRunning &&
          activeSession.targetReachedAt(_clock())) {
        final completedPhase = activeSession.pomodoroPhase;
        if (completedPhase != PomodoroPhase.focus &&
            completedPhase != PomodoroPhase.shortBreak &&
            completedPhase != PomodoroPhase.longBreak) {
          break;
        }

        final targetSeconds = activeSession.activeTargetSeconds ?? 0;
        final completedAtEpochMs = activeSession.phaseTargetEndEpochMs() ??
            _clock().millisecondsSinceEpoch;
        late ActivityTimerSession nextSession;

        if (completedPhase == PomodoroPhase.focus) {
          final focusSegments =
              List<ActivityTimerSegment>.from(activeSession.completedSegments);
          final currentStart = activeSession.currentSegmentStartedAtEpochMs;
          if (currentStart != null && completedAtEpochMs > currentStart) {
            focusSegments.add(ActivityTimerSegment(
              startedAtEpochMs: currentStart,
              endedAtEpochMs: completedAtEpochMs,
            ));
          }
          final nextPhase = activeSession.pomodoroCurrentRound >=
                  activeSession.pomodoroTotalRounds
              ? PomodoroPhase.longBreak
              : PomodoroPhase.shortBreak;
          nextSession = activeSession.copyWith(
            currentSegmentStartedAtEpochMs: null,
            completedSegments: focusSegments,
            pomodoroPhase: nextPhase,
            pomodoroPhaseStartedAtEpochMs: completedAtEpochMs,
            pomodoroPhaseElapsedSeconds: 0,
            status: ActivityTimerStatus.running,
            targetAlertTriggered: false,
            updatedAtEpochMs: _clock().millisecondsSinceEpoch,
          );
        } else {
          final isFinalBreak = completedPhase == PomodoroPhase.longBreak;
          final nextPhase = isFinalBreak
              ? PomodoroPhase.complete
              : PomodoroPhase.readyForFocus;
          nextSession = activeSession.copyWith(
            currentSegmentStartedAtEpochMs: null,
            pomodoroPhase: nextPhase,
            pomodoroCurrentRound: isFinalBreak
                ? activeSession.pomodoroCurrentRound
                : activeSession.pomodoroCurrentRound + 1,
            pomodoroPhaseStartedAtEpochMs: null,
            pomodoroPhaseElapsedSeconds: 0,
            status: ActivityTimerStatus.paused,
            targetAlertTriggered: false,
            updatedAtEpochMs: _clock().millisecondsSinceEpoch,
          );
        }

        try {
          await _notificationBridge.targetReached(
            session: activeSession,
            elapsedSeconds: targetSeconds,
          );
        } catch (error) {
          debugPrint('Pomodoro phase alert failed: $error');
        }

        await _databaseHelper.saveActiveTimerSession(nextSession);
        _session = nextSession;
        await _syncSystemNotification(nextSession);
        latestEvent = PomodoroPhaseEvent(
          completedPhase: completedPhase!,
          nextPhase: nextSession.pomodoroPhase!,
          completedRound: activeSession.pomodoroCurrentRound,
        );
        activeSession = nextSession;
      }

      if (emitEvent && latestEvent != null) {
        _pendingPomodoroPhaseEvent = latestEvent;
      }
      if (_shouldTick(_session)) {
        _startTicker();
      } else {
        _stopTicker();
      }
      notifyListeners();
    } finally {
      _isAdvancingPomodoro = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeTimerFromBackground());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTicker();
    }
  }

  Future<void> _resumeTimerFromBackground() async {
    await _advancePomodoroPhasesIfNeeded();
    if (_shouldTick(_session)) _startTicker();
    if (!_checkTargetReached()) notifyListeners();
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
