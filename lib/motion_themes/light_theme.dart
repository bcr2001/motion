import 'package:flutter/material.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'motion_text_styling.dart';
import 'package:google_fonts/google_fonts.dart';


ThemeData lightThemeData = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
  ),

  // app bar theme
  appBarTheme: AppBarTheme(
    centerTitle: true,
    titleTextStyle: appTitleStyle,
  ),

  // text theme
  textTheme: GoogleFonts.latoTextTheme().copyWith(
    bodyLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
    bodyMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
    bodySmall: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400)
  ),

  // alert dialog theme
  dialogTheme:  const DialogTheme(
    titleTextStyle: dialogTitleTextStyle
  ),

  // elevated button
  


  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);
