import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_providers/firestore_pvd/firestore_provider.dart';
import 'package:motion/motion_screens/settings_page.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
import 'package:provider/provider.dart';

// app bar action button

class MotionActionButtons extends StatelessWidget {
  const MotionActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // report
        IconButton(onPressed: () {}, icon: const Icon(Icons.bar_chart_rounded)),

        // popup menu button
        const MainRoutePopUpMenu()
      ],
    );
  }
}

// // alert dialog for log out option in the pop up menu
showAlertDialog(BuildContext context) {
  // alert dialog width
  final double dialogWidth = MediaQuery.of(context).size.width * 0.9;

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppString.logOutTitle),
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
                const Padding(
                  padding:  EdgeInsets.only(right: 22.0, left: 22),
                  child:  Text(
                    AppString.logOutQuestion,
                  ),
                ),

                // options (cancel and log out)
                Padding(
                  padding: const EdgeInsets.only(right: 22, left: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // cancel
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: dialogGreyColor),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            AppString.cancelTitle,
                            style: contentStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 15),
                          )),

                      // sign out
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: blueMainColor),
                          onPressed: () {
                            Navigator.pop(context);
                            AuthServices.signOutUser(context);
                          },
                          child: Text(AppString.logOutTitle,
                              style: contentStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 15))),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      });
}

// pop up menu
class MainRoutePopUpMenu extends StatelessWidget {
  const MainRoutePopUpMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(onSelected: (String value) {
      if (value == AppString.logOutValue) {
        showAlertDialog(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      }
    }, itemBuilder: (BuildContext context) {
      return [
        // settings
        const PopupMenuItem(
            value: AppString.settingsValue,
            child: Text(AppString.settingsTitle)),

        // logout
        const PopupMenuItem(
            value: AppString.logOutValue, child: Text(AppString.logOutTitle))
      ];
    });
  }
}
