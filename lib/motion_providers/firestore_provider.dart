import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/firestore_services.dart';

class FirestoreProvider extends ChangeNotifier {
  String _userName = "";
  String? _userPfpUrl;

  String get userName => _userName;
  String? get userPfpUrl => _userPfpUrl;

  StreamSubscription<User?>? _userChangesSubscription;

  FirestoreProvider() {
    fetchUserNamePfp();
  }

  Future<void> fetchUserNamePfp() async {
    // cancel any existing subscription before starting a new one
    await _userChangesSubscription?.cancel();

    _userChangesSubscription =
        FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        String userNameData =
            await FirestoreServices.getCurrentUserName(user.uid);

        String? userNamePfpUrl =
            await FirestoreServices.getUserProfile(user.uid);

        _userName = userNameData;
        _userPfpUrl = userNamePfpUrl;
      } else {
        _userName = "";
        _userPfpUrl = null;
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
