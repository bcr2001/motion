import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/firestore_services.dart';

class FirestoreProvider extends ChangeNotifier {
  String _userName = "";
  late StreamSubscription<User?> _userChangesSubscription;

  String get userName => _userName;

  FirestoreProvider() {
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    _userChangesSubscription =
        FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        String userNameData =
            await FirestoreServices.getCurrentUserName(user.uid);

        _userName = userNameData;

        notifyListeners();
      } else {
        _userName = "";
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userChangesSubscription.cancel();
    super.dispose();
  }
}
