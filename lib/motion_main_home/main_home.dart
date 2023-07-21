import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_routes/home_route.dart';
import 'package:motion/motion_routes/motion_route.dart';
import 'package:motion/motion_routes/stats_route.dart';
import 'package:provider/provider.dart';


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

  // get appropriate colors for bottom app bar element
  Color getIconAndTextColor(BuildContext context, int navIndex) {
    final themeValue = Provider.of<AppThemeModeProvider>(context);
    final themeMode = themeValue.currentThemeMode;

    if (themeMode == ThemeModeSettings.lightMode) {
      return navIndex == currentIndex ? const Color(0xFF00B0F0) : Colors.black;
    } else {
      return navIndex == currentIndex ? const Color(0xFF00B0F0) : Colors.white;
    }
  }

  // bottom appbar builder
  Widget _buildNavButton({
    required int navIndex,
    required Widget navIconImage,
    required Text navName,
  }) {
    final iconAndTextColor = getIconAndTextColor(context, navIndex);

    // icon and name for the bottom nav bar elements
    return ElevatedButton(
        style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor: MaterialStateProperty.all(Colors.transparent)),
        onPressed: () {
          setState(() {
            currentIndex = navIndex;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                iconAndTextColor,
                BlendMode.srcIn,
              ),
              child: navIconImage,
            ),
            Text(
              navName.data!,
              style: TextStyle(color: iconAndTextColor),
            ),
          ],
        ));
  }

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
              child: themeValue.currentThemeMode == ThemeModeSettings.lightMode
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // bottom navigation bar
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          height: 68,
          notchMargin: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // home
              _buildNavButton(
                  navIndex: 0,
                  navIconImage: Image.asset(
                    "assets/images/motion_icons/home_route.png",
                    fit: BoxFit.contain,
                    height: 24,
                    width: 24,
                  ),
                  navName: const Text(
                    "Home",
                  )),

              // stats
              _buildNavButton(
                  navIndex: 1,
                  navIconImage: const Icon(
                    Icons.bubble_chart_outlined,
                  ),
                  navName: const Text(
                    "Stats",
                  )),
            ],
          ),
        ),
      );
    });
  }
}
