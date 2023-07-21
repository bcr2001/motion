import 'package:flutter/material.dart';
import 'package:motion/motion_user/sign_in_page.dart';
import 'package:motion/motion_user/sign_up_page.dart';


class AppDirection extends StatefulWidget {
  const AppDirection({super.key});

  @override
  State<AppDirection> createState() => _AppDirectionState();
}

class _AppDirectionState extends State<AppDirection> {
  // current screen
  bool isSignInPage = true;

  // toggle between sign in and sign up
  void togglePages() {
    setState(() {
      isSignInPage = !isSignInPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSignInPage) {
      return SignInPage(toSignUpPage: togglePages);
    } else {
      return SignUpPage(toSignInPage: togglePages);
    }
  }
}
