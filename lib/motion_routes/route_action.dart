import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_settings/settings_page.dart';
import 'package:motion/motion_screens/ms_tips/tips_page.dart';
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

                // Custom widget for displaying two buttons: cancel and log out
                CancelAddTextButtons(
                  // Callback function when the "Cancel" button is pressed
                  onPressedFirst: () => Navigator.of(context).pop(),

                  // Callback function when the "Log Out" button is pressed
                  onPressedSecond: () {
                    Navigator.pop(context); // Close the dialog or screen
                    AuthServices.signOutUser(context); // Sign out the user
                    GoogleAuthService
                        .signOutGoogle(); // Sign out from Google (assuming it's a Google sign-in)
                  },

                  // Text displayed on the "Cancel" button
                  firstButtonName: AppString.cancelTitle,

                  // Text displayed on the "Log Out" button
                  secondButtonName: AppString.logOutTitle,
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

  // popup menu item builder
  PopupMenuItem _popUpItemBuilder(
      {required String itemName, required String value}) {
    return PopupMenuItem(
        value: value,
        child: Container(
          width: 100,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Text(itemName),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        padding: EdgeInsets.zero,
        color: Theme.of(context).popupMenuTheme.color,
        onSelected: (dynamic value) {
          // Change the parameter type to dynamic
          if (value == AppString.logOutValue) {
            showAlertDialog(context);
          } else if (value == AppString.tipsValue) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const TipsPage()));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            // Tips
            _popUpItemBuilder(
                value: AppString.tipsValue, itemName: AppString.tipsTitle),

            // settings
            _popUpItemBuilder(
                itemName: AppString.settingsTitle,
                value: AppString.settingsValue),

            // logout
            _popUpItemBuilder(
                itemName: AppString.logOutTitle, value: AppString.logOutValue)
          ];
        });
  }
}
