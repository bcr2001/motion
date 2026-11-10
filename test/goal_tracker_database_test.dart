import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Goal tracker database', () {
    late Directory tempDirectory;
    late Database database;
    late TrackerDatabaseHelper helper;

    setUp(() async {
      tempDirectory = Directory.systemTemp.createTempSync('motion_goals_');
      database = await databaseFactoryFfi.openDatabase(
        '${tempDirectory.path}${Platform.pathSeparator}tracker.db',
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (db, version) => TrackerDatabaseSchema.create(db),
        ),
      );
      helper = TrackerDatabaseHelper.forDatabase(database);
    });

    tearDown(() async {
      await database.close();
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('calculates calendar duration and freezes achieved goals', () {
      final active = _goal(
        user: 'user-1',
        start: DateTime(2026, 1, 1),
      );
      expect(active.elapsedDaysAt(DateTime(2026, 3, 15)), 73);

      final achieved = active.copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 3, 15),
      );
      expect(achieved.elapsedDaysAt(DateTime(2030, 1, 1)), 73);
    });

    test('isolates goals and check-ins by user', () async {
      final firstId = await helper.insertGoal(_goal(user: 'user-1'));
      await helper.insertGoal(_goal(user: 'user-2', name: 'Other'));
      final first = (await helper.getGoals(currentUser: 'user-1')).single;

      expect(first.id, firstId);
      expect(await helper.getGoals(currentUser: 'user-2'), hasLength(1));
      expect(
        await helper.toggleGoalCheckIn(
          goal: first,
          date: DateTime(2026, 1, 2),
          today: DateTime(2026, 1, 4),
        ),
        isTrue,
      );
      expect(
        await helper.getGoalCheckIns(
          goalId: firstId,
          currentUser: 'user-1',
        ),
        hasLength(1),
      );
      expect(
        await helper.getGoalCheckIns(
          goalId: firstId,
          currentUser: 'user-2',
        ),
        isEmpty,
      );
    });

    test('lists active goals before achieved goals', () async {
      await helper.insertGoal(_goal(user: 'user-1').copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 1, 2),
      ));
      await helper.insertGoal(_goal(user: 'user-1', name: 'Active Goal'));

      final goals = await helper.getGoals(currentUser: 'user-1');

      expect(goals.map((goal) => goal.name), ['Active Goal', 'Get a Job']);
    });

    test('toggles check-ins without creating duplicates', () async {
      final id = await helper.insertGoal(_goal(user: 'user-1'));
      final goal = (await helper.getGoals(currentUser: 'user-1')).single;
      final date = DateTime(2026, 1, 3);

      expect(
        await helper.toggleGoalCheckIn(
          goal: goal,
          date: date,
          today: date,
        ),
        isTrue,
      );
      expect(
        await helper.toggleGoalCheckIn(
          goal: goal,
          date: date,
          today: date,
        ),
        isFalse,
      );
      expect(
        await helper.getGoalCheckIns(
          goalId: id,
          currentUser: 'user-1',
        ),
        isEmpty,
      );
    });

    test('editing the start date removes only earlier check-ins', () async {
      final id = await helper.insertGoal(_goal(user: 'user-1'));
      var goal = (await helper.getGoals(currentUser: 'user-1')).single;
      for (final date in [DateTime(2026, 1, 2), DateTime(2026, 1, 4)]) {
        await helper.toggleGoalCheckIn(
          goal: goal,
          date: date,
          today: DateTime(2026, 1, 5),
        );
      }

      goal = goal.copyWith(
        startDate: DateTime(2026, 1, 3),
        updatedAtEpochMs: 2,
      );
      await helper.updateGoal(goal);

      final checkIns = await helper.getGoalCheckIns(
        goalId: id,
        currentUser: 'user-1',
      );
      expect(checkIns.map((item) => item.date.day), [4]);
    });

    test('achievement freezes duration and reopening preserves history',
        () async {
      await helper.insertGoal(_goal(user: 'user-1'));
      var goal = (await helper.getGoals(currentUser: 'user-1')).single;
      await helper.toggleGoalCheckIn(
        goal: goal,
        date: DateTime(2026, 1, 3),
        today: DateTime(2026, 1, 5),
      );

      await helper.updateGoal(goal.copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 1, 5),
        updatedAtEpochMs: 2,
      ));
      goal = (await helper.getGoals(currentUser: 'user-1')).single;
      expect(goal.isAchieved, isTrue);
      expect(goal.elapsedDaysAt(DateTime(2030, 1, 1)), 4);

      await helper.updateGoal(goal.copyWith(
        status: GoalStatus.active,
        clearCompletionDate: true,
        updatedAtEpochMs: 3,
      ));
      goal = (await helper.getGoals(currentUser: 'user-1')).single;
      expect(goal.isAchieved, isFalse);
      expect(goal.completionDate, isNull);
      expect(
        await helper.getGoalCheckIns(
          goalId: goal.id!,
          currentUser: 'user-1',
        ),
        hasLength(1),
      );
    });

    test('deleting a goal cascades its check-ins', () async {
      final id = await helper.insertGoal(_goal(user: 'user-1'));
      final goal = (await helper.getGoals(currentUser: 'user-1')).single;
      await helper.toggleGoalCheckIn(
        goal: goal,
        date: DateTime(2026, 1, 2),
        today: DateTime(2026, 1, 2),
      );

      await helper.deleteGoal(goalId: id, currentUser: 'user-1');

      expect(await helper.getGoals(currentUser: 'user-1'), isEmpty);
      final rows = await database.query(MotionDbTables.goalCheckIns);
      expect(rows, isEmpty);
    });

    test('provider runs the create, check-in, achieve, and reopen flow',
        () async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        now: () => DateTime(2026, 1, 5, 12),
      );
      try {
        await provider.initialize();
        final goal = await provider.createGoal(
          name: 'Get a Job',
          description: '',
          startDate: DateTime(2026, 1, 1),
        );
        await provider.toggleCheckIn(goal, DateTime(2026, 1, 3));
        expect(provider.checkInsFor(goal.id!), hasLength(1));

        await provider.markAchieved(provider.goalById(goal.id!)!);
        expect(provider.goalById(goal.id!)!.isAchieved, isTrue);
        expect(provider.goalById(goal.id!)!.elapsedDaysAt(provider.today), 4);

        await provider.reopenGoal(provider.goalById(goal.id!)!);
        expect(provider.goalById(goal.id!)!.isAchieved, isFalse);
        expect(provider.checkInsFor(goal.id!), hasLength(1));
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });
  });
}

MotionGoal _goal({
  required String user,
  String name = 'Get a Job',
  DateTime? start,
}) {
  return MotionGoal(
    currentLoggedInUser: user,
    name: name,
    startDate: start ?? DateTime(2026, 1, 1),
    createdAtEpochMs: 1,
    updatedAtEpochMs: 1,
  );
}
