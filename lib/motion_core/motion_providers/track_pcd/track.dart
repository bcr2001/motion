import 'package:flutter/material.dart';

class DropDownTrackProvider extends ChangeNotifier {
  String? _selectedValue;

  String? get selectedValue => _selectedValue;

  void changeSelectedValue(String? value) {
    _selectedValue = value;
    notifyListeners();
  }
}
