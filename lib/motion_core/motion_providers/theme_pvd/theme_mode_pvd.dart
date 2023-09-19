import 'package:flutter/material.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// app theme modes
enum ThemeModeSettings {darkMode, lightMode }

// theme mode provider class
class AppThemeModeProvider extends ChangeNotifier {
  // shared preference instance
  SharedPreferences? _prefs;

  // key to stored shared preferences
  static const String themeKey = "themeKey";

  // current theme mode
  ThemeModeSettings _currentThemeMode = ThemeModeSettings.lightMode;

  // current theme mode name
  String _currentThemeModeName = "Light Mode";

  // theme mode text color(light mode)
  Color _themeModeTextColor = Colors.black;

  // current switch value (false = light mode)
  bool switchValue = false;

  // get currentThemeMode
  ThemeModeSettings get currentThemeMode => _currentThemeMode;

  // get currentThemeModeName
  String get currentThemeModeName => _currentThemeModeName;

  // get theme mode text color
  Color get themeModeTextColor => _themeModeTextColor;

  // initialize shared preferenced
 Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs != null) {
      _loadSavedThemeMode();
    }
  }
  // theme mode change handler
  void switchThemeModes(bool value) {
    // dark mode
    if (value == true) {
      switchValue = value;
      _currentThemeMode = ThemeModeSettings.darkMode;
      _currentThemeModeName = "Dark Mode";
      _themeModeTextColor = Colors.white;
    // light mode
    } else {
      switchValue = value;
      _currentThemeMode = ThemeModeSettings.lightMode;
      _currentThemeModeName = "Light Mode";
      _themeModeTextColor = Colors.black;
    }
    // save the current theme
    _prefs?.setBool(themeKey, value);
    // notify listener to rebuild ui with appropriate theme mode
    notifyListeners();
  }

  // load the saved theme mode
  void _loadSavedThemeMode() {
    try {
      final savedThemeMode = _prefs!.getBool(themeKey);
      if (savedThemeMode != null) {
        switchValue = savedThemeMode;
        if (switchValue == true) {
          _currentThemeMode = ThemeModeSettings.darkMode;
          _currentThemeModeName = "Dark Mode";
        } else {
          _currentThemeMode = ThemeModeSettings.lightMode;
          _currentThemeModeName = "Light Mode";
        }
      }
    } catch (error) {
      logger.e("Error: $error");
    }
  }
}
