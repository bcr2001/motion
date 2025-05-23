import "package:google_sign_in/google_sign_in.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:provider/provider.dart';
import '../../motion_reusable/general_reuseable.dart';
import '../../motion_themes/mth_app/app_strings.dart';

class GoogleAuthService {
  // Sign in with Google and handle user authentication
  static Future<UserCredential> signInWithGoogle(context) async {
    // Display a circular progress indicator during the sign-in process
    circularIndicator(context);

    try {
      // Initiate the interactive sign-in process with Google
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // Check if the user canceled the Google sign-in
      if (gUser == null) {
        return Future.error("User canceled Google sign-in");
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
      if (userUid != null) {
        // Set the user's UID in the UserUidProvider using Provider
        final userUIdProviders =
            Provider.of<UserUidProvider>(context, listen: false);
        userUIdProviders.setUserUid(userUid.uid);
      }
      logger.i("USER UID RETRIEVED:> ${userUid?.uid}");
      // Return the authentication result
      return authResult;
    } catch (e) {
      // Log and rethrow any errors that occur during the process
      logger.e("(signInWithGoogle): Error => $e");

      // Display an error message using a snack bar.
      snackBarMessage(context,
          requiresColor: true,
          errorMessage: AppString.firebaseGoogleSignInError);

      rethrow;
    } finally {
      // Dispose of the circular progress indicator upon sign-in completion
      navigationKey.currentState!.pop();
    }
  }

  // Sign out the user from Google
  static Future<void> signOutGoogle() async {
    await GoogleSignIn().signOut();
  }
}
