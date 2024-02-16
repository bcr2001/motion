import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../home_reusable/front_home.dart';

// accounted and unaccounted total for the entire main_category table
// second section of the home page
class TotalAccountedAndUnaccounted extends StatelessWidget {
  final bool getEntireTotal;
  const TotalAccountedAndUnaccounted({super.key, required this.getEntireTotal});

  // this function handles the creation of the widget where the accounted
  // and unaccounted totals will be displayed
  Widget _totalsDisplay({required List<Widget> displayContent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayContent ,
        ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        CurrentYearProvider>(
      builder: (context, user, main, year, child) {
        final currentUser = user.userUid;

        return getEntireTotal
            ? _totalsDisplay(displayContent: [
                  // Accounted total
                  entireTimeAccountedAndUnaccounted(
                      future: main.retrieveEntireTotalMainCategoryTable(
                          currentUser!, false),
                      resultName: AppString.accountedTitle,
                      dayStyle: AppTextStyle.resultTitleStyleHome(false),
                      hoursStyle:
                          AppTextStyle.accountRegularAndUnaccountTextStyle()),

                  // Unaccounted total
                  entireTimeAccountedAndUnaccounted(
                      future: main.retrieveEntireTotalMainCategoryTable(
                          currentUser, true),
                      resultName: AppString.unAccountedTitle,
                      dayStyle: AppTextStyle.resultTitleStyleHome(true),
                      hoursStyle:
                          AppTextStyle.accountRegularAndUnaccountTextStyle())
                ],
              )
            : _totalsDisplay(displayContent: [
                // Accounted total
                entireTimeAccountedAndUnaccounted(
                    future: main.retrieveGetEntireYearTotalMainCategoryTable(
                        currentUser!, false, year.currentYear),
                    resultName: AppString.accountedTitle,
                    dayStyle: AppTextStyle.resultTitleStyleHome(false),
                    hoursStyle:
                        AppTextStyle.accountRegularAndUnaccountTextStyle()),

                // Unaccounted total
                entireTimeAccountedAndUnaccounted(
                    future: main.retrieveGetEntireYearTotalMainCategoryTable(
                        currentUser, true, year.currentYear),
                    resultName: AppString.unAccountedTitle,
                    dayStyle: AppTextStyle.resultTitleStyleHome(true),
                    hoursStyle:
                        AppTextStyle.accountRegularAndUnaccountTextStyle())
              ]);
      },
    );
  }
}
