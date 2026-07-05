import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

import 'calendar_clock.dart';

class CurrentDateProvider extends ChangeNotifier {
  CurrentDateProvider({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance {
    _currentDate = MotionDateUtils.formatDbDate(_clock.today);
    _clock.addListener(_updateFromClock);
  }

  final CalendarClock _clock;
  late String _currentDate;

  String get currentDate => _currentDate;

  void getCurrentDate() {
    _clock.refresh();
    _updateFromClock();
  }

  String getFormattedDate() {
    final dateTime = MotionDateUtils.parseStoredDate(_currentDate);
    if (dateTime == null) return "Invalid Date";

    return MotionDateUtils.formatWeekdayOrdinal(dateTime);
  }

  void _updateFromClock() {
    final currentDate = MotionDateUtils.formatDbDate(_clock.today);
    if (currentDate == _currentDate) return;

    _currentDate = currentDate;
    notifyListeners();
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
