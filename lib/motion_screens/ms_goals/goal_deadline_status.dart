import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

class GoalDeadlineStatus {
  const GoalDeadlineStatus({
    required this.deadline,
    required this.deltaDays,
    required this.isCompleted,
  });

  final DateTime deadline;
  final int deltaDays;
  final bool isCompleted;

  Color get color {
    if (isCompleted) return deltaDays < 0 ? Colors.redAccent : Colors.green;
    if (deltaDays < 0) return Colors.redAccent;
    if (deltaDays <= 7) return Colors.orange;
    return AppColor.blueMainColor;
  }

  String get label {
    if (isCompleted) {
      if (deltaDays > 0) {
        return 'Completed $deltaDays ${deltaDays == 1 ? 'day' : 'days'} early';
      }
      if (deltaDays == 0) return 'Completed on time';
      final lateDays = deltaDays.abs();
      return 'Completed $lateDays ${lateDays == 1 ? 'day' : 'days'} late';
    }
    if (deltaDays > 0) {
      return '$deltaDays ${deltaDays == 1 ? 'day' : 'days'} left';
    }
    if (deltaDays == 0) return 'Due today';
    final overdueDays = deltaDays.abs();
    return '$overdueDays ${overdueDays == 1 ? 'day' : 'days'} overdue';
  }
}

GoalDeadlineStatus? deadlineStatusFor(MotionGoal goal, DateTime today) {
  final deadline = goal.deadlineDate;
  if (deadline == null || !goal.isGoal) return null;
  final comparisonDate = goal.completionDate ?? MotionDateUtils.dateOnly(today);
  return GoalDeadlineStatus(
    deadline: deadline,
    deltaDays: deadline.difference(comparisonDate).inDays,
    isCompleted: goal.isAchieved,
  );
}
