import 'dart:convert';

import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

enum ActivityTimerStatus { running, paused }

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
  });

  bool get isRunning => status == ActivityTimerStatus.running;
  bool get isTimed => targetSeconds != null && targetSeconds! > 0;

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

  int? remainingSecondsAt(DateTime now) {
    final target = targetSeconds;
    if (target == null || target <= 0) return null;
    return (target - elapsedSecondsAt(now)).clamp(0, target).toInt();
  }

  DateTime? expectedEndAt(DateTime now) {
    final remainingSeconds = remainingSecondsAt(now);
    if (remainingSeconds == null || remainingSeconds <= 0) return null;
    return now.add(Duration(seconds: remainingSeconds));
  }

  int overtimeSecondsAt(DateTime now) {
    final target = targetSeconds;
    if (target == null || target <= 0) return 0;
    final overtime = elapsedSecondsAt(now) - target;
    return overtime < 0 ? 0 : overtime;
  }

  bool targetReachedAt(DateTime now) {
    final target = targetSeconds;
    return target != null && target > 0 && elapsedSecondsAt(now) >= target;
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
