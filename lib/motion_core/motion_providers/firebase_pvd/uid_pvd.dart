import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserUidProvider extends ChangeNotifier {
  SharedPreferences? _pref;

  static const String uidKey = "uidKeys";

  UserUidProvider() {
    initializeUidSharedPreferences();
  }

  Future<void> initializeUidSharedPreferences() async {
    _pref = await SharedPreferences.getInstance();
    _loadSavedUid();
  }

  String? _userUid;

  String? get userUid => _userUid;

  void setUserUid(String uid) {
    _userUid = uid;

    _pref?.setString(uidKey, uid);

    notifyListeners();
  }

  Future<void> _loadSavedUid() async {
    final savedUid = _pref?.getString(uidKey);
    if (savedUid != null) {
      _userUid = savedUid;
      notifyListeners();
    }
  }
}
