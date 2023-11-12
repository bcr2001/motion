import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_routes/mr_stats/stats_sections.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';

// the summary report of the year the user clicks on
class YearsWorthOfSummaryStatitics extends StatelessWidget {
  final String year;
  final String accountedDays;
  final String accountedHours;
  final String unaccountedDays;
  final String unaccountedHours;

  const YearsWorthOfSummaryStatitics(
      {super.key,
      required this.year,
      required this.accountedDays,
      required this.accountedHours,
      required this.unaccountedDays,
      required this.unaccountedHours});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(year),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        children: [
          // SECTION 1: ACCOUNTED VS UNACCOUNTED
          // Accounted vs Unaccounted
          sectionTitle(titleName: AppString.accountedVsUnaccounterTitle),

          Card(
            child: Column(
              children: [
                // total accounted and unaccounted totals
                // displays the total hours and days accounted
                // and unaccounted for the entire year
                YearTotalsAccountedUnaccountedBuilder(
                    accountedDays: accountedDays,
                    accountedHours: accountedHours,
                    unaccountedDays: unaccountedDays,
                    unaccountedHours: unaccountedHours),

                    
                // a pie chart showing the distibution of
                // accounted and unaccounted totals for that
                // year
                YearPieChartDistributionAccountedUnaccounted(
                    accountedTotalHours: accountedHours,
                    unAccountedTotalHours: unaccountedHours),
              ],
            ),
          ),

          // grouped bar chart distibution for accounted and
          // unaccounted data
          AppImages.chartNoData,

          // SECTION 2: ACCOUNTED OVERVIEW
          sectionTitle(titleName: AppString.mainCategoryOverview),

          // an overview of how much time was spent on 
          // each main category through out the year
          YearMainCategoryOveriew(year: year,),

          // SECTION 3: A YEAR IN SLICES
          sectionTitle(titleName: AppString.aYearInSlicesTitle),
          // a pie chart that shows the distribution of main
          // category elements
          AYearInSummaryPieChartDistribution(year: year,),


          // SECTION 4: HIGHEST TRACKED TIME PER SUBCATEGORY

          // section title
          specialSectionTitle(mainTitleName: AppString.highestTrackedTimeTitleMain, elevatedTitleName: AppString.highestTrackedTimeTitleSpecial),
          // information to the user regarding this section
          const InfoToTheUser(sectionInformation: AppString.infoAboutHighestTimeTracked),



          YearHighestTrackedTimePerSubcategory(year: year,)

        ],
      ),
    );
  }
}
