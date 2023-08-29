import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

class UserUidProvider extends ChangeNotifier {
  String? _userUid;

  String? get userUid => _userUid;

  void setUserUid(String uid) {
    _userUid = uid;
    notifyListeners();
  }

  void clearUserUid() {
    _userUid = null;
    notifyListeners();
  }
}
