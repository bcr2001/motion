import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// return current theme mode (dark or light theme)
ThemeModeSettings currentSelectedThemeMode(BuildContext context) {
  final selectedTheme = Provider.of<AppThemeModeProvider>(context);
  return selectedTheme.currentThemeMode;
}
