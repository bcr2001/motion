import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_routes/route_action.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'home actions omit AI forecast in ${brightness.name} mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness, useMaterial3: true),
            home: Scaffold(
              appBar: AppBar(actions: const [MotionActionButtons()]),
            ),
          ),
        );

        expect(find.text('AI'), findsNothing);
        expect(find.byTooltip('AI Forecast'), findsNothing);
        expect(find.byTooltip('Monthly Report'), findsOneWidget);
        expect(find.byTooltip('Timelines'), findsOneWidget);
        expect(find.byTooltip('Menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
