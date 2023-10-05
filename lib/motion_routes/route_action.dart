import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/settings_page.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';

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
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialogConst(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          widthFactor: 0.78,
          heightFactor: 0.15,
          alertDialogTitle: AppString.logOutTitle,
          alertDialogContent: Padding(
            padding: const EdgeInsets.only(right: 18, left: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // divider
                const Divider(),

                // log out query
                const Text(
                  AppString.logOutQuestion,
                ),

                // options (cancel and log out)
                CancelAddTextButtons(
                    onPressedFirst: () => Navigator.of(context).pop(),
                    onPressedSecond: () {
                      Navigator.pop(context);
                      AuthServices.signOutUser(context);
                      GoogleAuthService.signOutGoogle();
                    },
                    firstButtonName: AppString.cancelTitle,
                    secondButtonName: AppString.logOutTitle),
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
    return PopupMenuButton(
        color: Theme.of(context).popupMenuTheme.color,
        onSelected: (String value) {
          if (value == AppString.logOutValue) {
            showAlertDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            // settings
            const PopupMenuItem(
                value: AppString.settingsValue,
                child: Text(AppString.settingsTitle)),

            // logout
            const PopupMenuItem(
                value: AppString.logOutValue,
                child: Text(AppString.logOutTitle))
          ];
        });
  }
}
