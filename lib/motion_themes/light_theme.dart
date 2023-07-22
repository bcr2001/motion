import 'package:flutter/material.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'motion_text_styling.dart';
import 'package:google_fonts/google_fonts.dart';


ThemeData lightThemeData = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
  ),

  // app bar theme
  appBarTheme:  AppBarTheme(
    centerTitle: true,
    titleTextStyle: TextEditingStyling.appTitleStyle,
  ),

  // text theme
  textTheme: TextTheme(
    bodyLarge: TextEditingStyling.bodyStylingLightMode,
    bodyMedium:  TextEditingStyling.bodyStylingLightMode,
    bodySmall: TextEditingStyling.bodyStylingLightMode
  ),

  // alert dialog theme
  dialogTheme:  DialogTheme(
    titleTextStyle: TextEditingStyling.dialogTitleTextStyle
  ),

  // elevated button
  


  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);
