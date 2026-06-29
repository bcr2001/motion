import 'package:flutter/material.dart';

import 'calendar_clock.dart';

class CurrentYearProvider extends ChangeNotifier {
  CurrentYearProvider({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance,
        _currentYear = (clock ?? CalendarClock.instance).today.year.toString() {
    _clock.addListener(_updateFromClock);
  }

  final CalendarClock _clock;
  String _currentYear;

  String get currentYear => _currentYear;

  void _updateFromClock() {
    final currentYear = _clock.today.year.toString();
    if (currentYear == _currentYear) return;

    _currentYear = currentYear;
    notifyListeners();
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
