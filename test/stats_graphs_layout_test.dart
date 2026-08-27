import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_routes/mr_stats/stats_graphs.dart';

void main() {
  testWidgets('year distribution chart fits a narrow phone layout',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(1.1),
            ),
            child: SizedBox(
              width: 334,
              child: YearPieChartDistributionAccountedUnaccounted(
                accountedTotalHours: '3000',
                unAccountedTotalHours: '5760',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Accounted'), findsOneWidget);
    expect(find.text('Unaccounted'), findsOneWidget);
  });
}
