import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/seven_days_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';
import '../../motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import '../../motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import '../../motion_core/motion_providers/sql_pvd/track_pvd.dart';
import '../../motion_routes/mr_home/home_reusable/front_home.dart';
import '../../motion_themes/mth_styling/app_color.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';
import 'report_back.dart';

// display the most tracked and least tracked main category
class MostAndLeastTrackedMaincategorySection extends StatelessWidget {
  const MostAndLeastTrackedMaincategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return MLTitleAndCard(
        mlTitle: AppString.mainCategoryViewButtonName,
        cardContent: Card(
          child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Consumer3<FirstAndLastDay, UserUidProvider,
                  MainCategoryTrackerProvider>(
                builder: (context, day, user, main, child) {
                  // first and last day of the month
                  String firstDayOfMonth = day.firstDay;
                  String lastDayOfMonth = day.lastDay;

                  // currently logged in user
                  String currentLoggedInUser = user.userUid!;

                  // the number of days in the current month
                  // used to get the average hours per day
                  int numberOfDaysInCurrentMonth = day.days;

                  return Row(
                    children: [
                      // most tracked main category
                      MostAndLeastTrackedResult(
                          resultIcon: Icons.line_axis,
                          resultIconColor: Colors.green,
                          sectionTitle: AppString.mostTrackedTitle,
                          numberOfDaysInMonth: numberOfDaysInCurrentMonth,
                          future: main.retrieveMostAndLeastTrackedMainCategory(
                              firstDay: firstDayOfMonth,
                              lastDay: lastDayOfMonth,
                              currentUser: currentLoggedInUser,
                              isMost: true)),

                      // least tracked main category
                      MostAndLeastTrackedResult(
                          resultIcon: Icons.line_axis,
                          resultIconColor: Colors.red,
                          sectionTitle: AppString.leastTrackedTitle,
                          numberOfDaysInMonth: numberOfDaysInCurrentMonth,
                          future: main.retrieveMostAndLeastTrackedMainCategory(
                              firstDay: firstDayOfMonth,
                              lastDay: lastDayOfMonth,
                              currentUser: currentLoggedInUser,
                              isMost: false)),
                    ],
                  );
                },
              )),
        ));
  }
}

// the subcategory that was most and least tracked
// is displayed by the class below
class MostAndLeastTrackedSubcategorySection extends StatelessWidget {
  const MostAndLeastTrackedSubcategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return MLTitleAndCard(
        mlTitle: AppString.subcategoryViewButtonName,
        cardContent: Card(
          child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Consumer3<FirstAndLastDay, UserUidProvider,
                  SubcategoryTrackerDatabaseProvider>(
                builder: (context, day, user, sub, child) {
                  // first and last day of the month
                  String firstDayOfMonth = day.firstDay;
                  String lastDayOfMonth = day.lastDay;

                  // currently logged in user
                  String currentLoggedInUser = user.userUid!;

                  // number of days in the current month
                  int numberOfDaysInCurrentMonth = day.days;

                  return Row(
                    children: [
                      // most tracked subcategory
                      MostAndLeastTrackedResult(
                          resultIcon: Icons.line_axis,
                          resultIconColor: Colors.green,
                          sectionTitle: AppString.mostTrackedTitle,
                          numberOfDaysInMonth: numberOfDaysInCurrentMonth,
                          future: sub.retrieveMostAndLeastTrackedSubcategory(
                              firstDay: firstDayOfMonth,
                              lastDay: lastDayOfMonth,
                              currentUser: currentLoggedInUser,
                              isMost: true)),

                      // least tracked subcategory
                      MostAndLeastTrackedResult(
                          resultIcon: Icons.line_axis,
                          resultIconColor: Colors.red,
                          sectionTitle: AppString.leastTrackedTitle,
                          numberOfDaysInMonth: numberOfDaysInCurrentMonth,
                          future: sub.retrieveMostAndLeastTrackedSubcategory(
                              firstDay: firstDayOfMonth,
                              lastDay: lastDayOfMonth,
                              currentUser: currentLoggedInUser,
                              isMost: false)),
                    ],
                  );
                },
              )),
        ));
  }
}

// custom widget that returns a pie chart
// and their data value distribution
class PieChartAndValuesAccountedAndUnaccounted extends StatelessWidget {
  const PieChartAndValuesAccountedAndUnaccounted({super.key});

  // displays the pie chart color palette in a column
  Widget _columnPieChartColorPalette() {
    return SizedBox(
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // accounted color palette
          chartColorPalette(color: AppColor.accountedColor),

          // unaccounted color palette
          chartColorPalette(color: AppColor.unAccountedColor)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        FirstAndLastDay>(builder: (context, user, main, day, child) {
      final currentUser = user.userUid!;
      final firstDayofMonth = day.firstDay;
      final lastDayOfMonth = day.lastDay;

      return
          // pie chart and data values
          Container(
            height: 300,
        margin: const EdgeInsets.only(bottom: 15.0),
        child: Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // the pie chart that shows the distribution between
              // accounted and unaccounted values
              const AccountedUnaccountedReportPieChart(),
        
              // accounted month total
              Column(
                children: [
                  // accounted total for the current month
                  entireTimeAccountedAndUnaccounted(
                      future: main.retrieveEntireMonthlyTotalMainCategoryTable(
                          currentUser, firstDayofMonth, lastDayOfMonth, false),
                      resultName: AppString.accountedTitle,
                      dayStyle: AppTextStyle.resultTitleStyle(false),
                      hoursStyle:
                          AppTextStyle.accountRegularAndUnaccountTextStyle()),
        
                  // unaccounted total for the current month
                  entireTimeAccountedAndUnaccounted(
                      future: main.retrieveEntireMonthlyTotalMainCategoryTable(
                          currentUser, firstDayofMonth, lastDayOfMonth, true),
                      resultName: AppString.unAccountedTitle,
                      dayStyle: AppTextStyle.resultTitleStyle(true),
                      hoursStyle:
                          AppTextStyle.accountRegularAndUnaccountTextStyle())
                ],
              ),
        
              // pie chart legend
              _columnPieChartColorPalette()
            ],
          ),
        ),
      );
    });
  }
}

// Main Category Distribution Pie Chart and legend
class PieChartDataMainCategoryDistribution extends StatelessWidget {

  final Future<List<Map<String, dynamic>>?> future;
  
  const PieChartDataMainCategoryDistribution({super.key, required this.future});

  // main category distribution legend
  Widget _mainCategoryPieChartLegend(
      {required Color color, required String mainCategoryName}) {
    return Row(
      children: [
        // legend color
        chartColorPalette(color: color),

        // main category name
        Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: Text(
            mainCategoryName,
            style: AppTextStyle.legendTextStyling(),
          ),
        )
      ],
    );
  }

  // legend rows
  Widget legendRows() {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // sleep
          _mainCategoryPieChartLegend(
              color: AppColor.sleepPieChartColor,
              mainCategoryName: AppString.sleepMainCategory),

          // education
          _mainCategoryPieChartLegend(
              color: AppColor.educationPieChartColor,
              mainCategoryName: AppString.educationMainCategory),

          // skills
          _mainCategoryPieChartLegend(
              color: AppColor.skillsPieChartColor,
              mainCategoryName: AppString.skillMainCategory),

          // entertainment
          _mainCategoryPieChartLegend(
              color: AppColor.entertainmentPieChartColor,
              mainCategoryName: AppString.entertainmentMainCategory),

          // personal growth
          _mainCategoryPieChartLegend(
              color: AppColor.personalGrowthPieChartColor,
              mainCategoryName: AppString.personalGrowthMainCategory)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // main category pie chart distribution
            MainCategoryDistributionPieChart(
                future:future,
              ),
      
            legendRows()
          ],
        ),
      ),
    );
  }
}

// info to the user that the sleep main category is
// not included when considering whether to assign
// most and least tracked
class InfoAboutSleep extends StatelessWidget {
  const InfoAboutSleep({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoToTheUser(
        sectionInformation: AppString.informationAboutSleep);
  }
}

// info to the user about the highest tracked
// time per subcategory section
class InfoAboutHightesTrackedTime extends StatelessWidget {
  const InfoAboutHightesTrackedTime({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoToTheUser(
        sectionInformation: AppString.informationAboutHighestTrackedTime);
  }
}

// info about no data in the database
class InfoAboutNoData extends StatelessWidget {
  const InfoAboutNoData({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // no data image
        AppImages.noDataAvailableYet,

        // information about what the image illustrates
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // info icon
              const Padding(
                padding: EdgeInsets.only(right: 2.0),
                child: Icon(Icons.info_outline),
              ),

              // information about the specific section
              Text(
                AppString.informationAboutNoData,
                style: AppTextStyle.informationTextStyle(),
              )
            ],
          ),
        ),
      ],
    );
  }
}

// grouped bar chart for the distribution of accounted
// and unaccounted time during the course of the week
class GroupedBarChartOfAccountedAndUnaccountedTime extends StatelessWidget {
  const GroupedBarChartOfAccountedAndUnaccountedTime({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<FirstAndLastWithSevenDaysDiff, UserUidProvider,
            MainCategoryTrackerProvider>(
        builder: (context, week, user, main, child) {
      // current logged in user
      final String currentUser = user.userUid!;

      // first and last date of the week
      final String firstDayOfWeek = week.firstDay;
      final String lastDayOfWeek = week.lastDay;

      return FutureBuilder(
          future: main.retrieveAWeekOfAccountedAndAccountedData(
              currentUser: currentUser,
              firstDatePeriod: firstDayOfWeek,
              lastDatePeriod: lastDayOfWeek),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the data is loading, a shimmer effect is shown
              return const ShimmerWidget.rectangular(
                height: 50,
                width: 50,
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // if there is data available then the
              // grouped chart is shown, otherwise
              // an empty widget is rendered on the screen
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                logger.i(snapshot.data);
                return AppImages.chartNoData;
              } else {
                return const SizedBox.shrink();
              }
            }
          });
    });
  }
}
