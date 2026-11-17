import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_database_schema.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_services/goal_start_reminder_bridge.dart';
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

    test('existing rows default to uncategorized timelines', () async {
      await database.insert(MotionDbTables.goals, {
        MotionDbColumns.currentLoggedInUser: 'user-1',
        MotionDbColumns.goalName: 'Single since',
        MotionDbColumns.goalDescription: '',
        MotionDbColumns.goalStartDate: '2026-01-01',
        MotionDbColumns.goalCompletionDate: null,
        MotionDbColumns.goalStatus: 'active',
        MotionDbColumns.goalCreatedAtEpochMs: 1,
        MotionDbColumns.goalUpdatedAtEpochMs: 1,
      });

      final entry = (await helper.getGoals(currentUser: 'user-1')).single;

      expect(entry.isTimeline, isTrue);
      expect(entry.collectionId, isNull);
    });

    test('migrates version 19 entries without losing their history', () async {
      final path =
          '${tempDirectory.path}${Platform.pathSeparator}tracker_v19.db';
      var legacyDb = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 19,
          onConfigure: TrackerDatabaseSchema.configure,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE ${MotionDbTables.goals}(
                ${MotionDbColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                ${MotionDbColumns.currentLoggedInUser} TEXT NOT NULL,
                ${MotionDbColumns.goalName} TEXT NOT NULL,
                ${MotionDbColumns.goalDescription} TEXT NOT NULL DEFAULT '',
                ${MotionDbColumns.goalStartDate} TEXT NOT NULL,
                ${MotionDbColumns.goalCompletionDate} TEXT,
                ${MotionDbColumns.goalStatus} TEXT NOT NULL DEFAULT 'active',
                ${MotionDbColumns.goalCreatedAtEpochMs} INTEGER NOT NULL,
                ${MotionDbColumns.goalUpdatedAtEpochMs} INTEGER NOT NULL
              )
            ''');
            await db.insert(MotionDbTables.goals, {
              MotionDbColumns.currentLoggedInUser: 'user-1',
              MotionDbColumns.goalName: 'First Job',
              MotionDbColumns.goalDescription: '',
              MotionDbColumns.goalStartDate: '2024-01-01',
              MotionDbColumns.goalCompletionDate: null,
              MotionDbColumns.goalStatus: 'active',
              MotionDbColumns.goalCreatedAtEpochMs: 1,
              MotionDbColumns.goalUpdatedAtEpochMs: 1,
            });
          },
        ),
      );
      await legacyDb.close();

      legacyDb = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: TrackerDatabaseSchema.version,
          onConfigure: TrackerDatabaseSchema.configure,
          onUpgrade: TrackerDatabaseSchema.migrate,
        ),
      );
      final migrated = (await legacyDb.query(MotionDbTables.goals)).single;

      expect(migrated[MotionDbColumns.goalName], 'First Job');
      expect(migrated[MotionDbColumns.timelineEntryType], 'timeline');
      expect(migrated[MotionDbColumns.timelineCollectionId], isNull);
      expect(
        migrated[MotionDbColumns.goalActivationDate],
        migrated[MotionDbColumns.goalStartDate],
      );
      expect(
        await legacyDb.query(MotionDbTables.timelineCollections),
        isEmpty,
      );
      expect(await legacyDb.query(MotionDbTables.goalDependencies), isEmpty);
      await legacyDb.close();
    });

    test('deleting a collection keeps its entries uncategorized', () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'Calisthenics'),
      );
      await helper.insertGoal(
        _goal(user: 'user-1').copyWith(collectionId: collectionId),
      );

      await helper.deleteTimelineCollection(
        collectionId: collectionId,
        currentUser: 'user-1',
      );

      expect(
        await helper.getTimelineCollections(currentUser: 'user-1'),
        isEmpty,
      );
      expect(
        (await helper.getGoals(currentUser: 'user-1')).single.collectionId,
        isNull,
      );
    });

    test('prevents a timeline from using another user collection', () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-2', name: 'Private'),
      );

      expect(
        () => helper.insertGoal(
          _goal(user: 'user-1').copyWith(collectionId: collectionId),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('unlocks a dependent entry when its prerequisite is completed',
        () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'CIFA'),
      );
      final foundationId = await helper.insertGoal(
        _goal(user: 'user-1', name: 'Foundation')
            .copyWith(collectionId: collectionId),
      );
      final intermediateId = await helper.insertGoalWithDependencies(
        goal: _goal(user: 'user-1', name: 'Intermediate').copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
        ),
        prerequisiteGoalIds: [foundationId],
      );

      var intermediate = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == intermediateId);
      expect(intermediate.isLocked, isTrue);
      expect(intermediate.elapsedDaysAt(DateTime(2026, 1, 20)), 0);

      final foundation = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == foundationId);
      final unlocked = await helper.markGoalAchievedAndUnlockDependents(
        foundation.copyWith(
          status: GoalStatus.achieved,
          completionDate: DateTime(2026, 1, 10),
          updatedAtEpochMs: 2,
        ),
      );

      expect(unlocked, [intermediateId]);
      intermediate = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == intermediateId);
      expect(intermediate.isLocked, isFalse);
      expect(intermediate.activationDate, DateTime(2026, 1, 10));
      expect(intermediate.elapsedDaysAt(DateTime(2026, 1, 20)), 10);
    });

    test('repairs an eligible entry left locked by an older completion flow',
        () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'CIFA'),
      );
      final foundationId = await helper.insertGoal(
        _goal(user: 'user-1', name: 'Foundation')
            .copyWith(collectionId: collectionId),
      );
      final intermediateId = await helper.insertGoalWithDependencies(
        goal: _goal(
          user: 'user-1',
          name: 'Intermediate',
          start: DateTime(2026, 1, 12),
        ).copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
        ),
        prerequisiteGoalIds: [foundationId],
      );
      final foundation = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == foundationId);
      await helper.updateGoal(foundation.copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 1, 10),
        updatedAtEpochMs: 2,
      ));

      var intermediate = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == intermediateId);
      expect(intermediate.isLocked, isTrue);

      final repaired = await helper.reconcileGoalDependencyActivations(
        currentUser: 'user-1',
        updatedAtEpochMs: 3,
      );

      expect(repaired, [intermediateId]);
      intermediate = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == intermediateId);
      expect(intermediate.isLocked, isFalse);
      expect(intermediate.activationDate, DateTime(2026, 1, 12));
      expect(
        await helper.reconcileGoalDependencyActivations(
          currentUser: 'user-1',
          updatedAtEpochMs: 4,
        ),
        isEmpty,
      );
    });

    test('waits for every prerequisite and honors a later planned start',
        () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'Running'),
      );
      final twoKmId = await helper.insertGoal(
        _goal(user: 'user-1', name: '2 km')
            .copyWith(collectionId: collectionId),
      );
      final fiveKmId = await helper.insertGoal(
        _goal(user: 'user-1', name: '5 km')
            .copyWith(collectionId: collectionId),
      );
      final tenKmId = await helper.insertGoalWithDependencies(
        goal: _goal(
          user: 'user-1',
          name: '10 km',
          start: DateTime(2026, 2, 1),
        ).copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
        ),
        prerequisiteGoalIds: [twoKmId, fiveKmId],
      );

      for (final id in [twoKmId, fiveKmId]) {
        final prerequisite = (await helper.getGoals(currentUser: 'user-1'))
            .singleWhere((goal) => goal.id == id);
        final unlocked = await helper.markGoalAchievedAndUnlockDependents(
          prerequisite.copyWith(
            status: GoalStatus.achieved,
            completionDate:
                id == twoKmId ? DateTime(2026, 1, 10) : DateTime(2026, 1, 15),
            updatedAtEpochMs: 3,
          ),
        );
        expect(unlocked, id == twoKmId ? isEmpty : [tenKmId]);
      }

      final tenKm = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == tenKmId);
      expect(tenKm.activationDate, DateTime(2026, 2, 1));
      expect(tenKm.isUpcomingAt(DateTime(2026, 1, 20)), isTrue);
    });

    test('automatic progression starts on prerequisite completion', () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'CIFA'),
      );
      final foundationId = await helper.insertGoal(
        _goal(user: 'user-1', name: 'Foundation')
            .copyWith(collectionId: collectionId),
      );
      final intermediateId = await helper.insertGoalWithDependencies(
        goal: _goal(
          user: 'user-1',
          name: 'Intermediate',
          start: DateTime(2026, 3, 1),
        ).copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
          startsAutomaticallyAfterPrerequisites: true,
        ),
        prerequisiteGoalIds: [foundationId],
      );
      final foundation = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == foundationId);

      await helper.markGoalAchievedAndUnlockDependents(foundation.copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 1, 10),
        updatedAtEpochMs: 2,
      ));

      final intermediate = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == intermediateId);
      expect(intermediate.startDate, DateTime(2026, 1, 10));
      expect(intermediate.activationDate, DateTime(2026, 1, 10));
      expect(intermediate.isUpcomingAt(DateTime(2026, 1, 20)), isFalse);
    });

    test('rejects circular links and deleting a used prerequisite', () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'Qualifications'),
      );
      final firstId = await helper.insertGoal(
        _goal(user: 'user-1', name: 'Foundation')
            .copyWith(collectionId: collectionId),
      );
      final secondId = await helper.insertGoalWithDependencies(
        goal: _goal(user: 'user-1', name: 'Intermediate').copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
        ),
        prerequisiteGoalIds: [firstId],
      );
      final first = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == firstId);

      await expectLater(
        helper.updateGoalWithDependencies(
          goal: first,
          prerequisiteGoalIds: [secondId],
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        helper.deleteGoal(goalId: firstId, currentUser: 'user-1'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        helper.deleteTimelineCollection(
          collectionId: collectionId,
          currentUser: 'user-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('reopening a prerequisite does not relock an activated entry',
        () async {
      final collectionId = await helper.insertTimelineCollection(
        _collection(user: 'user-1', name: 'Career'),
      );
      final firstId = await helper.insertGoal(
        _goal(user: 'user-1', name: 'Apply')
            .copyWith(collectionId: collectionId),
      );
      final nextId = await helper.insertGoalWithDependencies(
        goal: _goal(user: 'user-1', name: 'Onboarding').copyWith(
          collectionId: collectionId,
          clearActivationDate: true,
        ),
        prerequisiteGoalIds: [firstId],
      );
      var first = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == firstId);
      await helper.markGoalAchievedAndUnlockDependents(first.copyWith(
        status: GoalStatus.achieved,
        completionDate: DateTime(2026, 1, 5),
        updatedAtEpochMs: 2,
      ));
      first = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == firstId);
      await helper.updateGoal(first.copyWith(
        status: GoalStatus.active,
        clearCompletionDate: true,
        updatedAtEpochMs: 3,
      ));

      final next = (await helper.getGoals(currentUser: 'user-1'))
          .singleWhere((goal) => goal.id == nextId);
      expect(next.isLocked, isFalse);
      expect(next.activationDate, DateTime(2026, 1, 5));
    });

    test('daily effort check-ins are only available for goals', () async {
      await helper.insertGoal(
        _goal(user: 'user-1', entryType: TimelineEntryType.timeline),
      );
      final timeline = (await helper.getGoals(currentUser: 'user-1')).single;

      expect(
        () => helper.toggleGoalCheckIn(
          goal: timeline,
          date: DateTime(2026, 1, 2),
          today: DateTime(2026, 1, 2),
        ),
        throwsA(isA<StateError>()),
      );
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
        reminderBridge: _FakeGoalStartReminderBridge(),
        now: () => DateTime(2026, 1, 5, 12),
      );
      try {
        await provider.initialize();
        final goal = await provider.createGoal(
          name: 'Get a Job',
          description: '',
          startDate: DateTime(2026, 1, 1),
          deadlineDate: DateTime(2026, 1, 31),
          entryType: TimelineEntryType.goal,
        );
        expect(goal.deadlineDate, DateTime(2026, 1, 31));
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

    test('provider creates a historical timeline as completed', () async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: _FakeGoalStartReminderBridge(),
        now: () => DateTime(2026, 1, 10, 12),
      );
      try {
        await provider.initialize();
        final timeline = await provider.createGoal(
          name: 'First Job',
          description: '',
          startDate: DateTime(2020, 1, 1),
          completionDate: DateTime(2024, 6, 30),
        );

        expect(timeline.isAchieved, isTrue);
        expect(timeline.completionDate, DateTime(2024, 6, 30));
        expect(
          provider.goalById(timeline.id!)!.completionDate,
          DateTime(2024, 6, 30),
        );
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });

    test('provider unlocks the next entry and sends one unlock notification',
        () async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final reminderBridge = _FakeGoalStartReminderBridge();
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: reminderBridge,
        now: () => DateTime(2026, 1, 5, 12),
      );
      try {
        await provider.initialize();
        final collection = await provider.createCollection('CIFA');
        final foundation = await provider.createGoal(
          name: 'Foundation',
          description: '',
          startDate: DateTime(2026, 1, 1),
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
        );
        final intermediate = await provider.createGoal(
          name: 'Intermediate',
          description: '',
          startDate: DateTime(2026, 1, 1),
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
          prerequisiteId: foundation.id,
        );

        expect(provider.goalById(intermediate.id!)!.isLocked, isTrue);
        expect(
          provider
              .goalById(intermediate.id!)!
              .startsAutomaticallyAfterPrerequisites,
          isTrue,
        );
        expect(reminderBridge.unlockedGoalIds, isEmpty);
        await provider.markAchieved(provider.goalById(foundation.id!)!);

        expect(provider.goalById(intermediate.id!)!.isLocked, isFalse);
        expect(reminderBridge.unlockedGoalIds, [intermediate.id]);
        expect(reminderBridge.lastSync, isEmpty);
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });

    test('completing a prerequisite in the editor unlocks the next entry',
        () async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final reminderBridge = _FakeGoalStartReminderBridge();
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: reminderBridge,
        now: () => DateTime(2026, 1, 10, 12),
      );
      try {
        await provider.initialize();
        final collection = await provider.createCollection('CIFA');
        final foundation = await provider.createGoal(
          name: 'Foundation',
          description: '',
          startDate: DateTime(2026, 1, 1),
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
        );
        final intermediate = await provider.createGoal(
          name: 'Intermediate',
          description: '',
          startDate: DateTime(2026, 1, 1),
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
          prerequisiteId: foundation.id,
        );

        await provider.editGoal(
          goal: provider.goalById(foundation.id!)!,
          name: foundation.name,
          description: foundation.description,
          startDate: foundation.startDate,
          completionDate: DateTime(2026, 1, 10),
          deadlineDate: foundation.deadlineDate,
          entryType: foundation.entryType,
          collectionId: collection.id,
        );

        expect(provider.goalById(intermediate.id!)!.isLocked, isFalse);
        expect(
          provider.goalById(intermediate.id!)!.activationDate,
          DateTime(2026, 1, 10),
        );
        expect(reminderBridge.unlockedGoalIds, [intermediate.id]);
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });

    test('future entries schedule and reconcile start reminders', () async {
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final reminderBridge = _FakeGoalStartReminderBridge();
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: reminderBridge,
        now: () => DateTime(2026, 1, 5, 12),
      );
      try {
        await provider.initialize();
        final goal = await provider.createGoal(
          name: 'Begin Marathon Training',
          description: '',
          startDate: DateTime(2026, 1, 10),
          entryType: TimelineEntryType.goal,
        );

        expect(provider.isUpcoming(goal), isTrue);
        expect(provider.activeDaysFor(goal), 0);
        expect(reminderBridge.permissionRequests, 1);
        expect(provider.reminderPermissionGranted, isTrue);
        expect(reminderBridge.lastSync, hasLength(1));
        expect(reminderBridge.lastSync.single.goalId, goal.id);
        expect(reminderBridge.lastSync.single.startDate, DateTime(2026, 1, 10));

        await expectLater(
          provider.markAchieved(goal),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          provider.pauseGoal(goal),
          throwsA(isA<StateError>()),
        );

        await provider.editGoal(
          goal: goal,
          name: goal.name,
          description: goal.description,
          startDate: DateTime(2026, 1, 12),
          completionDate: null,
          deadlineDate: null,
          entryType: goal.entryType,
        );
        expect(reminderBridge.permissionRequests, 2);
        expect(reminderBridge.lastSync.single.startDate, DateTime(2026, 1, 12));

        final updated = provider.goalById(goal.id!)!;
        await provider.editGoal(
          goal: updated,
          name: updated.name,
          description: updated.description,
          startDate: DateTime(2026, 1, 1),
          completionDate: null,
          deadlineDate: null,
          entryType: updated.entryType,
        );
        expect(reminderBridge.permissionRequests, 2);
        expect(reminderBridge.lastSync, isEmpty);
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });

    test('pausing preserves active days and achievement closes the pause',
        () async {
      var now = DateTime(2026, 1, 10, 12);
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: _FakeGoalStartReminderBridge(),
        now: () => now,
      );
      try {
        await provider.initialize();
        var goal = await provider.createGoal(
          name: 'Build Strength',
          description: '',
          startDate: DateTime(2026, 1, 1),
          deadlineDate: DateTime(2026, 3, 1),
          entryType: TimelineEntryType.goal,
        );
        expect(provider.activeDaysFor(goal), 9);

        await provider.pauseGoal(goal, reason: 'Injury');
        goal = provider.goalById(goal.id!)!;
        expect(provider.isPaused(goal), isTrue);

        now = DateTime(2026, 2, 9, 12);
        expect(provider.pausedDaysFor(goal), 30);
        expect(provider.activeDaysFor(goal), 9);
        expect(goal.deadlineDate, DateTime(2026, 3, 1));

        await provider.resumePausedGoal(goal);
        goal = provider.goalById(goal.id!)!;
        expect(provider.isPaused(goal), isFalse);
        expect(goal.deadlineDate, DateTime(2026, 3, 1));
        now = DateTime(2026, 2, 10, 12);
        expect(provider.activeDaysFor(goal), 10);

        await provider.pauseGoal(goal, reason: 'Travel');
        goal = provider.goalById(goal.id!)!;
        now = DateTime(2026, 2, 15, 12);
        await provider.markAchieved(goal);
        goal = provider.goalById(goal.id!)!;

        expect(goal.isAchieved, isTrue);
        expect(provider.isPaused(goal), isFalse);
        expect(
            provider.pausePeriodsFor(goal.id!).where((p) => p.isOpen), isEmpty);
        expect(provider.activeDaysFor(goal), 10);
        expect(goal.elapsedDaysAt(provider.today), 45);
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });

    test(
        'failed attempts stay frozen and a successful retry unlocks progression',
        () async {
      var now = DateTime(2026, 1, 5, 12);
      final userProvider = UserUidProvider(
        initialUserUid: 'user-1',
        isInitialized: true,
      );
      final provider = GoalTrackerProvider(
        userUidProvider: userProvider,
        databaseHelper: helper,
        reminderBridge: _FakeGoalStartReminderBridge(),
        now: () => now,
      );
      try {
        await provider.initialize();
        final collection = await provider.createCollection('Addictions');
        final attempt = await provider.createGoal(
          name: 'No Social Media - 7 Day Attempt',
          description: '',
          startDate: DateTime(2026, 1, 1),
          targetDays: 7,
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
        );
        final nextStep = await provider.createGoal(
          name: 'No Social Media - 30 Day Attempt',
          description: '',
          startDate: DateTime(2026, 1, 1),
          entryType: TimelineEntryType.goal,
          collectionId: collection.id,
          prerequisiteId: attempt.id,
        );

        await expectLater(
          provider.markAchieved(attempt),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('3 more active days'),
            ),
          ),
        );

        await provider.markFailed(attempt, reason: 'Opened social media');
        final failed = provider.goalById(attempt.id!)!;
        expect(failed.isFailed, isTrue);
        expect(failed.failureDate, DateTime(2026, 1, 5));
        expect(failed.failureReason, 'Opened social media');
        expect(failed.elapsedDaysAt(DateTime(2030)), 4);
        expect(provider.failedCount, 1);
        expect(provider.goalById(nextStep.id!)!.isLocked, isTrue);

        final retry = await provider.retryGoal(
          failed,
          startDate: DateTime(2026, 1, 5),
        );
        expect(retry.retryOfGoalId, failed.id);
        expect(retry.targetDays, 7);
        expect(provider.attemptNumberFor(retry), 2);
        expect(provider.prerequisiteIdsFor(provider.goalById(nextStep.id!)!),
            [retry.id]);

        now = DateTime(2026, 1, 12, 12);
        await provider.markAchieved(provider.goalById(retry.id!)!);

        expect(provider.goalById(retry.id!)!.isAchieved, isTrue);
        expect(provider.goalById(nextStep.id!)!.isLocked, isFalse);
      } finally {
        provider.dispose();
        userProvider.dispose();
      }
    });
  });
}

class _FakeGoalStartReminderBridge implements GoalStartReminderBridge {
  int permissionRequests = 0;
  List<GoalStartReminder> lastSync = const [];
  final List<int> unlockedGoalIds = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> sync(List<GoalStartReminder> reminders) async {
    lastSync = List.unmodifiable(reminders);
  }

  @override
  Future<void> notifyUnlocked(MotionGoal goal) async {
    unlockedGoalIds.add(goal.id!);
  }
}

MotionGoal _goal({
  required String user,
  String name = 'Get a Job',
  DateTime? start,
  TimelineEntryType entryType = TimelineEntryType.goal,
}) {
  final effectiveStart = start ?? DateTime(2026, 1, 1);
  return MotionGoal(
    currentLoggedInUser: user,
    name: name,
    startDate: effectiveStart,
    activationDate: effectiveStart,
    entryType: entryType,
    createdAtEpochMs: 1,
    updatedAtEpochMs: 1,
  );
}

MotionTimelineCollection _collection({
  required String user,
  required String name,
}) {
  return MotionTimelineCollection(
    currentLoggedInUser: user,
    name: name,
    createdAtEpochMs: 1,
    updatedAtEpochMs: 1,
  );
}
