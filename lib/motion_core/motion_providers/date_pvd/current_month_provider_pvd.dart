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
      _getCurrentMonth();
      _getCurrentMonthNumber;
    });
  }

  // Method to get the current month name and update it if it changes.
  void _getCurrentMonth() {
    final String thisMoment = DateFormat.MMMM().format(DateTime.now());

    if (thisMoment != _currentMonthName) {
      _currentMonthName = thisMoment;
      notifyListeners();
    }
  }

  // Method to get the current month number and update it if it changes.
  void _getCurrentMonthNumber() {
    final int thisMoment = DateTime.now().month;

    if (thisMoment != _currentMonthNumber) {
      _currentMonthNumber = thisMoment;
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing of the provider.
    super.dispose();
  }
}
