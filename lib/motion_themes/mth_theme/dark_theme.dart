import 'package:flutter/material.dart';
import '../mth_styling/motion_text_styling.dart';
import '../mth_styling/widget_bg_color.dart';

ThemeData darkThemeData = ThemeData(
  textTheme: TextTheme(
      // theme for the app body
      bodyLarge: TextEditingStyling.bodyStylingLarge(true),
      bodyMedium: TextEditingStyling.bodyStylingMedium(true),
      bodySmall: TextEditingStyling.bodyStylingSmall(true),

      // theme for manual tracking

      // theme for headings
      headlineLarge: TextEditingStyling.headingLarge(true),
      headlineMedium: TextEditingStyling.headingMedium(true),
      headlineSmall: TextEditingStyling.headingSmall(true)),
  colorScheme: ColorScheme.dark(primary: darkThemeWidgetBgColor),

  // text form field
  dialogTheme: DialogTheme(
      titleTextStyle: TextEditingStyling.dialogTitleTextStyle,
      backgroundColor: darkModeContentWidget),


  // app bar theme
  appBarTheme:
      const AppBarTheme(centerTitle: true, backgroundColor: Colors.black),

  // card theme
  cardTheme: CardTheme(
      elevation: 1,
      margin: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      color: darkModeContentWidget),

  // floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 1,
    backgroundColor: darkModeContentWidget,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
  ),

  // elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
          elevation: const MaterialStatePropertyAll(0.0),
          backgroundColor: MaterialStatePropertyAll(darkModeContentWidget))),

  // icon theme
  iconTheme: const IconThemeData(color: Colors.white),
  dividerTheme: const DividerThemeData(color: Colors.white),
  scaffoldBackgroundColor: Colors.black,
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.dark,
);
