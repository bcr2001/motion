import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// (new) Theme Mode Provider
enum ThemeModeSettingsN1 { darkMode, lightMode, systemDefault }

class AppThemeModeProviderN1 extends ChangeNotifier {
  // shared preference instance
  SharedPreferences? _prefs;

  // key for storing theme mode
  static const String themeModeKey = "themeModeKey";

  // current radio group value (0 = system default)
  int _groupValue = 0;

  // currently selected mode
  ThemeModeSettingsN1 _currentThemeModeA1 = ThemeModeSettingsN1.systemDefault;

  // theme mode getter
  ThemeModeSettingsN1 get currentThemeMode => _currentThemeModeA1;

  // radio value getter
  int get radioGroupValue => _groupValue;

  // initialize shared preference and load saved theme mode
  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    _loadThemeMode();
  }

  // load saved theme mode from SharedPreferences
  void _loadThemeMode() {
    final savedThemeMode = _prefs?.getInt(themeModeKey);

    if (savedThemeMode != null) {
      _groupValue = savedThemeMode;

      if (savedThemeMode == 0) {
        _currentThemeModeA1 = ThemeModeSettingsN1.systemDefault;
      } else if (savedThemeMode == 1) {
        _currentThemeModeA1 = ThemeModeSettingsN1.lightMode;
      } else {
        _currentThemeModeA1 = ThemeModeSettingsN1.darkMode;
      }
    }
  }

  // handles setting of theme mode
  void themeModeChanger(int value) {
    _groupValue = value;

    if (value == 0) {
      _currentThemeModeA1 = ThemeModeSettingsN1.systemDefault;
    } else if (value == 1) {
      _currentThemeModeA1 = ThemeModeSettingsN1.lightMode;
    } else {
      _currentThemeModeA1 = ThemeModeSettingsN1.darkMode;
    }

    // save the current theme mode to shared preferences
    _prefs!.setInt(themeModeKey, value);

    // notify listeners
    notifyListeners();
  }
}
