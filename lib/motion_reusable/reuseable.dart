import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_providers/zen_quotes_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// return current theme mode (dark or light theme)
ThemeModeSettings currentSelectedThemeMode(BuildContext context) {
  final selectedTheme = Provider.of<AppThemeModeProvider>(context);
  return selectedTheme.currentThemeMode;
}

// returns the current month
String currentMonth() {
  DateTime currentDate = DateTime.now();

  String currentMonthName = DateFormat.MMMM().format(currentDate);

  return currentMonthName;
}

// returns the current year
String currentYear() {
  // date
  int currentYearIn = DateTime.now().year;

  return currentYearIn.toString();
}
