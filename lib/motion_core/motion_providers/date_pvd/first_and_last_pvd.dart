import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// gets the first and last day of any particular month
//  also calculates how many day a particular month has
class FirstAndLastDay extends ChangeNotifier {
  String _firstDay = '';
  String _lastDay = '';
  int _days = 0; // Add the _days variable here.

  Timer? timer;

  FirstAndLastDay() {
    // Initialize the first and last day when the class is instantiated.
    _calculateFirstAndLastDay();
    // Update the dates at the start of each month using a timer.
    timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      if (_calculateFirstAndLastDay()) {
        notifyListeners();
      }
    });
  }

  String get firstDay => _firstDay;
  String get lastDay => _lastDay;
  int get days => _days; // Add the getter for _days.

  bool _calculateFirstAndLastDay() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final firstDay = dateFormat.format(firstDayOfMonth);
    final lastDay = dateFormat.format(lastDayOfMonth);
    final days = lastDayOfMonth.day;

    if (firstDay == _firstDay && lastDay == _lastDay && days == _days) {
      return false;
    }

    _firstDay = firstDay;
    _lastDay = lastDay;

    // Calculate the number of days in the current month.
    _days = days;
    return true;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
