import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';

void main() {
  testWidgets('failed attempt dialog captures an optional reason in dark mode',
      (tester) async {
    GoalFailureDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showFailGoalDialog(
                  context: context,
                  goalName: 'No Social Media',
                );
              },
              child: const Text('Open failure'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open failure'));
    await tester.pumpAndSettle();
    expect(find.text('End as Failed?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('goalFailureReasonField')),
      'Opened social media',
    );
    await tester.tap(find.byKey(const Key('confirmGoalFailureButton')));
    await tester.pumpAndSettle();

    expect(result?.reason, 'Opened social media');
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a categorized goal from the timeline editor',
      (tester) async {
    GoalDraft? savedDraft;
    const collection = MotionTimelineCollection(
      id: 7,
      currentLoggedInUser: 'user-1',
      name: 'Calisthenics',
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  savedDraft = await showGoalEditorDialog(
                    context: context,
                    collections: const [collection],
                    goals: const [],
                  );
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    expect(find.text('New Timeline'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Ending date'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);

    await tester.tap(find.text('Goal'));
    await tester.pumpAndSettle();
    expect(find.text('No deadline'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('goalTargetDaysField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('goalTargetDaysField')),
      '7',
    );
    await tester.ensureVisible(
      find.byKey(const Key('goalDeadlineDateField')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goalDeadlineDateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Date'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Muscle-up');

    await tester.ensureVisible(find.text('Uncategorized'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uncategorized'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calisthenics').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Goal'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.name, 'Muscle-up');
    expect(savedDraft!.entryType, TimelineEntryType.goal);
    expect(savedDraft!.collectionId, 7);
    expect(savedDraft!.completionDate, isNull);
    expect(savedDraft!.deadlineDate, isNotNull);
    expect(savedDraft!.targetDays, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a completed historical timeline', (tester) async {
    GoalDraft? savedDraft;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                savedDraft = await showGoalEditorDialog(
                  context: context,
                  collections: const [],
                  goals: const [],
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'First Job');
    await tester.ensureVisible(
      find.byKey(const Key('timelineEndingDateField')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timelineEndingDateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Date'));
    await tester.pumpAndSettle();

    expect(find.text('Ongoing'), findsNothing);
    expect(find.text('Add Timeline'), findsOneWidget);
    await tester.ensureVisible(find.text('Add Timeline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Timeline'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.completionDate, isNotNull);
    expect(savedDraft!.completionDate, savedDraft!.startDate);
    expect(savedDraft!.deadlineDate, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('links a new entry to a prerequisite in its collection',
      (tester) async {
    GoalDraft? savedDraft;
    const collection = MotionTimelineCollection(
      id: 7,
      currentLoggedInUser: 'user-1',
      name: 'CIFA',
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );
    final foundation = MotionGoal(
      id: 11,
      currentLoggedInUser: 'user-1',
      name: 'Foundation',
      startDate: DateTime(2026, 1, 1),
      activationDate: DateTime(2026, 1, 1),
      completionDate: DateTime(2026, 6, 1),
      status: GoalStatus.achieved,
      entryType: TimelineEntryType.goal,
      collectionId: 7,
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              savedDraft = await showGoalEditorDialog(
                context: context,
                collections: const [collection],
                goals: [foundation],
              );
            },
            child: const Text('Open progression editor'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open progression editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Intermediate');
    await tester.tap(find.text('Uncategorized'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CIFA').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('goalPrerequisiteField')));
    await tester.tap(find.byKey(const Key('goalPrerequisiteField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundation').last);
    await tester.pumpAndSettle();
    expect(find.text('Starting date'), findsNothing);
    expect(find.text('Starts automatically'), findsOneWidget);
    expect(
      find.byKey(const Key('automaticPrerequisiteStartPanel')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Start Timeline'));
    await tester.tap(find.text('Start Timeline'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.collectionId, 7);
    expect(savedDraft!.prerequisiteId, 11);
    expect(savedDraft!.startsAutomaticallyAfterPrerequisites, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows a linked entry to opt into a delayed start',
      (tester) async {
    GoalDraft? savedDraft;
    const collection = MotionTimelineCollection(
      id: 7,
      currentLoggedInUser: 'user-1',
      name: 'CIFA',
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );
    final foundation = MotionGoal(
      id: 11,
      currentLoggedInUser: 'user-1',
      name: 'Foundation',
      startDate: DateTime(2026, 1, 1),
      activationDate: DateTime(2026, 1, 1),
      completionDate: DateTime(2026, 6, 1),
      status: GoalStatus.achieved,
      collectionId: 7,
      createdAtEpochMs: 1,
      updatedAtEpochMs: 1,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              savedDraft = await showGoalEditorDialog(
                context: context,
                collections: const [collection],
                goals: [foundation],
              );
            },
            child: const Text('Open editor'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Intermediate');
    await tester.tap(find.text('Uncategorized'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CIFA').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('goalPrerequisiteField')));
    await tester.tap(find.byKey(const Key('goalPrerequisiteField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundation').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('delayPrerequisiteStartSwitch')),
    );
    await tester.tap(find.byKey(const Key('delayPrerequisiteStartSwitch')));
    await tester.pumpAndSettle();

    expect(find.text('Delayed start'), findsOneWidget);
    expect(find.text('Not before'), findsOneWidget);
    expect(
      find.byKey(const Key('delayedPrerequisiteStartDateField')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Start Timeline'));
    await tester.tap(find.text('Start Timeline'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.prerequisiteId, 11);
    expect(savedDraft!.startsAutomaticallyAfterPrerequisites, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'collection dialog dismisses safely outside in ${brightness.name} mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showCollectionNameDialog(context: context),
                  child: const Text('New Collection'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('New Collection'));
      await tester.pumpAndSettle();
      expect(find.text('Collection name'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('collectionNameDialogSurface')))
            .width,
        greaterThan(320),
      );

      await tester.enterText(find.byType(TextField), 'Calisthenics');
      await tester.pump();
      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(
        editableText.style.color,
        brightness == Brightness.dark ? Colors.white : Colors.black87,
      );

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.text('Collection name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
