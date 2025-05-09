import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_main_home/main_home.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import 'app_direction.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1) Still waiting on Firebase auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.blueMainColor),
          );
        }

        // 2) Error signing in
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // 3) Signed in
        if (snapshot.hasData) {
          // a) Push the Firebase UID into your provider (once per frame)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<UserUidProvider>(context, listen: false)
                .setUserUid(snapshot.data!.uid);
          });

          // b) Now watch the provider — only navigate when userUid != null
          return Consumer<UserUidProvider>(
            builder: (context, userPvd, _) {
              if (userPvd.userUid == null) {
                // not set yet → show loader
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColor.blueMainColor),
                );
              }
              // userUid is set → go to your real home
              return const MainMotionHome();
            },
          );
        }

        // 4) Not signed in
        return const AppDirection();
      },
    );
  }
}
