import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_clock.dart';

class FirstAndLastWithSevenDaysDiff extends ChangeNotifier {
  FirstAndLastWithSevenDaysDiff({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance {
    _calculate();
    _clock.addListener(_updateFromClock);
  }

  final CalendarClock _clock;
  late String _firstDay;
  late String _lastDay;

  String get firstDay => _firstDay;
  String get lastDay => _lastDay;

  void _calculate() {
    final today = _clock.today;
    final firstDate = today.subtract(Duration(days: today.weekday - 1));
    final lastDate = firstDate.add(const Duration(days: 6));
    final formatter = DateFormat('yyyy-MM-dd');
    _firstDay = formatter.format(firstDate);
    _lastDay = formatter.format(lastDate);
  }

  void _updateFromClock() {
    final previousFirst = _firstDay;
    final previousLast = _lastDay;
    _calculate();
    if (previousFirst != _firstDay || previousLast != _lastDay) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
