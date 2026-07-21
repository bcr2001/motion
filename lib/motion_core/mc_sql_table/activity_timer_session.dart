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
  });

  bool get isRunning => status == ActivityTimerStatus.running;

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
    );
  }
}

int _readInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
