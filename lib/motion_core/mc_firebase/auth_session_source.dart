import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn motionGoogleSignIn = GoogleSignIn();

abstract interface class AuthSessionSource {
  String? get currentUid;

  Stream<String?> get uidChanges;

  Future<String?> recoverPreviousSession();
}

class FirebaseAuthSessionSource implements AuthSessionSource {
  FirebaseAuthSessionSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? motionGoogleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  @override
  Stream<String?> get uidChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid).distinct();

  @override
  Future<String?> recoverPreviousSession() async {
    final existingUid = currentUid;
    if (existingUid != null) return existingUid;

    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      return result.user?.uid;
    } catch (error) {
      debugPrint('Silent authentication recovery failed: $error');
      return null;
    }
  }
}
