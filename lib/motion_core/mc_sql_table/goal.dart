import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum GoalStatus { active, achieved }

class MotionGoal {
  const MotionGoal({
    this.id,
    required this.currentLoggedInUser,
    required this.name,
    this.description = '',
    required this.startDate,
    this.completionDate,
    this.status = GoalStatus.active,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  final int? id;
  final String currentLoggedInUser;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? completionDate;
  final GoalStatus status;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  bool get isAchieved => status == GoalStatus.achieved;

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
    GoalStatus? status,
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
      status: status ?? this.status,
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
        MotionDbColumns.goalStatus: status.name,
        MotionDbColumns.goalCreatedAtEpochMs: createdAtEpochMs,
        MotionDbColumns.goalUpdatedAtEpochMs: updatedAtEpochMs,
      };

  factory MotionGoal.fromMap(Map<String, Object?> map) {
    final startDate =
        MotionDateUtils.parseStoredDate(map[MotionDbColumns.goalStartDate]);
    if (startDate == null) {
      throw const FormatException('Goal has an invalid start date.');
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
      status: map[MotionDbColumns.goalStatus]?.toString() ==
              GoalStatus.achieved.name
          ? GoalStatus.achieved
          : GoalStatus.active,
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
      throw const FormatException('Goal check-in has an invalid date.');
    }
    return GoalCheckIn(
      goalId: (map[MotionDbColumns.goalId] as num).toInt(),
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser]?.toString() ?? '',
      date: date,
    );
  }
}
