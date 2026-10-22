import 'dart:convert';

import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

enum ActivityTimerStatus { running, paused }

enum ActivityTimerMode { openEnded, timed, pomodoro }

enum PomodoroPhase {
  focus,
  shortBreak,
  longBreak,
  readyForFocus,
  complete,
}

class PomodoroConfiguration {
  final int focusSeconds;
  final int shortBreakSeconds;
  final int longBreakSeconds;
  final int totalRounds;

  const PomodoroConfiguration({
    required this.focusSeconds,
    required this.shortBreakSeconds,
    required this.longBreakSeconds,
    required this.totalRounds,
  });

  int get totalFocusSeconds => focusSeconds * totalRounds;
}

class ActivityTimerSegment {
  final int startedAtEpochMs;
  final int endedAtEpochMs;

  const ActivityTimerSegment({
    required this.startedAtEpochMs,
    required this.endedAtEpochMs,
  });

  int get durationMilliseconds {
    final duration = endedAtEpochMs - startedAtEpochMs;
    return duration < 0 ? 0 : duration;
  }

  Map<String, int> toJson() => {
        'start': startedAtEpochMs,
        'end': endedAtEpochMs,
      };

  factory ActivityTimerSegment.fromJson(Map<String, dynamic> json) {
    return ActivityTimerSegment(
      startedAtEpochMs: _readInt(json['start']),
      endedAtEpochMs: _readInt(json['end']),
    );
  }
}

class ActivityTimerSession {
  static const _notProvided = Object();

  final String currentLoggedInUser;
  final String mainCategoryName;
  final String subcategoryName;
  final int startedAtEpochMs;
  final int? currentSegmentStartedAtEpochMs;
  final List<ActivityTimerSegment> completedSegments;
  final ActivityTimerStatus status;
  final int updatedAtEpochMs;
  final int nextReminderAtSeconds;
  final int? targetSeconds;
  final bool targetAlertTriggered;
  final ActivityTimerMode mode;
  final PomodoroPhase? pomodoroPhase;
  final int pomodoroFocusSeconds;
  final int pomodoroShortBreakSeconds;
  final int pomodoroLongBreakSeconds;
  final int pomodoroTotalRounds;
  final int pomodoroCurrentRound;
  final int? pomodoroPhaseStartedAtEpochMs;
  final int pomodoroPhaseElapsedSeconds;

  const ActivityTimerSession({
    required this.currentLoggedInUser,
    required this.mainCategoryName,
    required this.subcategoryName,
    required this.startedAtEpochMs,
    required this.currentSegmentStartedAtEpochMs,
    required this.completedSegments,
    required this.status,
    required this.updatedAtEpochMs,
    required this.nextReminderAtSeconds,
    this.targetSeconds,
    this.targetAlertTriggered = false,
    this.mode = ActivityTimerMode.openEnded,
    this.pomodoroPhase,
    this.pomodoroFocusSeconds = 0,
    this.pomodoroShortBreakSeconds = 0,
    this.pomodoroLongBreakSeconds = 0,
    this.pomodoroTotalRounds = 0,
    this.pomodoroCurrentRound = 0,
    this.pomodoroPhaseStartedAtEpochMs,
    this.pomodoroPhaseElapsedSeconds = 0,
  });

  bool get isRunning => status == ActivityTimerStatus.running;
  ActivityTimerMode get effectiveMode {
    if (mode == ActivityTimerMode.openEnded &&
        targetSeconds != null &&
        targetSeconds! > 0) {
      return ActivityTimerMode.timed;
    }
    return mode;
  }

  bool get isTimed => effectiveMode == ActivityTimerMode.timed;
  bool get isPomodoro => effectiveMode == ActivityTimerMode.pomodoro;
  bool get isPomodoroFocus =>
      isPomodoro && pomodoroPhase == PomodoroPhase.focus;
  bool get isPomodoroBreak =>
      isPomodoro &&
      (pomodoroPhase == PomodoroPhase.shortBreak ||
          pomodoroPhase == PomodoroPhase.longBreak);
  bool get isWaitingForPomodoroFocus =>
      isPomodoro && pomodoroPhase == PomodoroPhase.readyForFocus;
  bool get isPomodoroComplete =>
      isPomodoro && pomodoroPhase == PomodoroPhase.complete;

  int? get activeTargetSeconds {
    if (!isPomodoro) return targetSeconds;
    switch (pomodoroPhase) {
      case PomodoroPhase.focus:
        return pomodoroFocusSeconds;
      case PomodoroPhase.shortBreak:
        return pomodoroShortBreakSeconds;
      case PomodoroPhase.longBreak:
        return pomodoroLongBreakSeconds;
      case PomodoroPhase.readyForFocus:
      case PomodoroPhase.complete:
      case null:
        return null;
    }
  }

  int elapsedMillisecondsAt(DateTime now) {
    var total = completedSegments.fold<int>(
      0,
      (sum, segment) => sum + segment.durationMilliseconds,
    );
    final currentStart = currentSegmentStartedAtEpochMs;
    if (isRunning && currentStart != null) {
      final currentDuration = now.millisecondsSinceEpoch - currentStart;
      total += currentDuration < 0 ? 0 : currentDuration;
    }
    return total;
  }

  int elapsedSecondsAt(DateTime now) => elapsedMillisecondsAt(now) ~/ 1000;

  int phaseElapsedSecondsAt(DateTime now) {
    if (!isPomodoro) return elapsedSecondsAt(now);
    var total = pomodoroPhaseElapsedSeconds;
    final phaseStart = pomodoroPhaseStartedAtEpochMs;
    if (isRunning && phaseStart != null) {
      final additional =
          (now.millisecondsSinceEpoch - phaseStart).clamp(0, 1 << 62) ~/ 1000;
      total += additional;
    }
    return total;
  }

  int? remainingSecondsAt(DateTime now) {
    final target = activeTargetSeconds;
    if (target == null || target <= 0) return null;
    return (target - phaseElapsedSecondsAt(now)).clamp(0, target).toInt();
  }

  DateTime? expectedEndAt(DateTime now) {
    final remainingSeconds = remainingSecondsAt(now);
    if (remainingSeconds == null || remainingSeconds <= 0) return null;
    return now.add(Duration(seconds: remainingSeconds));
  }

  int overtimeSecondsAt(DateTime now) {
    final target = activeTargetSeconds;
    if (target == null || target <= 0) return 0;
    final overtime = phaseElapsedSecondsAt(now) - target;
    return overtime < 0 ? 0 : overtime;
  }

  bool targetReachedAt(DateTime now) {
    final target = activeTargetSeconds;
    return target != null && target > 0 && phaseElapsedSecondsAt(now) >= target;
  }

  int? phaseTargetEndEpochMs() {
    final target = activeTargetSeconds;
    final phaseStart = pomodoroPhaseStartedAtEpochMs;
    if (!isPomodoro || target == null || target <= 0 || phaseStart == null) {
      return null;
    }
    final remainingAtStart =
        (target - pomodoroPhaseElapsedSeconds).clamp(0, target).toInt();
    return phaseStart + remainingAtStart * 1000;
  }

  List<ActivityTimerSegment> segmentsEndingAt(DateTime now) {
    final segments = List<ActivityTimerSegment>.from(completedSegments);
    final currentStart = currentSegmentStartedAtEpochMs;
    if (isRunning &&
        currentStart != null &&
        now.millisecondsSinceEpoch > currentStart) {
      segments.add(ActivityTimerSegment(
        startedAtEpochMs: currentStart,
        endedAtEpochMs: now.millisecondsSinceEpoch,
      ));
    }
    return segments;
  }

  ActivityTimerSession copyWith({
    Object? currentSegmentStartedAtEpochMs = _notProvided,
    List<ActivityTimerSegment>? completedSegments,
    ActivityTimerStatus? status,
    int? updatedAtEpochMs,
    int? nextReminderAtSeconds,
    Object? targetSeconds = _notProvided,
    bool? targetAlertTriggered,
    ActivityTimerMode? mode,
    Object? pomodoroPhase = _notProvided,
    int? pomodoroFocusSeconds,
    int? pomodoroShortBreakSeconds,
    int? pomodoroLongBreakSeconds,
    int? pomodoroTotalRounds,
    int? pomodoroCurrentRound,
    Object? pomodoroPhaseStartedAtEpochMs = _notProvided,
    int? pomodoroPhaseElapsedSeconds,
  }) {
    return ActivityTimerSession(
      currentLoggedInUser: currentLoggedInUser,
      mainCategoryName: mainCategoryName,
      subcategoryName: subcategoryName,
      startedAtEpochMs: startedAtEpochMs,
      currentSegmentStartedAtEpochMs:
          identical(currentSegmentStartedAtEpochMs, _notProvided)
              ? this.currentSegmentStartedAtEpochMs
              : currentSegmentStartedAtEpochMs as int?,
      completedSegments: completedSegments ?? this.completedSegments,
      status: status ?? this.status,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      nextReminderAtSeconds:
          nextReminderAtSeconds ?? this.nextReminderAtSeconds,
      targetSeconds: identical(targetSeconds, _notProvided)
          ? this.targetSeconds
          : targetSeconds as int?,
      targetAlertTriggered: targetAlertTriggered ?? this.targetAlertTriggered,
      mode: mode ?? this.mode,
      pomodoroPhase: identical(pomodoroPhase, _notProvided)
          ? this.pomodoroPhase
          : pomodoroPhase as PomodoroPhase?,
      pomodoroFocusSeconds: pomodoroFocusSeconds ?? this.pomodoroFocusSeconds,
      pomodoroShortBreakSeconds:
          pomodoroShortBreakSeconds ?? this.pomodoroShortBreakSeconds,
      pomodoroLongBreakSeconds:
          pomodoroLongBreakSeconds ?? this.pomodoroLongBreakSeconds,
      pomodoroTotalRounds: pomodoroTotalRounds ?? this.pomodoroTotalRounds,
      pomodoroCurrentRound: pomodoroCurrentRound ?? this.pomodoroCurrentRound,
      pomodoroPhaseStartedAtEpochMs:
          identical(pomodoroPhaseStartedAtEpochMs, _notProvided)
              ? this.pomodoroPhaseStartedAtEpochMs
              : pomodoroPhaseStartedAtEpochMs as int?,
      pomodoroPhaseElapsedSeconds:
          pomodoroPhaseElapsedSeconds ?? this.pomodoroPhaseElapsedSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
      MotionDbColumns.mainCategoryName: mainCategoryName,
      MotionDbColumns.subcategoryName: subcategoryName,
      MotionDbColumns.timerStartedAtEpochMs: startedAtEpochMs,
      MotionDbColumns.currentSegmentStartedAtEpochMs:
          currentSegmentStartedAtEpochMs,
      MotionDbColumns.completedTimerSegments: jsonEncode(
          completedSegments.map((segment) => segment.toJson()).toList()),
      MotionDbColumns.timerStatus: status.name,
      MotionDbColumns.timerUpdatedAtEpochMs: updatedAtEpochMs,
      MotionDbColumns.nextTimerReminderAtSeconds: nextReminderAtSeconds,
      MotionDbColumns.timerTargetSeconds: targetSeconds,
      MotionDbColumns.timerTargetAlertTriggered: targetAlertTriggered ? 1 : 0,
      MotionDbColumns.timerMode: effectiveMode.name,
      MotionDbColumns.pomodoroPhase: pomodoroPhase?.name,
      MotionDbColumns.pomodoroFocusSeconds: pomodoroFocusSeconds,
      MotionDbColumns.pomodoroShortBreakSeconds: pomodoroShortBreakSeconds,
      MotionDbColumns.pomodoroLongBreakSeconds: pomodoroLongBreakSeconds,
      MotionDbColumns.pomodoroTotalRounds: pomodoroTotalRounds,
      MotionDbColumns.pomodoroCurrentRound: pomodoroCurrentRound,
      MotionDbColumns.pomodoroPhaseStartedAtEpochMs:
          pomodoroPhaseStartedAtEpochMs,
      MotionDbColumns.pomodoroPhaseElapsedSeconds: pomodoroPhaseElapsedSeconds,
    };
  }

  factory ActivityTimerSession.fromMap(Map<String, dynamic> map) {
    final decodedSegments = jsonDecode(
      map[MotionDbColumns.completedTimerSegments]?.toString() ?? '[]',
    );
    final segments = decodedSegments is List
        ? decodedSegments
            .whereType<Map>()
            .map((segment) => ActivityTimerSegment.fromJson(
                  Map<String, dynamic>.from(segment),
                ))
            .toList(growable: false)
        : const <ActivityTimerSegment>[];

    return ActivityTimerSession(
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      mainCategoryName: map[MotionDbColumns.mainCategoryName]?.toString() ?? '',
      subcategoryName: map[MotionDbColumns.subcategoryName]?.toString() ?? '',
      startedAtEpochMs: _readInt(map[MotionDbColumns.timerStartedAtEpochMs]),
      currentSegmentStartedAtEpochMs:
          map[MotionDbColumns.currentSegmentStartedAtEpochMs] == null
              ? null
              : _readInt(
                  map[MotionDbColumns.currentSegmentStartedAtEpochMs],
                ),
      completedSegments: segments,
      status: ActivityTimerStatus.values.firstWhere(
        (status) => status.name == map[MotionDbColumns.timerStatus],
        orElse: () => ActivityTimerStatus.paused,
      ),
      updatedAtEpochMs: _readInt(map[MotionDbColumns.timerUpdatedAtEpochMs]),
      nextReminderAtSeconds:
          _readInt(map[MotionDbColumns.nextTimerReminderAtSeconds]),
      targetSeconds: _readNullablePositiveInt(
        map[MotionDbColumns.timerTargetSeconds],
      ),
      targetAlertTriggered:
          _readInt(map[MotionDbColumns.timerTargetAlertTriggered]) == 1,
      mode: ActivityTimerMode.values.firstWhere(
        (mode) => mode.name == map[MotionDbColumns.timerMode],
        orElse: () =>
            _readNullablePositiveInt(map[MotionDbColumns.timerTargetSeconds]) ==
                    null
                ? ActivityTimerMode.openEnded
                : ActivityTimerMode.timed,
      ),
      pomodoroPhase: PomodoroPhase.values.cast<PomodoroPhase?>().firstWhere(
            (phase) => phase?.name == map[MotionDbColumns.pomodoroPhase],
            orElse: () => null,
          ),
      pomodoroFocusSeconds: _readInt(map[MotionDbColumns.pomodoroFocusSeconds]),
      pomodoroShortBreakSeconds:
          _readInt(map[MotionDbColumns.pomodoroShortBreakSeconds]),
      pomodoroLongBreakSeconds:
          _readInt(map[MotionDbColumns.pomodoroLongBreakSeconds]),
      pomodoroTotalRounds: _readInt(map[MotionDbColumns.pomodoroTotalRounds]),
      pomodoroCurrentRound: _readInt(map[MotionDbColumns.pomodoroCurrentRound]),
      pomodoroPhaseStartedAtEpochMs:
          map[MotionDbColumns.pomodoroPhaseStartedAtEpochMs] == null
              ? null
              : _readInt(
                  map[MotionDbColumns.pomodoroPhaseStartedAtEpochMs],
                ),
      pomodoroPhaseElapsedSeconds:
          _readInt(map[MotionDbColumns.pomodoroPhaseElapsedSeconds]),
    );
  }
}

int _readInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullablePositiveInt(Object? value) {
  if (value == null) return null;
  final parsed = _readInt(value);
  return parsed > 0 ? parsed : null;
}
