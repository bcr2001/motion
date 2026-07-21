import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_screens/ms_daily_review/daily_review_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the selected date summary and saved blocks',
      (tester) async {
    final subcategoryProvider = _FakeSubcategoryProvider();
    final experienceProvider = _FakeExperienceProvider();
    final userProvider = UserUidProvider(
      initialUserUid: 'user-1',
      isInitialized: true,
    );
    final assignerProvider = AssignerMainProvider();
    addTearDown(subcategoryProvider.dispose);
    addTearDown(experienceProvider.dispose);
    addTearDown(userProvider.dispose);
    addTearDown(assignerProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider<SubcategoryTrackerDatabaseProvider>.value(
            value: subcategoryProvider,
          ),
          ChangeNotifierProvider<ExperiencePointTableProvider>.value(
            value: experienceProvider,
          ),
          ChangeNotifierProvider.value(value: assignerProvider),
        ],
        child: MaterialApp(
          home: DailyReviewPage(initialDate: DateTime(2026, 7, 20)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Daily Review'), findsOneWidget);
    expect(find.text('24-Hour Overview'), findsOneWidget);
    expect(find.text('1hr'), findsWidgets);
    expect(find.text('5 XP earned'), findsOneWidget);
    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Skills | 1hr'), findsOneWidget);

    await tester.tap(find.byTooltip('Select date'));
    await tester.pumpAndSettle();

    expect(find.text('Select Review Date'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Open Review'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

class _FakeSubcategoryProvider extends SubcategoryTrackerDatabaseProvider {
  @override
  Future<List<Subcategories>> retrieveSubcategoryEntriesForDate({
    required String date,
    required String currentUser,
  }) async {
    return [
      Subcategories(
        id: 1,
        date: date,
        mainCategoryName: 'Skills',
        subcategoryName: 'Chess',
        timeSpent: 60,
        currentLoggedInUser: currentUser,
      ),
    ];
  }
}

class _FakeExperienceProvider extends ExperiencePointTableProvider {
  @override
  Future<Map<String, int>> retrieveDailyExperiencePointBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    return const {'Skills': 5};
  }
}
