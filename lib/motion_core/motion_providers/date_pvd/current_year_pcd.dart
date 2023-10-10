import 'dart:async';
import 'package:flutter/material.dart';


// A class that gets the current year.
class CurrentYearProvider extends ChangeNotifier {
  // The current year
  int _currentYear = DateTime.now().year;

  int get currentYear => _currentYear;

  Timer? _timer;

  // Constructor that initializes the timer to update the current year daily.
  CurrentYearProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _getCurrentYear();
    });
  }

  // Method to get the current year and update it if it changes.
  void _getCurrentYear() {
    final int thisYear = DateTime.now().year;

    if (thisYear != _currentYear) {
      _currentYear = thisYear;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing of the provider.
    super.dispose();
  }
}
