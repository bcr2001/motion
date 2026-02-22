import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:provider/provider.dart';
import '../../motion_themes/mth_app/app_strings.dart';

// This class handles the sign-in, sign-up, and sign-out of users.
// It also adds user information to the Firestore database when needed
class AuthServices {
  // firebase auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // sign in users using email and password
  static Future<void> signInUser(context,
      {required String userEmail, required userPassword}) async {
    // Display a circular loading indicator during sign-in.
    circularIndicator(context);

    try {
      // Attempt to sign in with the provided email and password.
      await _auth.signInWithEmailAndPassword(
          email: userEmail, password: userPassword);

      // If sign-in is successful and a user is authenticated.
      if (_auth.currentUser != null) {
        final userUidProvider =
            Provider.of<UserUidProvider>(context, listen: false);

        // Check if user UID is saved in SharedPreferences
        while (!(await userUidProvider.isUserUidSaved())) {
          // Keep displaying the circular progress indicator until user UID is saved
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Set the user's UID in the UserUidProvider.
        userUidProvider.setUserUid(_auth.currentUser!.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        // Handle the case where the user does not exist.
        logger.e("(signInUser): no user in the system!");

        // Display an error message using a snack bar.
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseUserNotFoundError);
      } else if (e.code == "wrong-password") {
        // Handle the case of an incorrect password.

        logger.e("(signInUser): Incorrect password");

        // Display an error message using a snack bar.
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseIncorrectPassword);
      } else {
        // Handle other FirebaseAuth exceptions.
        logger
            .e("(signInUser): something went wrong during the sign in process");

        // Display an error message using a snack bar.
        snackBarMessage(context,
            requiresColor: true,
            errorMessage: AppString.firebaseSomethingWentWrong);
      }
    } finally {
      // Dispose of the circular loading indicator upon sign-in completion.
      navigationKey.currentState!.pop();
    }
  }

  // sign up users using email and password
  static signUpUser(context,
      {required String userEmailSignup,
      required String userPasswordSignUp}) async {
    // Display a circular loading indicator during sign-up.
    circularIndicator(context);

    try {
      // Attempt to create a new user account with the provided email and password.
      await _auth.createUserWithEmailAndPassword(
          email: userEmailSignup, password: userPasswordSignUp);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        // Handle the case where the email is already in use.
        logger.e(
            "(signUpUser): something went wrong during the sign up process $e");
        // Display an error message using a snack bar.
        snackBarMessage(context,
            requiresColor: true, errorMessage: AppString.firebaseEmailInUse);
      }
    } finally {
      // Dispose of the circular loading indicator upon sign-up completion.
      navigationKey.currentState!.pop();
    }
  }

  // sign out user
  static void signOutUser(context) async {
    // Dispose of the circular loading indicator upon sign-up completion.
    circularIndicator(context);

    try {
      // Sign the user out.
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      // Handle errors during sign-out.

      logger.e("(signOutUser): unable to sign out $e");

      // Display an error message using a snack bar.
      snackBarMessage(context,
          requiresColor: true, errorMessage: AppString.firebaseUnableToSignOut);
    } finally {
      // Dispose of the circular loading indicator upon sign-out completion.
      navigationKey.currentState!.pop();
    }
  }
}
