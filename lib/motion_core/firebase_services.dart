import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_reusable/reuseable.dart';

//handles the sign in and sign up of users
//adds user information to the firestore database

class AuthServices {
  // firebase auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // sign in users using email and password
  static signInUser(context,
      {required String userEmail, required userPassword}) async {
    // //dialog displayed during sign-in process
    circularIndicator(context);

    try {
      await _auth.signInWithEmailAndPassword(
          email: userEmail, password: userPassword);

      // circularIndicator disposed upon sign-in completion
    } on FirebaseAuthException catch (e) {
      // // circularIndicator disposed upon sign-in error

      if (e.code == "user-not-found") {
        logger.e("no user in the system!");
        // error message
        errorSnack(context, errorMessage: "User does not exist");
      } else if (e.code == "wrong-password") {
        logger.e("Incorrect password");
        errorSnack(context, errorMessage: "Incorrect password");
      } else {
        logger.e("something went wrong during the sign in process");
        errorSnack(context, errorMessage: "Something went wrong on our side:(");
      }
    } finally {
      navigationKey.currentState!.pop();
    }
  }

  // sign up users using email and password
  static signUpUser(context,
      {required String userEmailSignup,
      required String userPasswordSignUp,
      required String userName,
      required String imagePfpPath}) async {
    circularIndicator(context);

    try {
      // create a new user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: userEmailSignup, password: userPasswordSignUp);

      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;
        // add user info to firestore
        await _addUserSignUpDetail(
            uid: userId, userName: userName, userEmailAdress: userEmailSignup, userPfpPath: imagePfpPath);
      } else {
        logger.e("Something went wrong");
      }
    } on FirebaseAuthException catch (e) {
      logger.e("something went wrong during the sign up process $e");
    }finally {
      navigationKey.currentState!.pop();
    }
  }

  // add user detail to firestore
  static Future<void> _addUserSignUpDetail(
      {required String uid,
      required String userName,
      required String userEmailAdress,
      required String userPfpPath}) async {
    await _firestore
        .collection("users")
        .doc(uid)
        .set({"user name": userName, "email": userEmailAdress, "pfpPath": userPfpPath});
  }

  // sign out user
  static void signOutUser(context) async {
    circularIndicator(context);

    try {
      await _auth.signOut();

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      logger.e("unable to sign out $e");
    }
  }
}
