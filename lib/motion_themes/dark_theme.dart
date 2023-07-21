import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'motion_text_styling.dart';
import 'widget_bg_color.dart';

ThemeData darkThemeData = ThemeData(

    // text theme
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      bodyLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.white),
      bodyMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.white),
      bodySmall: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.white),
    ),

  // color scheme
    colorScheme: ColorScheme.dark(
      primary: darkThemeWidgetBgColor
    ),

    // list tile
    listTileTheme:const ListTileThemeData(
      textColor: Colors.white
    ),

    dialogTheme: DialogTheme(
      titleTextStyle: dialogTitleTextStyle,
    backgroundColor: darkThemeWidgetBgColor),

    popupMenuTheme: PopupMenuThemeData(color: darkThemeWidgetBgColor),

    appBarTheme: AppBarTheme(
        centerTitle: true,
        titleTextStyle: appTitleStyle,
        backgroundColor: darkThemeWidgetBgColor),

    scaffoldBackgroundColor: Colors.black,

    useMaterial3: true,

    visualDensity: VisualDensity.adaptivePlatformDensity,

    brightness: Brightness.dark
);