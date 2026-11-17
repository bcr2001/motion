import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_services/goal_start_reminder_bridge.dart';
import 'package:motion/motion_screens/ms_goals/goal_tracker_page.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'Collections opens as a bordered page in ${brightness.name} mode',
        (tester) async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final goalProvider = GoalTrackerProvider(
        userUidProvider: userProvider,
        reminderBridge: _NoopGoalStartReminderBridge(),
        now: () => DateTime(2026, 11, 14),
      );
      addTearDown(() {
        goalProvider.dispose();
        userProvider.dispose();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<GoalTrackerProvider>.value(
          value: goalProvider,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const GoalTrackerPage(),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Manage Collections'));
      await tester.pumpAndSettle();

      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.text('New Collection'), findsOneWidget);

      final action = tester.widget<Container>(
        find.byKey(const Key('collectionsBottomAction')),
      );
      final decoration = action.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color.a, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}

class _NoopGoalStartReminderBridge implements GoalStartReminderBridge {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<GoalStartReminder> reminders) async {}

  @override
  Future<void> notifyUnlocked(MotionGoal goal) async {}
}
