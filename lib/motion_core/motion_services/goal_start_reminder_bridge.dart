import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';

class GoalStartReminder {
  const GoalStartReminder({
    required this.goalId,
    required this.name,
    required this.entryType,
    required this.startDate,
  });

  final int goalId;
  final String name;
  final TimelineEntryType entryType;
  final DateTime startDate;

  Map<String, Object> toPlatformMap() => {
        'goalId': goalId,
        'name': name,
        'entryType': entryType.name,
        'year': startDate.year,
        'month': startDate.month,
        'day': startDate.day,
      };
}

abstract class GoalStartReminderBridge {
  Future<bool> requestPermission();

  Future<void> sync(List<GoalStartReminder> reminders);

  Future<void> notifyUnlocked(MotionGoal goal);
}

class PlatformGoalStartReminderBridge implements GoalStartReminderBridge {
  static const MethodChannel _channel = MethodChannel(
    'motion/goal_start_reminder',
  );

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPermission() async {
    if (!_isSupported) return true;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<void> sync(List<GoalStartReminder> reminders) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>('sync', {
      'reminders': reminders
          .map((reminder) => reminder.toPlatformMap())
          .toList(growable: false),
    });
  }

  @override
  Future<void> notifyUnlocked(MotionGoal goal) async {
    if (!_isSupported || goal.id == null) return;
    await _channel.invokeMethod<void>('notifyUnlocked', {
      'goalId': goal.id,
      'name': goal.name,
      'entryType': goal.entryType.name,
    });
  }
}
