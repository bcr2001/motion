import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_routes/home_route.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'appDirection.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center(
              child: CircularProgressIndicator(
                color: blueMainColor,
              ),
            );
          }
           
          // error handling
          else if (snapshot.hasError) {
            return Text("error: ${snapshot.error}");
          }

          // user is signed in
          else if (snapshot.hasData) {
            return const MotionHomeRoute();
          }

          // user is not signed in
          else {
            return const AppDirection();
          }
        });
  }
}
