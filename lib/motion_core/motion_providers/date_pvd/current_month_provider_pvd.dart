import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_clock.dart';

class CurrentMonthProvider extends ChangeNotifier {
  CurrentMonthProvider({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance {
    _sync();
    _clock.addListener(_updateFromClock);
  }

  final CalendarClock _clock;
  late int _currentMonthNumber;
  late String _currentMonthName;

  int get currentMonthNumber => _currentMonthNumber;
  String get currentMonthName => _currentMonthName;

  void _sync() {
    _currentMonthNumber = _clock.today.month;
    _currentMonthName = DateFormat.MMMM().format(_clock.today);
  }

  void _updateFromClock() {
    final previousMonth = _currentMonthNumber;
    final previousName = _currentMonthName;
    _sync();
    if (previousMonth != _currentMonthNumber ||
        previousName != _currentMonthName) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
