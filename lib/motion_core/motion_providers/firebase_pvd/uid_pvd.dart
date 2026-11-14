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
  bool _isUsingOfflineFallback = false;
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
      final savedUid = _pref?.getString(uidKey)?.trim();
      final currentUid = sessionSource.currentUid;

      if (currentUid != null && currentUid.trim().isNotEmpty) {
        await setUserUid(currentUid);
      } else {
        final recovery = await sessionSource.recoverPreviousSession();
        final recoveredUid = sessionSource.currentUid ?? recovery.uid;

        if (recoveredUid != null && recoveredUid.trim().isNotEmpty) {
          await setUserUid(recoveredUid);
        } else if (recovery.status ==
                AuthSessionRecoveryStatus.temporarilyUnavailable &&
            savedUid != null &&
            savedUid.isNotEmpty) {
          await setUserUid(savedUid);
          _isUsingOfflineFallback = true;
        } else {
          await clearUserUid();
        }
      }

      _authSubscription ??= sessionSource.uidChanges.listen(
        (uid) => unawaited(_handleAuthenticationChange(uid)),
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

    _isUsingOfflineFallback = false;
    final changed = _userUid != normalizedUid;
    _userUid = normalizedUid;
    await _pref?.setString(uidKey, normalizedUid);
    if (changed) notifyListeners();
  }

  Future<void> clearUserUid() async {
    _isUsingOfflineFallback = false;
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

  Future<void> _handleAuthenticationChange(String? uid) async {
    if ((uid == null || uid.trim().isEmpty) &&
        _isUsingOfflineFallback &&
        _userUid != null) {
      return;
    }

    await _syncAuthenticatedUid(uid);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
