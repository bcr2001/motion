import 'package:flutter/material.dart';
import '../mth_styling/motion_text_styling.dart';
import '../mth_styling/widget_bg_color.dart';

ThemeData darkThemeData = ThemeData(

    textTheme: TextTheme(
      // theme for the app body
      bodyLarge: TextEditingStyling.bodyStyling(true),
      bodyMedium:TextEditingStyling.bodyStyling(true),
      bodySmall: TextEditingStyling.bodyStyling(true),

      // theme for headings 
      headlineLarge: TextEditingStyling.headingLarge(true),
      headlineMedium: TextEditingStyling.headingMedium(true),
      headlineSmall: TextEditingStyling.headingSmall(true)
    ),

    colorScheme: ColorScheme.dark(
      primary: darkThemeWidgetBgColor
    ),

    // list tile
    listTileTheme:const ListTileThemeData(

      textColor: Colors.blue
    ),

    // text form field
    dialogTheme: DialogTheme(
    titleTextStyle: TextEditingStyling.dialogTitleTextStyle,
    backgroundColor: darkThemeWidgetBgColor),
    popupMenuTheme: PopupMenuThemeData(color: darkThemeWidgetBgColor),

    appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: darkThemeWidgetBgColor),

    scaffoldBackgroundColor: Colors.black,

    useMaterial3: true,

    visualDensity: VisualDensity.adaptivePlatformDensity,

    brightness: Brightness.dark
);