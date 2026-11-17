import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import '../mth_styling/motion_text_styling.dart';

ThemeData lightThemeData = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
  ),

  // app bar theme
  appBarTheme: const AppBarTheme(centerTitle: true),

  // text theme
  textTheme: TextTheme(
      bodyLarge: AppTextStyle.bodyStylingLarge(false),
      bodyMedium: AppTextStyle.bodyStylingMedium(false),
      bodySmall: AppTextStyle.bodyStylingSmall(false),

      // theme for headings
      headlineLarge: AppTextStyle.headingLarge(false),
      headlineMedium: AppTextStyle.headingMedium(false),
      headlineSmall: AppTextStyle.headingSmall(false)),

  // alert dialog theme
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColor.lightModeContentWidget,
  ),

  // card theme
  cardTheme: const CardThemeData(
    elevation: 1,
    margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    color: AppColor.lightModeContentWidget,
  ),

  // floating action button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 1,
    backgroundColor: AppColor.lightModeContentWidget,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
  ),

  // icon theme
  iconTheme: const IconThemeData(color: Colors.black),

  dividerTheme: const DividerThemeData(color: Colors.black),

  // elevated button theme
  elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
          elevation: WidgetStatePropertyAll(0.0),
          backgroundColor:
              WidgetStatePropertyAll(AppColor.lightModeContentWidget))),

  // Snackbar theme
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF202738),
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

  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);
