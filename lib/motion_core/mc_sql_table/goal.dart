import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum GoalStatus { active, achieved }

enum TimelineEntryType { timeline, goal }

class MotionTimelineCollection {
  const MotionTimelineCollection({
    this.id,
    required this.currentLoggedInUser,
    required this.name,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  final int? id;
  final String currentLoggedInUser;
  final String name;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  MotionTimelineCollection copyWith({
    int? id,
    String? currentLoggedInUser,
    String? name,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) {
    return MotionTimelineCollection(
      id: id ?? this.id,
      currentLoggedInUser: currentLoggedInUser ?? this.currentLoggedInUser,
      name: name ?? this.name,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) MotionDbColumns.id: id,
        MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
        MotionDbColumns.timelineCollectionName: name,
        MotionDbColumns.timelineCollectionCreatedAtEpochMs: createdAtEpochMs,
        MotionDbColumns.timelineCollectionUpdatedAtEpochMs: updatedAtEpochMs,
      };

  factory MotionTimelineCollection.fromMap(Map<String, Object?> map) {
    return MotionTimelineCollection(
      id: (map[MotionDbColumns.id] as num?)?.toInt(),
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      name: map[MotionDbColumns.timelineCollectionName]?.toString() ?? '',
      createdAtEpochMs:
          (map[MotionDbColumns.timelineCollectionCreatedAtEpochMs] as num?)
                  ?.toInt() ??
              0,
      updatedAtEpochMs:
          (map[MotionDbColumns.timelineCollectionUpdatedAtEpochMs] as num?)
                  ?.toInt() ??
              0,
    );
  }
}

class MotionGoal {
  const MotionGoal({
    this.id,
    required this.currentLoggedInUser,
    required this.name,
    this.description = '',
    required this.startDate,
    this.completionDate,
    this.deadlineDate,
    this.status = GoalStatus.active,
    this.entryType = TimelineEntryType.timeline,
    this.collectionId,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  final int? id;
  final String currentLoggedInUser;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? completionDate;
  final DateTime? deadlineDate;
  final GoalStatus status;
  final TimelineEntryType entryType;
  final int? collectionId;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  bool get isAchieved => status == GoalStatus.achieved;
  bool get isGoal => entryType == TimelineEntryType.goal;
  bool get isTimeline => entryType == TimelineEntryType.timeline;

  int elapsedDaysAt(DateTime today) {
    final end = completionDate ?? MotionDateUtils.dateOnly(today);
    final start = MotionDateUtils.dateOnly(startDate);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays;
  }

  MotionGoal copyWith({
    int? id,
    String? currentLoggedInUser,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? completionDate,
    bool clearCompletionDate = false,
    DateTime? deadlineDate,
    bool clearDeadlineDate = false,
    GoalStatus? status,
    TimelineEntryType? entryType,
    int? collectionId,
    bool clearCollectionId = false,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) {
    return MotionGoal(
      id: id ?? this.id,
      currentLoggedInUser: currentLoggedInUser ?? this.currentLoggedInUser,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      completionDate:
          clearCompletionDate ? null : completionDate ?? this.completionDate,
      deadlineDate:
          clearDeadlineDate ? null : deadlineDate ?? this.deadlineDate,
      status: status ?? this.status,
      entryType: entryType ?? this.entryType,
      collectionId:
          clearCollectionId ? null : collectionId ?? this.collectionId,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) MotionDbColumns.id: id,
        MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
        MotionDbColumns.goalName: name,
        MotionDbColumns.goalDescription: description,
        MotionDbColumns.goalStartDate: MotionDateUtils.formatDbDate(startDate),
        MotionDbColumns.goalCompletionDate: completionDate == null
            ? null
            : MotionDateUtils.formatDbDate(completionDate!),
        MotionDbColumns.goalDeadlineDate: deadlineDate == null
            ? null
            : MotionDateUtils.formatDbDate(deadlineDate!),
        MotionDbColumns.goalStatus: status.name,
        MotionDbColumns.timelineEntryType: entryType.name,
        MotionDbColumns.timelineCollectionId: collectionId,
        MotionDbColumns.goalCreatedAtEpochMs: createdAtEpochMs,
        MotionDbColumns.goalUpdatedAtEpochMs: updatedAtEpochMs,
      };

  factory MotionGoal.fromMap(Map<String, Object?> map) {
    final startDate =
        MotionDateUtils.parseStoredDate(map[MotionDbColumns.goalStartDate]);
    if (startDate == null) {
      throw const FormatException('Timeline has an invalid start date.');
    }
    return MotionGoal(
      id: (map[MotionDbColumns.id] as num?)?.toInt(),
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      name: map[MotionDbColumns.goalName]?.toString() ?? '',
      description: map[MotionDbColumns.goalDescription]?.toString() ?? '',
      startDate: startDate,
      completionDate: MotionDateUtils.parseStoredDate(
        map[MotionDbColumns.goalCompletionDate],
      ),
      deadlineDate: MotionDateUtils.parseStoredDate(
        map[MotionDbColumns.goalDeadlineDate],
      ),
      status: map[MotionDbColumns.goalStatus]?.toString() ==
              GoalStatus.achieved.name
          ? GoalStatus.achieved
          : GoalStatus.active,
      entryType: map[MotionDbColumns.timelineEntryType]?.toString() ==
              TimelineEntryType.goal.name
          ? TimelineEntryType.goal
          : TimelineEntryType.timeline,
      collectionId:
          (map[MotionDbColumns.timelineCollectionId] as num?)?.toInt(),
      createdAtEpochMs:
          (map[MotionDbColumns.goalCreatedAtEpochMs] as num?)?.toInt() ?? 0,
      updatedAtEpochMs:
          (map[MotionDbColumns.goalUpdatedAtEpochMs] as num?)?.toInt() ?? 0,
    );
  }
}

class GoalCheckIn {
  const GoalCheckIn({
    required this.goalId,
    required this.currentLoggedInUser,
    required this.date,
  });

  final int goalId;
  final String currentLoggedInUser;
  final DateTime date;

  Map<String, Object?> toMap() => {
        MotionDbColumns.goalId: goalId,
        MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
        MotionDbColumns.date: MotionDateUtils.formatDbDate(date),
      };

  factory GoalCheckIn.fromMap(Map<String, Object?> map) {
    final date = MotionDateUtils.parseStoredDate(map[MotionDbColumns.date]);
    if (date == null) {
      throw const FormatException('Timeline check-in has an invalid date.');
    }
    return GoalCheckIn(
      goalId: (map[MotionDbColumns.goalId] as num).toInt(),
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      date: date,
    );
  }
}

class GoalPausePeriod {
  const GoalPausePeriod({
    this.id,
    required this.goalId,
    required this.currentLoggedInUser,
    required this.startDate,
    this.resumeDate,
    this.reason = '',
  });

  final int? id;
  final int goalId;
  final String currentLoggedInUser;
  final DateTime startDate;
  final DateTime? resumeDate;
  final String reason;

  bool get isOpen => resumeDate == null;

  Map<String, Object?> toMap() => {
        if (id != null) MotionDbColumns.id: id,
        MotionDbColumns.goalId: goalId,
        MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
        MotionDbColumns.goalPauseStartDate:
            MotionDateUtils.formatDbDate(startDate),
        MotionDbColumns.goalPauseResumeDate: resumeDate == null
            ? null
            : MotionDateUtils.formatDbDate(resumeDate!),
        MotionDbColumns.goalPauseReason: reason,
      };

  factory GoalPausePeriod.fromMap(Map<String, Object?> map) {
    final startDate = MotionDateUtils.parseStoredDate(
      map[MotionDbColumns.goalPauseStartDate],
    );
    if (startDate == null) {
      throw const FormatException('Goal pause has an invalid start date.');
    }
    return GoalPausePeriod(
      id: (map[MotionDbColumns.id] as num?)?.toInt(),
      goalId: (map[MotionDbColumns.goalId] as num).toInt(),
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      startDate: startDate,
      resumeDate: MotionDateUtils.parseStoredDate(
        map[MotionDbColumns.goalPauseResumeDate],
      ),
      reason: map[MotionDbColumns.goalPauseReason]?.toString() ?? '',
    );
  }
}
