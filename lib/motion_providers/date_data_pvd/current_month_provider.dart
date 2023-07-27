import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentMonthProvider extends ChangeNotifier {
  String _currentMonthName = DateFormat.MMMM().format(DateTime.now());

  String get currentMonthName => _currentMonthName;

  Timer? _timer;

  CurrentMonthProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _getCurrentMonth();
    });
  }

  void _getCurrentMonth() {
    final String thisMoment = DateFormat.MMMM().format(DateTime.now());

    if (thisMoment != _currentMonthName) {
      _currentMonthName = thisMoment;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
