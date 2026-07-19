import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_main_home/main_home.dart';
import 'package:provider/provider.dart';

import 'app_direction.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserUidProvider>(
      builder: (context, user, child) {
        if (!user.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return user.userUid == null
            ? const AppDirection()
            : const MainMotionHome();
      },
    );
  }
}
