import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_clock.dart';

class CurrentDateProvider extends ChangeNotifier {
  CurrentDateProvider({CalendarClock? clock})
      : _clock = clock ?? CalendarClock.instance {
    _currentDate = _formatDate(_clock.today);
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
    final dateTime = DateTime.tryParse(_currentDate);
    if (dateTime == null) return "Invalid Date";

    final day = dateTime.day;
    final daySuffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';

    return '${DateFormat('EEEE').format(dateTime)} $day$daySuffix ';
  }

  void _updateFromClock() {
    final currentDate = _formatDate(_clock.today);
    if (currentDate == _currentDate) return;

    _currentDate = currentDate;
    notifyListeners();
  }

  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void dispose() {
    _clock.removeListener(_updateFromClock);
    super.dispose();
  }
}
