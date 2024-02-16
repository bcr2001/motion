import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class that gets and updates the current year as a string.
class CurrentYearProvider extends ChangeNotifier {
  String _currentYear = DateTime.now().year.toString();

  String get currentYear => _currentYear;

  Timer? _timer;

  CurrentYearProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _checkAndUpdateYear();
    });

    // Check and update the year on initialization.
    _checkAndUpdateYear();
  }

  // Method to check and update the current year based on the stored value.
  Future<void> _checkAndUpdateYear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String lastUpdateYear =
        prefs.getString('lastUpdateYear') ?? DateTime.now().year.toString();

    final String thisYear = DateTime.now().year.toString();

    if (lastUpdateYear != thisYear) {
      _currentYear = thisYear;
      prefs.setString('lastUpdateYear', thisYear);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing of the provider.
    super.dispose();
  }
}
