import 'package:flutter/material.dart';
import '../mth_styling/motion_text_styling.dart';

ThemeData lightThemeData = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
  ),

  // app bar theme
  appBarTheme: const AppBarTheme(
    centerTitle: true,
  ),

  // text theme
  textTheme: TextTheme(
    bodyLarge: TextEditingStyling.bodyStyling(false),
    bodyMedium: TextEditingStyling.bodyStyling(false),
    bodySmall: TextEditingStyling.bodyStyling(false),

    // theme for headings
    headlineLarge: TextEditingStyling.headingLarge(false),
    headlineMedium: TextEditingStyling.headingMedium(false),
    headlineSmall: TextEditingStyling.headingSmall(false)
  ),

  // alert dialog theme
  dialogTheme:
      DialogTheme(titleTextStyle: TextEditingStyling.dialogTitleTextStyle),

  // elevated button

  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);
