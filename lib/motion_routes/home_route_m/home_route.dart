import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:motion/motion_routes/route_actions/route_action.dart';
import 'package:intl/intl.dart';

// home route
class MotionHomeRoute extends StatelessWidget {

  const MotionHomeRoute({super.key});


  // return current theme mode (dark or light theme)
  ThemeModeSettings currentSelectedThemeMode(BuildContext context) {
    final selectedTheme = Provider.of<AppThemeModeProvider>(context);
    return selectedTheme.currentThemeMode;
  }

  @override
  Widget build(BuildContext context) {
     // Get the current date
    DateTime currentMonth = DateTime.now();

// Get the month name using the intl package
    String currentMonthName = DateFormat.MMMM().format(currentMonth);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor:
              currentSelectedThemeMode(context) == ThemeModeSettings.darkMode
                  ? Colors.black
                  : Colors.white,
          actions: const [MotionActionButtons()],
          floating: true,
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            // title will be the current month data is being recorded for
            title: Text(
              currentMonthName,
              style: TextStyle(
                fontSize: 18,
                color: currentSelectedThemeMode(context) ==
                        ThemeModeSettings.darkMode
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            centerTitle: true,
            titlePadding: const EdgeInsets.only(top: 18),
            // profile picture and username
            background: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // user profile picture
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        AssetImage("assets/images/motion_icons/motion_pfp.jpg"),
                  ),
                  // UserName
                  Text(
                    "智也tomoya_hx",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
