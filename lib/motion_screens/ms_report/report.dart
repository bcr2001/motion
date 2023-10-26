import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:provider/provider.dart';
import '../../motion_routes/mr_home/home_reusable/back_home.dart';
import '../../motion_themes/mth_app/app_strings.dart';
import 'report_front.dart';

//the data summary for the entire current month
class MonthlyReportPage extends StatelessWidget {
  const MonthlyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Consumer<CurrentMonthProvider>(
            builder: (context, month, child) {
              final currentMonth = month.currentMonthName;
              return Text("$currentMonth Report");
            },
          ),
        ),
        body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            children: [
              // PIE CHART SECTION

              // Pie Chart Data Title
              sectionTitle(titleName: AppString.accountedVsUnaccounterTitle),

              const PieChartAndValues(),

              // MOST TRACKED AND LEAST TRACKED SECTION

              // section title
              sectionTitle(titleName: AppString.mostAndLeastTrackedTitle),

              // main category section 
              const MostAndLeastTrackedMaincategorySection(),

              // subcategory section

              // section information
              const InfoAboutSleep()
            ]));
  }
}
