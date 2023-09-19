import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//  gets the current time
//  this is used to update the "date_created" column
//  of any database table that has that column
class CurrentTimeProvider extends ChangeNotifier {
  DateTime _currentTime = DateTime.now();

  CurrentTimeProvider() {
    // Update the current time every minute 
    // This simulates a real-time clock
    _updateTime();
  }

  // Getter method to access the current time in the desired format
  String get formattedTime {
    return DateFormat('HH:mm a').format(_currentTime);
  }

  // Method to update the current time
  void _updateTime() {
    // Update the current time every minute
    Future.delayed(const Duration(minutes: 1), () {
      _currentTime = DateTime.now();
      notifyListeners(); // Notify listeners of the updated time
      _updateTime(); // Schedule the next update
    });
  }
}
