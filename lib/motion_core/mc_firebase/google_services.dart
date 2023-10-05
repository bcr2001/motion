import "package:google_sign_in/google_sign_in.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:provider/provider.dart';
import '../../motion_reusable/general_reuseable.dart';

class GoogleAuthService {
  static Future<UserCredential> signInWithGoodle(context) async {
    // dialog displayed during sign-in process
    circularIndicator(context);

    try {
      // begin interractive sign in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser!.authentication;

      // create a new credential for user
      final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);

      // Sign in user
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // get the user UID
      final User? userUid = authResult.user;
      if (userUid != null) {
        final userUIdProviders =
            Provider.of<UserUidProvider>(context, listen: false);
        userUIdProviders.setUserUid(userUid.uid);
      }

      // sign in user
      return authResult;
    } catch (e) {
      logger.e("Error: $e");
      rethrow;
    } finally {
      // circularIndicator disposed upon sign-in completion
      navigationKey.currentState!.pop();
    }
  }

  static Future<void> signOutGoogle() async {
    await GoogleSignIn().signOut();
  }

}
