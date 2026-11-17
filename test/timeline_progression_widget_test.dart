import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_services/goal_start_reminder_bridge.dart';
import 'package:motion/motion_screens/ms_goals/goal_tracker_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('a selected collection shows its linked progression in order',
      (tester) async {
    final userProvider = UserUidProvider(
      initialUserUid: 'user-1',
      isInitialized: true,
    );
    const collection = MotionTimelineCollection(
      id: 7,
      currentLoggedInUser: 'user-1',
      name: 'CIFA',
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );
    final foundation = _goal(
      id: 1,
      name: 'CIFA - Foundation Level',
      status: GoalStatus.achieved,
      completionDate: DateTime(2026, 9, 4),
      createdAtEpochMs: 1,
    );
    final intermediate = _goal(
      id: 2,
      name: 'CIFA - Intermediate Level',
      createdAtEpochMs: 2,
    );
    final advanced = _goal(
      id: 3,
      name: 'CIFA - Advanced Level',
      locked: true,
      createdAtEpochMs: 3,
    );
    final registration = _goal(
      id: 4,
      name: 'Exam Registration',
      entryType: TimelineEntryType.timeline,
      createdAtEpochMs: 4,
    );
    final goalProvider = _FakeGoalTrackerProvider(
      userProvider: userProvider,
      collection: collection,
      goals: [foundation, intermediate, advanced, registration],
      prerequisites: const {
        2: [1],
        3: [2],
      },
    );
    addTearDown(() {
      goalProvider.dispose();
      userProvider.dispose();
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<GoalTrackerProvider>.value(
        value: goalProvider,
        child: const MaterialApp(home: GoalTrackerPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('collectionProgression')), findsOneWidget);
    expect(find.text('Progression'), findsOneWidget);
    expect(find.text('Other entries'), findsOneWidget);
    expect(find.text('Exam Registration'), findsOneWidget);
    expect(find.byKey(const Key('progressionNode_1')), findsOneWidget);
    expect(find.byKey(const Key('progressionNode_2')), findsOneWidget);
    expect(find.byKey(const Key('progressionNode_3')), findsOneWidget);

    final foundationY =
        tester.getTopLeft(find.text('CIFA - Foundation Level')).dy;
    final intermediateY =
        tester.getTopLeft(find.text('CIFA - Intermediate Level')).dy;
    final advancedY = tester.getTopLeft(find.text('CIFA - Advanced Level')).dy;
    expect(foundationY, lessThan(intermediateY));
    expect(intermediateY, lessThan(advancedY));
    expect(tester.takeException(), isNull);
  });
}

MotionGoal _goal({
  required int id,
  required String name,
  required int createdAtEpochMs,
  GoalStatus status = GoalStatus.active,
  DateTime? completionDate,
  TimelineEntryType entryType = TimelineEntryType.goal,
  bool locked = false,
}) {
  return MotionGoal(
    id: id,
    currentLoggedInUser: 'user-1',
    name: name,
    startDate: DateTime(2026, 9, 5),
    activationDate: locked ? null : DateTime(2026, 9, 5),
    completionDate: completionDate,
    status: status,
    entryType: entryType,
    collectionId: 7,
    createdAtEpochMs: createdAtEpochMs,
    updatedAtEpochMs: createdAtEpochMs,
  );
}

class _FakeGoalTrackerProvider extends GoalTrackerProvider {
  _FakeGoalTrackerProvider({
    required UserUidProvider userProvider,
    required this.collection,
    required List<MotionGoal> goals,
    required Map<int, List<int>> prerequisites,
  })  : _fakeGoals = List.unmodifiable(goals),
        _prerequisites = Map.unmodifiable(prerequisites),
        super(
          userUidProvider: userProvider,
          reminderBridge: _NoopGoalStartReminderBridge(),
          now: () => DateTime(2026, 11, 17),
        );

  final MotionTimelineCollection collection;
  final List<MotionGoal> _fakeGoals;
  final Map<int, List<int>> _prerequisites;

  @override
  List<MotionGoal> get goals => _fakeGoals;

  @override
  List<MotionGoal> get filteredGoals => _fakeGoals;

  @override
  List<MotionTimelineCollection> get collections => [collection];

  @override
  bool get showAllCollections => false;

  @override
  int? get selectedCollectionId => collection.id;

  @override
  GoalFilter get filter => GoalFilter.all;

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

  @override
  DateTime get today => DateTime(2026, 11, 17);

  @override
  int get activeCount => _fakeGoals.where((goal) => !goal.isAchieved).length;

  @override
  int get achievedCount => _fakeGoals.where((goal) => goal.isAchieved).length;

  @override
  List<int> prerequisiteIdsFor(MotionGoal goal) =>
      List.unmodifiable(_prerequisites[goal.id] ?? const <int>[]);

  @override
  List<MotionGoal> dependentsFor(MotionGoal goal) {
    return _fakeGoals
        .where((entry) =>
            (_prerequisites[entry.id] ?? const <int>[]).contains(goal.id))
        .toList(growable: false);
  }

  @override
  MotionGoal? primaryPrerequisiteFor(MotionGoal goal) {
    final ids = _prerequisites[goal.id] ?? const <int>[];
    if (ids.isEmpty) return null;
    for (final entry in _fakeGoals) {
      if (entry.id == ids.first) return entry;
    }
    return null;
  }

  @override
  MotionTimelineCollection? collectionById(int? collectionId) {
    return collectionId == collection.id ? collection : null;
  }

  @override
  int entryCountForCollection(int? collectionId) {
    return collectionId == collection.id ? _fakeGoals.length : 0;
  }

  @override
  bool isPaused(MotionGoal goal) => false;

  @override
  int activeDaysFor(MotionGoal goal) => goal.elapsedDaysAt(today);

  @override
  Future<void> refresh() async {}
}

class _NoopGoalStartReminderBridge implements GoalStartReminderBridge {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<GoalStartReminder> reminders) async {}

  @override
  Future<void> notifyUnlocked(MotionGoal goal) async {}
}
