import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class responsible for managing the user's UID and saving it to SharedPreferences.
class UserUidProvider extends ChangeNotifier {
  SharedPreferences? _pref;
  StreamSubscription<User?>? _authSubscription;

  static const String uidKey = "uidKeys";

  // Initialize SharedPreferences for UID storage.
  Future<void> initializeUidSharedPreferences() async {
    if (_pref != null) return;

    _pref = await SharedPreferences.getInstance();
    await _loadSavedUid();
    await _syncFirebaseUser(FirebaseAuth.instance.currentUser);
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_syncFirebaseUser);
  }

  String? _userUid;

  String? get userUid => _userUid;

  // Set the user's UID, save it to SharedPreferences, and notify listeners.
  void setUserUid(String uid) {
    if (_userUid == uid) return;

    _userUid = uid;

    _pref?.setString(uidKey, uid);

    notifyListeners();
  }

  Future<void> clearUserUid() async {
    if (_userUid == null) return;

    _userUid = null;
    await _pref?.remove(uidKey);
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

  Future<void> _syncFirebaseUser(User? user) async {
    if (user == null) {
      await clearUserUid();
      return;
    }

    setUserUid(user.uid);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
