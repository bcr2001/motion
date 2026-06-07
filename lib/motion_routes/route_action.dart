import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_settings/settings_page.dart';
import 'package:motion/motion_screens/ms_tips/tips_page.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

import '../motion_screens/ms_report/report.dart';
import '../motion_themes/mth_app/app_images.dart';

// app bar action button
class MotionActionButtons extends StatelessWidget {
  const MotionActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // report gif
        GestureDetector(
          onTap: (){
            Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const MonthlyReportPage()));
          },
          child: AppImages.animatedBarChart),

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
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final borderColor =
      isDarkMode ? Colors.white.withValues(alpha: 0.16) : Colors.black12;
  final cancelTextColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialogConst(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          widthFactor: 0.78,
          heightFactor: 0.16,
          alertDialogTitle: AppString.logOutTitle,
          alertDialogContent: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppString.logOutQuestion,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 14,
                        fontweight: FontWeight.normal,
                        color: cancelTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cancelTextColor,
                        minimumSize: const Size(0, 44),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppString.cancelTitle,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12,
                          fontweight: FontWeight.w700,
                          color: cancelTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AuthServices.signOutUser(context);
                        GoogleAuthService.signOutGoogle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppString.logOutTitle,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12,
                          fontweight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
}

// pop up menu
class MainRoutePopUpMenu extends StatelessWidget {
  const MainRoutePopUpMenu({super.key});

  // popup menu item builder
  PopupMenuItem<String> _popUpItemBuilder({
    required BuildContext context,
    required String itemName,
    required String value,
    required IconData icon,
    required Color itemColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 158,
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 17,
                color: itemColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 13,
                  fontweight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        color: Theme.of(context).popupMenuTheme.color,
        elevation: 8,
        offset: const Offset(0, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: const Icon(Icons.more_vert_rounded),
        tooltip: "Menu",
        onSelected: (value) {
          // Change the parameter type to dynamic
          if (value == AppString.logOutValue) {
            showAlertDialog(context);
          } else if (value == AppString.tipsValue) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const FAQPage()));
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
              context: context,
              value: AppString.tipsValue,
              itemName: AppString.tipsTitle,
              icon: Icons.help_outline_rounded,
              itemColor: Colors.blueGrey,
            ),

            // settings
            _popUpItemBuilder(
              context: context,
              itemName: AppString.settingsTitle,
              value: AppString.settingsValue,
              icon: Icons.settings_outlined,
              itemColor: AppColor.blueMainColor,
            ),

            // logout
            _popUpItemBuilder(
              context: context,
              itemName: AppString.logOutTitle,
              value: AppString.logOutValue,
              icon: Icons.logout_rounded,
              itemColor: Colors.redAccent,
            )
          ];
        });
  }
}
