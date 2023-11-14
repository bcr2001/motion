import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:provider/provider.dart';
import '../../motion_routes/mr_home/home_reusable/back_home.dart';
import '../../motion_themes/mth_app/app_strings.dart';
import 'report_front.dart';

// the data summary for the entire current month
// this page contains, charts and summary information
// related to the current month
class MonthlyReportPage extends StatelessWidget {
  const MonthlyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // get the current month name from the
          // CurrentMonthProvider class
          title: Consumer<CurrentMonthProvider>(
            builder: (context, month, child) {
              final currentMonth = month.currentMonthName;
              return Text("$currentMonth ${AppString.reportTitle}");
            },
          ),
        ),
        body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            children: [
              // SECTION 1:
              // Pie Chart Data Title
              sectionTitle(titleName: AppString.accountedVsUnaccounterTitle),
              // pie chart for the accounted and unaccounted distribution
              const PieChartAndValuesAccountedAndUnaccounted(),


              // SECTION 2:
              // MOST TRACKED AND LEAST TRACKED SECTION

              // section title (Most and Least Tracked)
              sectionTitle(titleName: AppString.mostAndLeastTrackedTitle),

              // main category section
              // the summary of the most tracked and least tracked
              // main categories
              const MostAndLeastTrackedMaincategorySection(),

              // section information
              // info about why the sleep category is not included in the
              // most and least tracked
              const InfoAboutSleep(),

              // subcategory section
              // the summary of the most tracked and least tracked
              // main categories
              const MostAndLeastTrackedSubcategorySection(),

              // SECTION 3:
              // Pie chart for the main category
              //distribution for the current month
              sectionTitle(titleName: AppString.mainCategoryDistributionTitle),

              Consumer3<UserUidProvider, FirstAndLastDay,
                      MainCategoryTrackerProvider>(
                  builder: (context, user, day, main, child) {
                // user uid
                final String currentUser = user.userUid!;
                return PieChartDataMainCategoryDistribution(
                  future: main.retrieveMainTotalTimeSpentSpecificDates(
                      currentUser: currentUser,
                      firstDay: day.firstDay,
                      lastDay: day.lastDay),
                );
              }),

              // SECTION 4:
              // Highest Tracked time per subcategory section
              specialSectionTitle(
                mainTitleName: AppString.highestTrackedTimeTitleMain,
                elevatedTitleName: AppString.highestTrackedTimeTitleSpecial,
              ),
              // information about this section
              const InfoAboutHightesTrackedTime(),

              Consumer3<FirstAndLastDay, UserUidProvider,
                      SubcategoryTrackerDatabaseProvider>(
                  builder: (context, day, user, sub, child) {
                // current logged in user
                final String currentUserUid = user.userUid!;

                logger.i(day.firstDay);
                logger.i(day.lastDay);

                return GridHighestTrackedSubcategory(
                  future: sub.retrieveHighestTrackedTimePerSubcategory(
                      currentUser: currentUserUid,
                      firstDay: day.firstDay,
                      lastDay: day.lastDay),
                );
              })
            ]));
  }
}
