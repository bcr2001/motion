import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
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

  // card theme
  cardTheme:  CardTheme(
    elevation: 1,
    margin:  const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    color: lightModeContentWidget
  ),

  // floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 1,
    backgroundColor: lightModeContentWidget,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25.0)
    ),
  ),

  // icon theme
  iconTheme: const IconThemeData(
    color: Colors.black
  ),

  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);
