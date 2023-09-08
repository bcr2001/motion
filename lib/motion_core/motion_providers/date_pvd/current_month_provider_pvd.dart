import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentMonthProvider extends ChangeNotifier {
  // number rep of the month
  int _currentMonthNumber = DateTime.now().month;

  int get currentMonthNumber => _currentMonthNumber;

  // name of the month
  String _currentMonthName = DateFormat.MMMM().format(DateTime.now());

  String get currentMonthName => _currentMonthName;

  Timer? _timer;

  CurrentMonthProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _getCurrentMonth();
      _getCurrentMonthNumber;
    });
  }

  void _getCurrentMonth() {
    final String thisMoment = DateFormat.MMMM().format(DateTime.now());

    if (thisMoment != _currentMonthName) {
      _currentMonthName = thisMoment;
      notifyListeners();
    }
  }

  void _getCurrentMonthNumber() {
    final int thisMoment = DateTime.now().month;

    if (thisMoment != _currentMonthNumber) {
      _currentMonthNumber = thisMoment;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
