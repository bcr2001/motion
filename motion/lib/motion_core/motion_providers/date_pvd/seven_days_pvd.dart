import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirstAndLastWithSevenDaysDiff extends ChangeNotifier {
  String _firstDay = '';
  String _lastDay = '';

  Timer? timer;

  FirstAndLastWithSevenDaysDiff() {
    _calculateFirstAndLastDay();
    timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _calculateFirstAndLastDay();
      notifyListeners();
    });
  }

  String get firstDay => _firstDay;
  String get lastDay => _lastDay;

  void _calculateFirstAndLastDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Finding the first date
    DateTime firstDate = today.subtract(Duration(days: today.weekday - 1));

    // Finding the last date, seven days after the first date
    DateTime lastDate = firstDate.add(const Duration(days: 6));

    final dateFormat = DateFormat('yyyy-MM-dd');
    _firstDay = dateFormat.format(firstDate);
    _lastDay = dateFormat.format(lastDate);
  }
}
