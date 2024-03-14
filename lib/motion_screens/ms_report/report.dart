import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_windows/efficieny_window.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_screens/ms_report/report_heat_map.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
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
    return Scaffold(appBar: AppBar(
      // get the current month name from the
      // CurrentMonthProvider class
      title: Consumer<CurrentMonthProvider>(
        builder: (context, month, child) {
          final currentMonth = month.currentMonthName;
          return Text("$currentMonth ${AppString.reportTitle}");
        },
      ),
    ), body: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
        builder: (context, user, main, child) {
      // current user uid
      final String currentUser = user.userUid!;

      // depending on whether the accounted time is 0
      // or >0, a image will be shown of the screen to
      // indicate to the user that there is no data
      //  available and if data is available, then
      // the report for the current month will be displayed
      return FutureBuilder(
          future: main.retrieveEntireTotalMainCategoryTable(currentUser, false),
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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // default display image that is shown when the page is empty
                    AppImages.noAnalysisGallary,

                    // information on why it is empty
                    const InfoToTheUser(
                        sectionInformation:
                            AppString.infoAboutMonthlyReportEmpty)
                  ],
                );
              } else {
                return ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    children: [
                      // SECTION 0 (new): Current Month Efficiency Score
                      // gets the efficiency score of the current month
                      const EfficienyScoreSelectedYearOrMont(
                        getSelectedYearEfs: false,
                        selectedYear: '',
                      ),

                      // SECTION 1 (new): Contributions
                      // This section displays a heat map representing the
                      // distribution of accounted time intensities for the
                      // entire month.
                      // Each cell in the heat map corresponds to a day,
                      // and its color indicates the intensity of accounted time
                      // for that day.
                      // Users can visualize their activity patterns throughout
                      // the month using this heat map.
                      sectionTitle(titleName: AppString.contributionTitle),
                      const ContributionsHeatMap(),

                      // Most and Least Productive days
                      const MostAndLeastProductiveDayBuilder(
                        getMostProductiveDay: true,
                      ),
                      const MostAndLeastProductiveDayBuilder(
                          getMostProductiveDay: false),

                      // SECTION 3:
                      // Pie Chart Data Title
                      sectionTitle(
                          titleName: AppString.accountedVsUnaccounterTitle),
                      // pie chart for the accounted and unaccounted distribution
                      const PieChartAndValuesAccountedAndUnaccounted(),

                      // SECTION 2:
                      // MOST TRACKED AND LEAST TRACKED SECTION

                      // section title (Most and Least Tracked)
                      sectionTitle(
                          titleName: AppString.mostAndLeastTrackedTitle),

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
                      sectionTitle(
                          titleName: AppString.mainCategoryDistributionTitle),

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
                    ]);
              }
            }
          });
    }));
  }
}
