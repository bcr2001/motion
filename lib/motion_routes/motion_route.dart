import 'package:flutter/material.dart';
import 'package:motion/motion_themes/app_strings.dart';

class MotionTrackRoute extends StatelessWidget {
  const MotionTrackRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.motionRouteTitle),),
    );
  }
}
