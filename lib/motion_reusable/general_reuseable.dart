import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
import 'package:provider/provider.dart';

// logger instance
var logger = Logger();

// // return current theme mode (dark or light theme)
ThemeModeSettings currentSelectedThemeMode(BuildContext context) {
  final selectedTheme = Provider.of<AppThemeModeProvider>(context);
  return selectedTheme.currentThemeMode;
}

// Circular progress indicator
Future circularIndicator(context) {
  return showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: CircularProgressIndicator(
            color: blueMainColor,
          ),
        );
      });
}

// snack bar for sign in and sign out error messages
errorSnack(context, {required errorMessage}) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage, style: contentStyle(color:const Color(0xFFFF6B00)),))
  ); 
}