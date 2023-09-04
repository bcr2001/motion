import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class CurrentDataProvider extends ChangeNotifier {
  String _currentData = DateFormat("dd/MM/yyy").format(DateTime.now());

  String get currentData => _currentData;

  Timer? _timer;

  CurrentDataProvider() {
    _timer = Timer.periodic(const Duration(days: 1), (Timer t) {
      getCurrentDate();
    });
  }

  void getCurrentDate() {
    final String thisMoment = DateFormat("dd/MM/yyy").format(DateTime.now());

    if (thisMoment != _currentData) {
      _currentData = thisMoment;
      notifyListeners();
    }
  }

  // String getFormattedDate() {
  //   final List<String> dateParts = _currentData.split('/');
  //   if (dateParts.length != 3) {
  //     return "Invalid Date";
  //   }

  //   final int day = int.tryParse(dateParts[0]) ?? 0;
  //   final int month = int.tryParse(dateParts[1]) ?? 0;
  //   final int year = int.tryParse(dateParts[2]) ?? 0;

  //   if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1) {
  //     return "Invalid Date";
  //   }

  //   final DateTime currentDate = DateTime(year, month, day);
  //   final String formattedDate = DateFormat("MMMM d y").format(currentDate);

  //   // Add the appropriate suffix to the day (e.g., 1st, 2nd, 3rd, 4th, etc.)
  //   final String daySuffix = (day >= 11 && day <= 13)
  //       ? 'th'
  //       : (day % 10 == 1)
  //           ? 'st'
  //           : (day % 10 == 2)
  //               ? 'nd'
  //               : (day % 10 == 3)
  //                   ? 'rd'
  //                   : 'th';

  //   return '$formattedDate$daySuffix';
  // }
  String getFormattedDate() {
    final List<String> dateParts = _currentData.split('/');
    if (dateParts.length != 3) {
      return "Invalid Date";
    }

    final int day = int.tryParse(dateParts[0]) ?? 0;
    final int month = int.tryParse(dateParts[1]) ?? 0;
    final int year = int.tryParse(dateParts[2]) ?? 0;

    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1) {
      return "Invalid Date";
    }

     // list of month names
    final List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

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

    return '${monthNames[month-1]} $day$daySuffix $year';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
