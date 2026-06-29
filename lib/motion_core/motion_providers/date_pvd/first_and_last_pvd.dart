import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_clock.dart';

class FirstAndLastDay extends ChangeNotifier {
  FirstAndLastDay({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance {
    _calculate();
    _clock.addListener(_updateFromClock);
  }

  final CalendarClock _clock;
  late String _firstDay;
  late String _lastDay;
  late int _days;

  String get firstDay => _firstDay;
  String get lastDay => _lastDay;
  int get days => _days;

  void _calculate() {
    final today = _clock.today;
    final formatter = DateFormat('yyyy-MM-dd');
    _firstDay = formatter.format(DateTime(today.year, today.month, 1));
    final lastDate = DateTime(today.year, today.month + 1, 0);
    _lastDay = formatter.format(lastDate);
    _days = lastDate.day;
  }

  void _updateFromClock() {
    final previousFirst = _firstDay;
    final previousLast = _lastDay;
    final previousDays = _days;
    _calculate();
    if (previousFirst != _firstDay ||
        previousLast != _lastDay ||
        previousDays != _days) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
