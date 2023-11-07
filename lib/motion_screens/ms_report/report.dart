import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
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
              // Pie Chart Data Title
              sectionTitle(titleName: AppString.accountedVsUnaccounterTitle),
              // pie chart for the accounted and unaccounted distribution
              const PieChartAndValuesAccountedAndUnaccounted(),

              // Week distribution of accounted and unaccounted
              const GroupedBarChartOfAccountedAndUnaccountedTime(),


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

              // Pie chart for the main category
              //distribution for the current month
              sectionTitle(titleName: AppString.mainCategoryDistributionTitle),

              const PieChartDataMainCategoryDistribution(),

              // Highest Tracked time per subcategory section
              sectionTitle(titleName: AppString.highestTrackedTimeTitle),
              // information about this section
              const InfoAboutHightesTrackedTime(),

              const GridHighestTrackedSubcategory()

            ]));
  }
}