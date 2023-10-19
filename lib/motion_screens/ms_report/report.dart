import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_screens/ms_report/report_reuse.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

//the data summary for the entire current month
class MonthlyReportPage extends StatelessWidget {
  const MonthlyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Consumer<CurrentMonthProvider>(
        builder: (context, month, child) {
          final currentMonth = month.currentMonthName;
          return Text("$currentMonth Report");
        },
      ),
    ), body: Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        FirstAndLastDay>(builder: (context, user, main, day, child) {
      final currentUser = user.userUid!;
      final firstDayofMonth = day.firstDay;
      final lastDayOfMonth = day.lastDay;

      return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          children: [
            // PIE CHART SECTION

            // Pie Chart Data Title
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text("Accounted vs Unaccounted"),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // the pie chart that shows the distribution between
                // accounted and unaccounted values
                const AccountedUnaccountedReportPieChart(),
                // accounted month total
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // accounted total for the current month
                    entireTimeAccountedAndUnaccounted(
                        future:
                            main.retrieveEntireMonthlyTotalMainCategoryTable(
                                currentUser,
                                firstDayofMonth,
                                lastDayOfMonth,
                                false),
                        resultName: "Accounted",
                        isUnaccounted: false),
            
                    // unaccounted total for the current month
                    entireTimeAccountedAndUnaccounted(
                        future:
                            main.retrieveEntireMonthlyTotalMainCategoryTable(
                                currentUser,
                                firstDayofMonth,
                                lastDayOfMonth,
                                true),
                        resultName: "Unaccounted",
                        isUnaccounted: true)
                  ],
                ),
              ],
              // TOP 3 ACTIVITIES SECTION
              
            ),
          ]);
    }));
  }
}

class MyPieChart extends StatelessWidget {
  const MyPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 100,
      child: PieChart(
          swapAnimationDuration: const Duration(milliseconds: 300),
          PieChartData(sections: [
            PieChartSectionData(value: 20, color: Colors.yellow),
            PieChartSectionData(value: 20, color: Colors.red),
            PieChartSectionData(value: 10, color: Colors.blue),
            PieChartSectionData(value: 30, color: Colors.green),
          ])),
    );
  }
}
