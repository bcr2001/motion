import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_screens/ms_report/report_dashboard.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:provider/provider.dart';
import '../../motion_themes/mth_app/app_strings.dart';

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
      body: Consumer3<UserUidProvider, SubcategoryTrackerDatabaseProvider,
          FirstAndLastDay>(builder: (context, user, sub, days, child) {
        // current user uid
        final currentUser = user.userUid;

        if (currentUser == null) {
          return const MonthlyReportLoadingSkeleton();
        }

        // depending on whether the accounted time is 0
        // or >0, a image will be shown of the screen to
        // indicate to the user that there is no data
        //  available and if data is available, then
        // the report for the current month will be displayed
        return FutureBuilder(
          future: sub.retrieveMonthTotalTimeSpent(
            currentUser,
            days.firstDay,
            days.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MonthlyReportLoadingSkeleton();
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  children: const [
                    MonthlySnapshotDashboard(),
                    MonthlyReportHeatMapPanel(),
                    MonthlyDailyXpTrendChart(),
                    MonthlyCategoryBreakdownBars(),
                    MonthlyTopSubcategorySection(),
                    MonthlyInsightCards(),
                    SizedBox(height: 18),
                  ],
                );
              }
            }
          });
      }),
    );
  }
}
