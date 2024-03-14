import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class responsible for managing the user's UID and saving it to SharedPreferences.
class UserUidProvider extends ChangeNotifier {
  SharedPreferences? _pref;

  static const String uidKey = "uidKeys";

  UserUidProvider() {
    initializeUidSharedPreferences();
  }

  // Initialize SharedPreferences for UID storage.
  Future<void> initializeUidSharedPreferences() async {
    _pref = await SharedPreferences.getInstance();
    _loadSavedUid();
  }

  String? _userUid;

  String? get userUid => _userUid;

  // Set the user's UID, save it to SharedPreferences, and notify listeners.
  void setUserUid(String uid) {
    _userUid = uid;

    _pref?.setString(uidKey, uid);

    notifyListeners();
  }

  // Load the saved UID from SharedPreferences.
  Future<void> _loadSavedUid() async {
    final savedUid = _pref?.getString(uidKey);
    if (savedUid != null) {
      _userUid = savedUid;
      notifyListeners();
    }
  }

  // Check if user UID is saved in SharedPreferences
  Future<bool> isUserUidSaved() async {
    final savedUid = _pref?.getString(uidKey);
    return savedUid != null;
  }
}
