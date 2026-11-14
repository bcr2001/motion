import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_screens/ms_goals/goal_deadline_status.dart';

void main() {
  test('reports remaining, overdue, early, on-time, and late deadlines', () {
    final active = _goal(deadline: DateTime(2026, 1, 11));
    expect(
        deadlineStatusFor(active, DateTime(2026, 1, 1))!.label, '10 days left');
    expect(
        deadlineStatusFor(active, DateTime(2026, 1, 11))!.label, 'Due today');
    expect(deadlineStatusFor(active, DateTime(2026, 1, 14))!.label,
        '3 days overdue');

    expect(
      deadlineStatusFor(
        _goal(
          deadline: DateTime(2026, 1, 11),
          completion: DateTime(2026, 1, 8),
        ),
        DateTime(2030),
      )!
          .label,
      'Completed 3 days early',
    );
    expect(
      deadlineStatusFor(
        _goal(
          deadline: DateTime(2026, 1, 11),
          completion: DateTime(2026, 1, 11),
        ),
        DateTime(2030),
      )!
          .label,
      'Completed on time',
    );
    expect(
      deadlineStatusFor(
        _goal(
          deadline: DateTime(2026, 1, 11),
          completion: DateTime(2026, 1, 13),
        ),
        DateTime(2030),
      )!
          .label,
      'Completed 2 days late',
    );
  });
}

MotionGoal _goal({required DateTime deadline, DateTime? completion}) {
  return MotionGoal(
    currentLoggedInUser: 'user-1',
    name: 'Get a Job',
    startDate: DateTime(2026, 1, 1),
    deadlineDate: deadline,
    completionDate: completion,
    status: completion == null ? GoalStatus.active : GoalStatus.achieved,
    entryType: TimelineEntryType.goal,
    createdAtEpochMs: 1,
    updatedAtEpochMs: 1,
  );
}
