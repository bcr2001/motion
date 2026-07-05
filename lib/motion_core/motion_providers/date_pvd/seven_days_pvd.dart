import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

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
    final range = MotionDateUtils.weekRange(_clock.today);
    _firstDay = range.startIso;
    _lastDay = range.endIso;
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
