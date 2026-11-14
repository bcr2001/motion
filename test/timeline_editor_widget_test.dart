import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';

void main() {
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
    await tester.tap(find.byKey(const Key('goalDeadlineDateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Date'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Muscle-up');

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
