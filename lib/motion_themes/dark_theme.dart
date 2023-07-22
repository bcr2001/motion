import 'package:flutter/material.dart';
import 'motion_text_styling.dart';
import 'widget_bg_color.dart';

ThemeData darkThemeData = ThemeData(

    textTheme: TextTheme(
      bodyLarge: TextEditingStyling.bodyStylingDarkMode,
      bodyMedium:TextEditingStyling.bodyStylingDarkMode,
      bodySmall: TextEditingStyling.bodyStylingDarkMode,
    ),

    colorScheme: ColorScheme.dark(
      primary: darkThemeWidgetBgColor
    ),

    // list tile
    listTileTheme:const ListTileThemeData(
      textColor: Colors.white
    ),

    // text form field
    dialogTheme: DialogTheme(
    titleTextStyle: TextEditingStyling.dialogTitleTextStyle,
    backgroundColor: darkThemeWidgetBgColor),
    popupMenuTheme: PopupMenuThemeData(color: darkThemeWidgetBgColor),

    appBarTheme: AppBarTheme(
        centerTitle: true,
        titleTextStyle: TextEditingStyling.appTitleStyle,
        backgroundColor: darkThemeWidgetBgColor),

    scaffoldBackgroundColor: Colors.black,

    useMaterial3: true,

    visualDensity: VisualDensity.adaptivePlatformDensity,

    brightness: Brightness.dark
);