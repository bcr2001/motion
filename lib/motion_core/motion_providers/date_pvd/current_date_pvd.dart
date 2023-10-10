import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// contains functions that constantly updates
//  the current date in the desired format
class CurrentDateProvider extends ChangeNotifier {
  String _currentDate = DateFormat("yyyy-MM-dd").format(DateTime.now());

  String get currentDate => _currentDate;

  Timer? _timer;

  // Constructor that initializes the timer to update the current date daily.
  CurrentDateProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      getCurrentDate();
    });
  }

  // Method to get the new date after a day and reset the
  // date stored by the _currentDate variable.
  void getCurrentDate() {
    final String thisMoment = DateFormat("yyyy-MM-dd").format(DateTime.now());

    if (thisMoment != _currentDate) {
      _currentDate = thisMoment;
      notifyListeners();
    }
  }

  // Method to format the date with the day of the week and suffix.
  String getFormattedDate() {
    final List<String> dateParts = _currentDate.split('-');
    if (dateParts.length != 3) {
      return "Invalid Date";
    }

    final int year = int.tryParse(dateParts[0]) ?? 0;
    final int month = int.tryParse(dateParts[1]) ?? 0;
    final int day = int.tryParse(dateParts[2]) ?? 0;

    // Convert the date string to a DateTime object
    final DateTime dateTime = DateTime(year, month, day);

    // Get the day of the week name using the intl package
    final String dayOfWeekName = DateFormat('EEEE').format(dateTime);


    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1) {
      return "Invalid Date";
    }
    // Add the appropriate suffix to the day (e.g., 1st, 2nd, 3rd, 4th, etc.)
    final String daySuffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';

    return '$day$daySuffix $dayOfWeekName';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
