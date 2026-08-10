import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_core/motion_providers/ai_pvd/daily_forecast_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_ai/ai_forecast_page.dart';
import 'package:motion/motion_screens/ms_awards/awards_page.dart';
import 'package:motion/motion_screens/ms_settings/settings_page.dart';
import 'package:motion/motion_screens/ms_tips/tips_page.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

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
        const _AiForecastAction(),

        // report gif
        Tooltip(
          message: 'Monthly Report',
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const MonthlyReportPage()));
              },
              child: AppImages.animatedBarChart),
        ),

        // popup menu button
        const MainRoutePopUpMenu()
      ],
    );
  }
}

class _AiForecastAction extends StatefulWidget {
  const _AiForecastAction();

  @override
  State<_AiForecastAction> createState() => _AiForecastActionState();
}

class _AiForecastActionState extends State<_AiForecastAction> {
  String? _scheduledRequestKey;

  void _scheduleRefresh({
    required String currentUser,
    required String currentDate,
    required String currentYear,
    required int revision,
  }) {
    final requestKey = '$currentUser|$currentDate|$currentYear|$revision';
    if (_scheduledRequestKey == requestKey) return;
    _scheduledRequestKey = requestKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DailyForecastProvider>().refresh(
            currentUser: currentUser,
            currentDate: currentDate,
            currentYear: currentYear,
            experienceRevision: revision,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserUidProvider>().userUid;
    final currentDate = context.watch<CurrentDateProvider>().currentDate;
    final currentYear = context.watch<CurrentYearProvider>().currentYear;
    final revision = context.watch<ExperiencePointTableProvider>().refreshKey;
    final forecastProvider = context.watch<DailyForecastProvider>();
    if (currentUser != null) {
      _scheduleRefresh(
        currentUser: currentUser,
        currentDate: currentDate,
        currentYear: currentYear,
        revision: revision,
      );
    }
    final showUnread = currentUser != null &&
        forecastProvider.isUnreadFor(
          currentUser: currentUser,
          currentDate: currentDate,
        );
    final foregroundColor = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).iconTheme.color;

    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Tooltip(
        message: 'AI Forecast',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiForecastPage()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
                minimumSize: const Size(44, 42),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'AI',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 15,
                  fontweight: FontWeight.w900,
                  color: foregroundColor,
                ),
              ),
            ),
            if (showUnread)
              Positioned(
                top: 2,
                right: 1,
                child: Semantics(
                  label: 'New AI forecast available',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      builder: (BuildContext dialogContext) {
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await AuthServices.signOutUser(context);
                        if (!context.mounted) return;
                        await GoogleAuthService.signOutGoogle(context);
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
          } else if (value == AppString.awardsValue) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const AwardsPage(),
              ),
            );
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
            // Awards
            _popUpItemBuilder(
              context: context,
              value: AppString.awardsValue,
              itemName: AppString.awardsTitle,
              icon: Icons.emoji_events_outlined,
              itemColor: Colors.amber.shade700,
            ),

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
