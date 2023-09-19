import 'package:flutter/material.dart';

// handles the values and their selection in a 
// drop down button
class DropDownTrackProvider extends ChangeNotifier {
  String? _selectedValue;

  String? get selectedValue => _selectedValue;

  void changeSelectedValue(String? value) {
    _selectedValue = value;
    notifyListeners();
  }
}
