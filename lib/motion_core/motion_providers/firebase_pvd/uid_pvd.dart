import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/auth_session_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class responsible for managing the user's UID and saving it to SharedPreferences.
class UserUidProvider extends ChangeNotifier {
  UserUidProvider({
    String? initialUserUid,
    bool isInitialized = false,
    AuthSessionSource? authSessionSource,
  })  : _userUid = initialUserUid,
        _isInitialized = isInitialized,
        _authSessionSource = authSessionSource;

  SharedPreferences? _pref;
  StreamSubscription<String?>? _authSubscription;
  bool _isInitialized;
  AuthSessionSource? _authSessionSource;

  AuthSessionSource get _sessionSource =>
      _authSessionSource ??= FirebaseAuthSessionSource();

  static const String uidKey = "uidKeys";

  // Initialize SharedPreferences for UID storage.
  Future<void> initializeUidSharedPreferences() async {
    if (_isInitialized) return;

    try {
      _pref ??= await SharedPreferences.getInstance();
      final sessionSource = _sessionSource;
      var authenticatedUid = sessionSource.currentUid;
      authenticatedUid ??= await sessionSource.recoverPreviousSession();
      authenticatedUid ??= sessionSource.currentUid;
      await _syncAuthenticatedUid(authenticatedUid);
      _authSubscription ??= sessionSource.uidChanges.listen(
        (uid) => unawaited(_syncAuthenticatedUid(uid)),
      );
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  String? _userUid;

  String? get userUid => _userUid;
  bool get isInitialized => _isInitialized;

  // Set the user's UID, save it to SharedPreferences, and notify listeners.
  Future<void> setUserUid(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    final changed = _userUid != normalizedUid;
    _userUid = normalizedUid;
    await _pref?.setString(uidKey, normalizedUid);
    if (changed) notifyListeners();
  }

  Future<void> clearUserUid() async {
    final changed = _userUid != null;
    _userUid = null;
    await _pref?.remove(uidKey);
    if (changed) notifyListeners();
  }

  // Check if user UID is saved in SharedPreferences
  Future<bool> isUserUidSaved() async {
    final savedUid = _pref?.getString(uidKey);
    return savedUid != null;
  }

  Future<void> _syncAuthenticatedUid(String? uid) async {
    if (uid == null || uid.trim().isEmpty) {
      await clearUserUid();
      return;
    }

    await setUserUid(uid);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
