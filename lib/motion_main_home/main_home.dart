import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_routes/mr_home/homa_main/home_route.dart';
import 'package:motion/motion_routes/mr_track/track_main/track_route.dart';
import 'package:motion/motion_routes/mr_stats/stats_route.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../motion_themes/mth_app/app_strings.dart';
import '../motion_themes/mth_styling/motion_text_styling.dart';

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

  // Helper function to build Google Nav Bar buttons
  GButton gButtonBuilder(BuildContext context,{
    required IconData gIcon, 
    required String gText}) {
    return GButton(
        icon: gIcon,
        text: gText,
        textStyle: AppTextStyle.navigationTextLTStyle(),
        iconSize: 20,
        iconColor: Theme.of(context).iconTheme.color);
  }

  // google nav bar button
  // Helper function to build Google Nav Bar buttons
  List<GButton> _navButtons(BuildContext context) {
    return <GButton>[
      // home button
      gButtonBuilder(
        context, 
        gIcon: Icons.home_filled, 
        gText: AppString.homeNavigation),

      // stats button
      gButtonBuilder(
        context, 
        gIcon: Icons.bubble_chart_outlined, 
        gText: AppString.statsNavigation),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProviderN1>(
        builder: (context, themeValue, child) {
      return Scaffold(
          // the app body of the current index
          body: Stack(
            children: [
              motionAppRoutes[currentIndex],

            Positioned(
              bottom: 0,
                left: 0,
                right: 0,
              child: SafeArea(
            child: GNav(
            backgroundColor:  themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
            haptic: true,
            curve: Curves.linear,
            padding:const EdgeInsets.all(8),
            duration: const Duration(milliseconds: 500),
            gap: 10.0,
            tabMargin: const EdgeInsets.all(5),
            selectedIndex: currentIndex,
            tabs: _navButtons(context),
            onTabChange: (index) {
              setState(() {
                currentIndex = index;
              });
            },
                    )))

              
            ],
          ),

          // centered Motion logo floating action button
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton.large(
                backgroundColor:
                    themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                        ? Colors.black
                        : Colors.white,
                elevation: 0,
                shape: const CircleBorder(),
                child:
                    // different svg images depending on the theme mode 
                    // (dark/light)
                    themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
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
                  // navigates to the Track route where users can create and
                  // assign subcategories to their respective main categories
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

          );
    });
  }
}
