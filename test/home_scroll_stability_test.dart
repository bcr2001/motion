import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/calendar_clock.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/homa_main/home_content_sliver.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = CalendarClock.instance;

  testWidgets('scrolling back to a loaded section preserves data and height',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var loads = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          cacheExtent: 0,
          slivers: [
            HomeContentSliver(children: [
              CachedFutureBuilder<int>(
                cacheKey: 'tracking',
                futureFactory: () async => ++loads,
                builder: (context, snapshot) => SizedBox(
                  key: const ValueKey('tracking'),
                  height: snapshot.hasData ? 450 : 48,
                  child: Text(snapshot.hasData ? 'Activities' : 'Loading'),
                ),
              ),
              ...List.generate(
                  12,
                  (index) => SizedBox(
                        height: 150,
                        child: Text('Section $index'),
                      )),
            ]),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(loads, 1);

    controller.jumpTo(1200);
    await tester.pumpAndSettle();
    controller.jumpTo(100);
    await tester.pump();

    expect(loads, 1, reason: 'Scrolling must not restart database futures.');
    expect(find.text('Loading'), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('tracking'))).height, 450);
    final positionBeforeCompletion = controller.offset;
    await tester.pumpAndSettle();
    expect(controller.offset, positionBeforeCompletion);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
        'tracking list retains its position and refreshes in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pageController = ScrollController();
      final user = UserUidProvider(initialUserUid: 'user', isInitialized: true);
      final assigner = _Assignments();
      final totals = _Totals();
      final date = CurrentDateProvider(clock: clock);
      addTearDown(pageController.dispose);
      addTearDown(user.dispose);
      addTearDown(assigner.dispose);
      addTearDown(totals.dispose);
      addTearDown(date.dispose);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: user),
          ChangeNotifierProvider<AssignerMainProvider>.value(value: assigner),
          ChangeNotifierProvider<SubcategoryTrackerDatabaseProvider>.value(
            value: totals,
          ),
          ChangeNotifierProvider.value(value: date),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: CustomScrollView(
              controller: pageController,
              cacheExtent: 0,
              slivers: [
                HomeContentSliver(children: [
                  const SizedBox(height: 100),
                  const CardBuilder(
                    timeAccountedAndOthers: Text('Tracking Window'),
                    itemsToBeDisplayed: SubcategoryAndCurrentDayTotals(),
                  ),
                  ...List.generate(12, (_) => const SizedBox(height: 150)),
                ]),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final listFinder = find.descendant(
        of: find.byType(SubcategoryAndCurrentDayTotals),
        matching: find.byType(ListView),
      );
      final innerController = tester.widget<ListView>(listFinder).controller!;
      await tester.drag(listFinder, const Offset(0, -140));
      await tester.pumpAndSettle();
      final listOffset = innerController.offset;
      expect(listOffset, greaterThan(0));
      expect(pageController.offset, 0);
      expect(totals.loads, 1);

      for (var pass = 0; pass < 3; pass++) {
        pageController.jumpTo(1200);
        await tester.pumpAndSettle();
        pageController.jumpTo(0);
        await tester.pumpAndSettle();
        expect(totals.loads, 1);
        expect(tester.widget<ListView>(listFinder).controller, innerController);
        expect(innerController.offset, listOffset);
        expect(find.byType(ShimmerWidget), findsNothing);
      }

      innerController.jumpTo(0);
      await tester.pumpAndSettle();
      final cardHeight = tester.getSize(find.byType(CardBuilder)).height;
      totals.recordMinutes(30);
      await tester.pumpAndSettle();
      expect(totals.loads, 2, reason: 'Real data updates must still refresh.');
      expect(find.text('30.00mins'), findsOneWidget);
      expect(tester.getSize(find.byType(CardBuilder)).height, cardHeight);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Assignments extends AssignerMainProvider {
  @override
  UnmodifiableListView<Assigner> get assignerItems => UnmodifiableListView(
        List.generate(
            16,
            (index) => Assigner(
                  id: index,
                  currentLoggedInUser: 'user',
                  subcategoryName: 'Activity $index',
                  mainCategoryName: 'Skills',
                  dateCreated: '2026-01-01',
                  isActive: 1,
                )),
      );
}

class _Totals extends SubcategoryTrackerDatabaseProvider {
  int loads = 0;
  int revision = 0;
  double minutes = 0;

  @override
  int get refreshKey => revision;

  void recordMinutes(double value) {
    minutes = value;
    revision++;
    notifyListeners();
  }

  @override
  Future<Map<String, double>> retrieveSubcategoryTotalsForDate(
      String currentDate, String currentUser) async {
    loads++;
    return {'Activity 0': minutes};
  }
}
