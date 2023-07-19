import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motion/motion_reusable/reuseable.dart';

//handles the sign in and sign up of users
//adds user information to the firestore database

class AuthServices {
  // sign in users using email and password
  static signInUser(context,
      {required String userEmail, required userPassword}) async {
    //dialog displayed during sign-in process
    circularIndicator(context);

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userEmail, password: userPassword);

      // circularIndicator disposed upon sign-in completion
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // circularIndicator disposed upon sign-in error
      Navigator.pop(context);

      if (e.code == "user-not-found") {
        logger.e("no user in the system!");
      } else if (e.code == "wrong-password") {
        logger.e("Incorrect password");
      } else {
        logger.e("something went wrong during the sign in process");
      }
    }
  }

  // sign up users using email and password
  static signUpUser(
      {required String userEmailSignup,
      required String userPasswordSignUp,
      required String userName}) async {
    try {
      // create a new user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: userEmailSignup, password: userPasswordSignUp);

      String userId = userCredential.user!.uid;

      // add user info to firestore
      await _addUserSignUpDetail(
          uid: userId, userName: userName, userEmailAdress: userEmailSignup);
    } on FirebaseAuthException catch (e) {
      logger.e("something went wrong during the sign up process");
    }
  }

  // add user detail to firestore
  static Future<void> _addUserSignUpDetail(
      {required String uid,
      required String userName,
      required String userEmailAdress}) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .set({"user name": userName, "email": userEmailAdress});
  }

  // sign out user
  static void signOutUser(context) async {
    circularIndicator(context);

    try {
      await FirebaseAuth.instance.signOut();

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      logger.e("unable to sign out");
    }
  }
}

// handles reading and writing to firestore
class FirestoreService {}
