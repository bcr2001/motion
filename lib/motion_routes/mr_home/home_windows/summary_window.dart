import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';

// Where the summary for the month is displayed
// button toggles (Subcategory and Category)
// total time accounted for the current month
class SummaryWindow extends StatelessWidget {
  final bool isSubcatgory;

  const SummaryWindow({super.key, required this.isSubcatgory});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
            MainCategoryTrackerProvider>(
        builder: (context, user, day, main, child) {
      // currently logged in user
      final String currentUser = user.userUid!;

      // first and last day of the current month
      final String firstDayOfMonth = day.firstDay;
      final String lastDayOfMonth = day.lastDay;

      // if the total amount of time for the current
      // month is 0, then the summary page info
      // is displayed
      return FutureBuilder(
          future: main.retrieveEntireMonthlyTotalMainCategoryTable(
              currentUser, firstDayOfMonth, lastDayOfMonth, false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the data is loading, a shimmer effect is shown
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final snapshotData = snapshot.data;

              if (snapshotData! <= 0) {
                return const InfoToTheUser(
                    sectionInformation: AppString.infoAboutSummaryWindow);
              } else {
                return CardBuilder(
                  itemsToBeDisplayed: isSubcatgory
                      ? const SubcategoryMonthTotalsAndAverages(
                          isSubcategory: true)
                      : const SubcategoryMonthTotalsAndAverages(
                          isSubcategory: false),
                  timeAccountedAndOthers: null,
                  sizedBoxHeight: 0.37,
                );
              }
            }
          });
    });
  }
}
