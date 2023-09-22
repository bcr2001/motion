import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:provider/provider.dart';

//handles the sign in and sign up of users
//adds user information to the firestore database

class AuthServices {
  // firebase auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // sign in users using email and password
  static Future<void> signInUser(context,
      {required String userEmail, required userPassword}) async {
    // //dialog displayed during sign-in process
    circularIndicator(context);

    try {
      await _auth.signInWithEmailAndPassword(
          email: userEmail, password: userPassword);

      if (_auth.currentUser != null) {
        final userUidProvider =
            Provider.of<UserUidProvider>(context, listen: false);
        userUidProvider.setUserUid(_auth.currentUser!.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        logger.e("no user in the system!");
        // error message
        errorSnack(context, errorMessage: "User does not exist");
      } else if (e.code == "wrong-password") {
        logger.e("Incorrect password");
        errorSnack(context, errorMessage: "Incorrect password");
      } else {
        logger.e("something went wrong during the sign in process");
        errorSnack(context,
            errorMessage: "Something went wrong on our side:( ");
      }
    } finally {
      // circularIndicator disposed upon sign-in completion
      navigationKey.currentState!.pop();
    }
  }

  // sign up users using email and password
  static signUpUser(context,
      {required String userEmailSignup,
      required String userPasswordSignUp}) async {
    circularIndicator(context);

    try {
      await _auth.createUserWithEmailAndPassword(
          email: userEmailSignup, password: userPasswordSignUp);


    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        logger.e("something went wrong during the sign up process $e");
        errorSnack(context,
            errorMessage: "The email you provided is already in use");
      }
    } finally {
      navigationKey.currentState!.pop();
    }
  }
  // sign out user
  static void signOutUser(context) async {
    circularIndicator(context);

    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      logger.e("unable to sign out $e");
      errorSnack(context, errorMessage: "Unable to sign out");
    } finally {
      navigationKey.currentState!.pop();
    }
  }
}
