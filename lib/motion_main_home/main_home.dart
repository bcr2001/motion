import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motion/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_routes/home_route.dart';
import 'package:motion/motion_routes/motion_route.dart';
import 'package:motion/motion_routes/stats_route.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Scaffold and Bottom App Bar routes
class MainMotionHome extends StatefulWidget {
  const MainMotionHome({super.key});

  @override
  State<MainMotionHome> createState() => _MotionHome();
}

class _MotionHome extends State<MainMotionHome> {
  // current page index
  int currentIndex = 0;

  // main app routes in the app
  List motionAppRoutes = const [
    MotionHomeRoute(),
    MotionStatesRoute(),
  ];

  // google nav bar button
  static const _navButtons = <GButton>[
    // home button
    GButton(
      icon: Icons.home_filled,
      text: "Home",
    ),

    // stats button
    GButton(
      icon: Icons.bubble_chart_outlined,
      text: "Stats",
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
        builder: (context, themeValue, child) {
      return Scaffold(
          // the app body of the current index
          body: motionAppRoutes[currentIndex],

          // centered Motion logo floating action button
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton.large(
                backgroundColor:
                    themeValue.currentThemeMode == ThemeModeSettings.lightMode
                        ? Colors.black
                        : Colors.white,
                elevation: 0,
                shape: const CircleBorder(),
                child:
                    themeValue.currentThemeMode == ThemeModeSettings.lightMode
                        ? SvgPicture.asset(
                            "assets/images/motion_icons/motion_logo_white.svg",
                            height: 30,
                            width: 30,
                          )
                        : SvgPicture.asset(
                            "assets/images/motion_icons/motion_logo.svg",
                            height: 30,
                            width: 30,
                          ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MotionTrackRoute()));
                },
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          // bottom navigation bar
          bottomNavigationBar: SafeArea(
              child: GNav(
            haptic: true,
            curve: Curves.linear,
            padding:const EdgeInsets.all(15),
            duration: const Duration(milliseconds: 700),
            gap: 10.0,
            tabMargin: const EdgeInsets.all(5),
            selectedIndex: currentIndex,
            tabs: _navButtons,
            onTabChange: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          )));
    });
  }
}
