import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_stats/stats_graphs.dart';
import 'package:motion/motion_routes/mr_stats/stats_sections.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

import '../mr_home/home_reusable/back_home.dart';
import '../mr_home/home_windows/efficieny_window.dart';

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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        children: [
          // SECTION 0(new): Efficiency Score
          // This section displays the efficieny score for the
          // selected year
          EfficienyScoreSelectedYearOrMont(selectedYear: year, getSelectedYearEfs: true,),

          // SECTION 1(new): Contributions
          // This section displays to the user a HeatMap
          // showing entire years contibutions to time
          // they have accounted for
          sectionTitle(titleName: AppString.contributionTitle),
          SummaryContributionHeatMap(year: int.parse(year)),

          // SECTION 1: ACCOUNTED VS UNACCOUNTED
          // Accounted vs Unaccounted
          sectionTitle(titleName: AppString.accountedVsUnaccounterTitle),

          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Card(
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

                  // accounted and unaccounted grouped bar chart distribution
                  GroupedPieChartAccountedUnaccounted(
                    year: year,
                  )
                ],
              ),
            ),
          ),

          // SECTION 2: ACCOUNTED OVERVIEW
          sectionTitle(titleName: AppString.mainCategoryOverview),

          // an overview of how much time was spent on
          // each main category through out the year
          YearMainCategoryOveriew(
            year: year,
          ),

          // SECTION 3: A YEAR IN SLICES
          sectionTitle(titleName: AppString.aYearInSlicesTitle),
          // a pie chart that shows the distribution of main
          // category elements
          AYearInSummaryPieChartDistribution(
            year: year,
          ),

          // SECTION 4: HIGHEST TRACKED TIME PER SUBCATEGORY

          // section title
          specialSectionTitle(
              mainTitleName: AppString.highestTrackedTimeTitleMain,
              elevatedTitleName: AppString.highestTrackedTimeTitleSpecial),
          // information to the user regarding this section
          const InfoToTheUser(
              sectionInformation: AppString.infoAboutHighestTimeTracked),

          YearHighestTrackedTimePerSubcategory(
            year: year,
          ),

          // SECTION 5: CHARTING A YEAR IN LINES

          // section title: Charting a Year in Lines
          sectionTitle(titleName: AppString.chartingAYearInLinesTitle),
          LineChartOfMainCategoryYearlyDistribution(
            year: year,
          ),

          // SECTION 6: STACKED BAR CHART
          sectionTitle(titleName: AppString.stackingAYearInLinesTitle),
          Card(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon and data
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 15, bottom: 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    makeTransactionsIcon(),
                    const SizedBox(
                      width: 15,
                    ),
                    specialSectionTitle(
                        mainTitleName: AppString.stackingATitle,
                        elevatedTitleName: AppString.statusUpTitle),
                  ],
                ),
              ),

              // info to the user
              const Padding(
                padding: EdgeInsets.only(bottom: 15.0),
                child: InfoToTheUser(
                    sectionInformation: AppString.infoAboutStackChartData),
              ),

              // stacked bar chart
              StackedBarChartOfMainCategoryDistribution(year: year),

              // legend
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: chartLegend(),
              )
            ],
          ))
        ],
      ),
    );
  }
}

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String gallaryYear;
  final VoidCallback onTap;

  const AnnualGallaryBuilder(
      {super.key, required this.gallaryYear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // the year of the gallary summary
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                gallaryYear,
                style: const TextStyle(
                  color: AppColor.blueMainColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // DIVIDER
            // divider
            const SizedBox(
              width: 100,
              child: Divider(
                thickness: 1.5,
                color: AppColor.blueMainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// yearly accounted and unaccounted totals
class YearTotalsAccountedUnaccountedBuilder extends StatelessWidget {
  final String accountedDays;
  final String accountedHours;
  final String unaccountedDays;
  final String unaccountedHours;

  const YearTotalsAccountedUnaccountedBuilder(
      {super.key,
      required this.accountedDays,
      required this.accountedHours,
      required this.unaccountedDays,
      required this.unaccountedHours});

  // function that builds out the accounted and unaccounted
  // sections
  Widget _onePieceData(
      {required String sectionName,
      required String sectionDays,
      required String sectionHours,
      required TextStyle sectionDataValueStyle,
      required Color lineChartIconColor}) {
    return SizedBox(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // section title
          Text(
            sectionName,
            style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),
          ),

          // days
          Row(
            children: [
              Icon(
                Icons.line_axis_rounded,
                size: 30,
                color: lineChartIconColor,
              ),
              Column(
                children: [
                  Text(
                    "$sectionDays days",
                    style: sectionDataValueStyle,
                  ),

                  // hours
                  Text(
                    "$sectionHours hours",
                    style: sectionDataValueStyle,
                  ),
                ],
              ),
            ],
          ),

          // section divider
          const SizedBox(
            width: 100,
            child: Divider(
              thickness: 2,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // accounted with data
          _onePieceData(
              sectionName: AppString.totalAccountedTitle,
              sectionDays: accountedDays,
              sectionHours: accountedHours,
              sectionDataValueStyle: AppTextStyle.pieChartTextStyling(),
              lineChartIconColor: Colors.green),

          // unaccounted with data
          _onePieceData(
              sectionName: AppString.totalUnaccountedTitle,
              sectionDays: unaccountedDays,
              sectionHours: unaccountedHours,
              sectionDataValueStyle: AppTextStyle.pieChartTextStyling(),
              lineChartIconColor: Colors.red),
        ],
      ),
    );
  }
}

Widget makeTransactionsIcon() {
  const width = 4.5;
  const space = 3.5;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: width,
        height: 10,
        color: const Color(0xFFA9A9A9),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 28,
        color: const Color(0xFF909090),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 42,
        color: const Color(0xFFCFCFCF),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 28,
        color: const Color(0xFF909090),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 10,
        color: const Color(0xFFA9A9A9),
      ),
    ],
  );
}
