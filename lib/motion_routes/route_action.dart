import 'package:flutter/material.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_screens/settings_page.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:provider/provider.dart';

// // alert dialog for log out option in the pop up menu
showAlertDialog(BuildContext context) {
  // alert dialog width
  final double dialogWidth = MediaQuery.of(context).size.width * 0.9;

  // return the current theme mode text color
  Color themeModeColor(BuildContext context) {
    var themeModeColor = Provider.of<AppThemeModeProvider>(context);
    return themeModeColor.themeModeTextColor;
  }

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: const Text("Logout"),
          content: SizedBox(
            height: 150,
            width: dialogWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // divider
                const Padding(
                  padding: EdgeInsets.only(right: 22, left: 22),
                  child: Divider(),
                ),

                // log out query
                Padding(
                  padding: const EdgeInsets.only(right: 22.0, left: 22),
                  child: Text(
                    "Are you sure you want to log out?",
                    style: contentStyle(),
                  ),
                ),

                // options (cancel and log out)
                Padding(
                  padding: const EdgeInsets.only(right: 22, left: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      // sign out
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B0F0)),
                          onPressed: () {
                            Navigator.pop(context);
                            AuthServices.signOutUser(context);
                          },
                          child: Text("Sign Out",
                              style: contentStyle(color: Colors.white, fontSize: 15))),

                      // cancel
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel",
                              style:
                                  TextStyle(color: themeModeColor(context)))),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      });
}

// popup menu button
Widget mainRoutePopUpMenu(BuildContext context) {
  return PopupMenuButton(onSelected: (String value) {
    if (value == "logout") {
      showAlertDialog(context);
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SettingsPage()));
    }
  }, itemBuilder: (BuildContext context) {
    return [
      
      // settings
      const PopupMenuItem(value: "settings", child: Text("Settings")),
      
      // logout
      const PopupMenuItem(value: "logout", child: Text("Logout"))

    ];
  });
}

// app bar action button
class MotionActionButtons extends StatefulWidget {
  const MotionActionButtons({super.key});

  @override
  State<MotionActionButtons> createState() => _MotionAction();
}

class _MotionAction extends State<MotionActionButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // report
        IconButton(onPressed: () {}, icon: const Icon(Icons.bar_chart_rounded)),

        // popup menu button
        mainRoutePopUpMenu(context)
      ],
    );
  }
}
