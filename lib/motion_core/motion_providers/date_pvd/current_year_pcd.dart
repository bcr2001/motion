import 'dart:async';
import 'package:flutter/material.dart';


// gets the current year 
class CurrentYearProvider extends ChangeNotifier {
  // The current year
  int _currentYear = DateTime.now().year;

  int get currentYear => _currentYear;

  Timer? _timer;

  CurrentYearProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _getCurrentYear();
    });
  }

  void _getCurrentYear() {
    final int thisYear = DateTime.now().year;

    if (thisYear != _currentYear) {
      _currentYear = thisYear;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
