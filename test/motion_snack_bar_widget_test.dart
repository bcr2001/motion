import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_reusable/motion_ui/motion_snack_bar.dart';
import 'package:motion/motion_themes/mth_theme/dark_theme.dart';
import 'package:motion/motion_themes/mth_theme/light_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Motion snackbar remains visible in ${brightness.name} mode',
      (tester) async {
        final theme =
            brightness == Brightness.dark ? darkThemeData : lightThemeData;

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showMotionSnackBar(
                    context,
                    message: 'Goal created.',
                  ),
                  child: const Text('Create'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Create'));
        await tester.pump();

        expect(find.text('Goal created.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
        expect(theme.snackBarTheme.backgroundColor, isNotNull);
        expect(theme.snackBarTheme.contentTextStyle?.color, Colors.white);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
