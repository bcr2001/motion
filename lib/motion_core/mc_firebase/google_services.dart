import 'package:flutter/material.dart';
import "package:google_sign_in/google_sign_in.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion/main.dart';
import '../../motion_reusable/general_reuseable.dart';
import '../../motion_themes/mth_app/app_strings.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google and handle user authentication
  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    // Display a circular progress indicator during the sign-in process
    circularIndicator(context);

    try {
      // Initiate the interactive sign-in process with Google
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

      // Check if the user canceled the Google sign-in
      if (gUser == null) {
        debugLog("(signInWithGoogle): User canceled Google sign-in");
        return null;
      }

      // Obtain authentication details from the Google sign-in request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create a new credential for the user using Google's access and ID tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);

      // Sign in the user using Firebase authentication
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get the user's UID from the authentication result
      final User? userUid = authResult.user;
      debugLog("USER UID RETRIEVED:> ${userUid?.uid}");
      // Return the authentication result
      return authResult;
    } on FirebaseAuthException catch (e) {
      logger.e("(signInWithGoogle): FirebaseAuthException => ${e.code}");

      if (context.mounted) {
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseGoogleSignInError);
      }

      return null;
    } catch (e) {
      // Log and rethrow any errors that occur during the process
      logger.e("(signInWithGoogle): Error => $e");

      // Display an error message using a snack bar.
      if (context.mounted) {
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseGoogleSignInError);
      }

      return null;
    } finally {
      // Dispose of the circular progress indicator upon sign-in completion
      navigationKey.currentState?.pop();
    }
  }

  // Sign out the user from Google
  static Future<void> signOutGoogle([BuildContext? context]) async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      logger.e("(signOutGoogle): Error => $e");

      if (context != null && context.mounted) {
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseUnableToSignOut);
      }
    }
  }
}
