import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A class that gets the current month and performs formatting on the month.
class CurrentMonthProvider extends ChangeNotifier {
  // Number representation of the month.
  int _currentMonthNumber = DateTime.now().month;

  int get currentMonthNumber => _currentMonthNumber;

  // name of the month
  String _currentMonthName = DateFormat.MMMM().format(DateTime.now());

  String get currentMonthName => _currentMonthName;

  Timer? _timer;

  // Constructor that initializes the timer to update the current month daily.
  CurrentMonthProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _updateCurrentMonth();
    });
  }

  // Method to update the current month values if they change.
  void _updateCurrentMonth() {
    final now = DateTime.now();
    final currentMonthName = DateFormat.MMMM().format(now);
    final currentMonthNumber = now.month;

    if (currentMonthName == _currentMonthName &&
        currentMonthNumber == _currentMonthNumber) {
      return;
    }

    _currentMonthName = currentMonthName;
    _currentMonthNumber = currentMonthNumber;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing of the provider.
    super.dispose();
  }
}
