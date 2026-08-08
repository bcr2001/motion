import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_screens/ms_daily_review/daily_review_dialogs.dart';

void main() {
  testWidgets('Add Missing Time remains usable in dark mode', (tester) async {
    DailyTimeBlockDraft? result;
    final assignment = Assigner(
      currentLoggedInUser: 'user-1',
      subcategoryName: 'AI-Assisted Development',
      mainCategoryName: 'Skills',
      dateCreated: '2026-06-04',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDailyTimeBlockDialog(
                    context: context,
                    date: DateTime(2026, 8, 8),
                    assignments: [assignment],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Missing Time'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('AI-Assisted Development'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add Time'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final durationFields = find.byType(TextField);
    expect(durationFields, findsNWidgets(3));
    await tester.enterText(durationFields.at(0), '1');
    await tester.enterText(durationFields.at(1), '30');
    await tester.tap(find.text('Add Time'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.minutes, 90);
    expect(result!.assignment, same(assignment));
    expect(tester.takeException(), isNull);
  });
}
