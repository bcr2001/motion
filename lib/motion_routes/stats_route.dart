import 'package:flutter/material.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_themes/app_strings.dart';

// stats route
class MotionStatesRoute extends StatelessWidget {
  const MotionStatesRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
          AppString.statsRouteTitle,)
      ,actions: const [MainRoutePopUpMenu()],),

    );
  }
}
