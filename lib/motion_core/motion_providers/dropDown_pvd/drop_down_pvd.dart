import 'package:flutter/material.dart';

// A class that handles the values and their selection in a drop-down button.
class DropDownTrackProvider extends ChangeNotifier {
  String? _selectedValue;

  String? get selectedValue => _selectedValue;

  // Method to change the selected value and notify listeners.
  void changeSelectedValue(String? value) {
    _selectedValue = value;
    notifyListeners();
  }
}
