import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

class CalendarClock extends ChangeNotifier with WidgetsBindingObserver {
  CalendarClock._() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMidnight();
  }

  static final CalendarClock instance = CalendarClock._();

  DateTime _today = MotionDateUtils.today();
  Timer? _midnightTimer;

  DateTime get today => _today;

  void refresh() {
    final currentDate = MotionDateUtils.today();
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }
}
