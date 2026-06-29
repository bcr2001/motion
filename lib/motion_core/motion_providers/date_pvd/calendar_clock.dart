import 'dart:async';

import 'package:flutter/widgets.dart';

class CalendarClock extends ChangeNotifier with WidgetsBindingObserver {
  CalendarClock._() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMidnight();
  }

  static final CalendarClock instance = CalendarClock._();

  DateTime _today = _dateOnly(DateTime.now());
  Timer? _midnightTimer;

  DateTime get today => _today;

  void refresh() {
    final currentDate = _dateOnly(DateTime.now());
    if (currentDate != _today) {
      _today = currentDate;
      notifyListeners();
    }
    _scheduleNextMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  void _scheduleNextMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }
}
