import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn motionGoogleSignIn = GoogleSignIn();

abstract interface class AuthSessionSource {
  String? get currentUid;

  Stream<String?> get uidChanges;

  Future<AuthSessionRecoveryResult> recoverPreviousSession();
}

enum AuthSessionRecoveryStatus {
  recovered,
  noSession,
  temporarilyUnavailable,
}

@immutable
class AuthSessionRecoveryResult {
  const AuthSessionRecoveryResult._(this.status, this.uid);

  const AuthSessionRecoveryResult.recovered(String uid)
      : this._(AuthSessionRecoveryStatus.recovered, uid);

  const AuthSessionRecoveryResult.noSession()
      : this._(AuthSessionRecoveryStatus.noSession, null);

  const AuthSessionRecoveryResult.temporarilyUnavailable()
      : this._(AuthSessionRecoveryStatus.temporarilyUnavailable, null);

  final AuthSessionRecoveryStatus status;
  final String? uid;
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
  Future<AuthSessionRecoveryResult> recoverPreviousSession() async {
    final existingUid = currentUid;
    if (existingUid != null) {
      return AuthSessionRecoveryResult.recovered(existingUid);
    }

    try {
      // Do not suppress errors here. A network failure must remain distinct
      // from a confirmed absence of a previously selected Google account.
      final googleUser =
          await _googleSignIn.signInSilently(suppressErrors: false);
      if (googleUser == null) {
        return const AuthSessionRecoveryResult.noSession();
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        return const AuthSessionRecoveryResult.noSession();
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      final uid = result.user?.uid;
      return uid == null
          ? const AuthSessionRecoveryResult.noSession()
          : AuthSessionRecoveryResult.recovered(uid);
    } on FirebaseAuthException catch (error) {
      debugPrint('Silent authentication recovery failed: $error');
      if (_isTerminalAuthenticationError(error.code)) {
        return const AuthSessionRecoveryResult.noSession();
      }
      return const AuthSessionRecoveryResult.temporarilyUnavailable();
    } catch (error) {
      debugPrint('Silent authentication recovery failed: $error');
      return const AuthSessionRecoveryResult.temporarilyUnavailable();
    }
  }

  bool _isTerminalAuthenticationError(String code) {
    return const {
      'invalid-credential',
      'invalid-user-token',
      'user-disabled',
      'user-not-found',
      'user-token-expired',
    }.contains(code);
  }
}
