import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class CurrentDataProvider extends ChangeNotifier {
  String _currentData = DateFormat("dd/MM/yyy").format(DateTime.now());

  String get currentData => _currentData;

  Timer? _timer;

  CurrentDataProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      _getCurrentDate();
    });
  }

  void _getCurrentDate() {
    final String thisMoment = DateFormat("dd/MM/yyy").format(DateTime.now());

    if (thisMoment != _currentData) {
      _currentData = thisMoment;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
