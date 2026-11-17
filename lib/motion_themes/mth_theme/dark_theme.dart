import 'package:flutter/material.dart';
import '../mth_styling/motion_text_styling.dart';
import '../mth_styling/app_color.dart';

ThemeData darkThemeData = ThemeData(
  textTheme: TextTheme(
      // theme for the app body
      bodyLarge: AppTextStyle.bodyStylingLarge(true),
      bodyMedium: AppTextStyle.bodyStylingMedium(true),
      bodySmall: AppTextStyle.bodyStylingSmall(true),

      // theme for manual tracking

      // theme for headings
      headlineLarge: AppTextStyle.headingLarge(true),
      headlineMedium: AppTextStyle.headingMedium(true),
      headlineSmall: AppTextStyle.headingSmall(true)),

  colorScheme: const ColorScheme.dark(primary: AppColor.darkThemeWidgetBgColor),

  // text form field
  dialogTheme:
      const DialogThemeData(backgroundColor: AppColor.darkModeContentWidget),

  // app bar theme
  appBarTheme:
      const AppBarTheme(centerTitle: true, backgroundColor: Colors.black),

  // card theme
  cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      elevation: 1,
      margin: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      color: AppColor.darkModeContentWidget),

  // floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 1,
    backgroundColor: AppColor.darkModeContentWidget,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
  ),

  // elevated button theme
  elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
          elevation: WidgetStatePropertyAll(0.0),
          backgroundColor:
              WidgetStatePropertyAll(AppColor.darkModeContentWidget))),

  // icon theme
  iconTheme: const IconThemeData(color: Colors.white),
  dividerTheme: const DividerThemeData(color: Colors.white),
  scaffoldBackgroundColor: Colors.black,
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.dark,

  // Snackbar theme
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF252C3B),
    actionTextColor: AppColor.blueMainColor,
    elevation: 5,
    insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    contentTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
);
