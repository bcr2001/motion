import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/firestore_services.dart';

class FirestoreProvider extends ChangeNotifier {
  String _userName = "";

  String get userName => _userName;

  StreamSubscription<User?>? _userChangesSubscription;

  FirestoreProvider() {
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    // cancel any existing subscription before starting a new one
    await _userChangesSubscription?.cancel();

    _userChangesSubscription =
        FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        String userNameData =
            await FirestoreServices.getCurrentUserName(user.uid);
            
        _userName = userNameData;
      } else {
        _userName = "";
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userChangesSubscription?.cancel();
    super.dispose();
  }
}
