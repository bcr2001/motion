import 'package:flutter/material.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';
import '../../motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import '../../motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import '../../motion_core/motion_providers/sql_pvd/track_pvd.dart';
import '../../motion_routes/mr_home/home_reusable/front_home.dart';
import '../../motion_themes/mth_styling/app_color.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';
import 'report_back.dart';

// displays the most tracked main and subcategories
class MostAndLeastTrackedMaincategorySection extends StatelessWidget {
  const MostAndLeastTrackedMaincategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 14),
          child: Consumer3<FirstAndLastDay, UserUidProvider,
              MainCategoryTrackerProvider>(
            builder: (context, day, user, main, child) {
              // first and last day of the month
              String firstDayOfMonth = day.firstDay;
              String lastDayOfMonth = day.lastDay;
              String currentLoggedInUser = user.userUid!;

              int numberOfDaysInCurrentMonth = day.days;

              logger.i("Number of Days: $numberOfDaysInCurrentMonth");

              return Row(
                children: [
                  // most tracked main category
                  MostAndLeastTrackedResult(
                      sectionTitle: AppString.mostTrackedTitle,
                      numberOfDaysInMonth: numberOfDaysInCurrentMonth,
                      future: main.retrieveMostAndLeastTrackedMainCategory(
                          firstDay: firstDayOfMonth,
                          lastDay: lastDayOfMonth,
                          currentUser: currentLoggedInUser,
                          isMost: true)),

                  // least tracked main category
                  MostAndLeastTrackedResult(
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
    );
  }
}

// class MostAndLeastTrackedSubcategorySection extends StatelessWidget {
//   const MostAndLeastTrackedSubcategorySection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//           padding: const EdgeInsets.only(top: 10, bottom: 14),
//           child: Consumer3<FirstAndLastDay, UserUidProvider,
//               MainCategoryTrackerProvider>(
//             builder: (context, day, user, main, child) {
//               // first and last day of the month
//               String firstDayOfMonth = day.firstDay;
//               String lastDayOfMonth = day.lastDay;
//               String currentLoggedInUser = user.userUid!;

//               return Row(
//                 children: [
//                   // most tracked subcategory
//                   MostAndLeastTrackedResult(
//                       sectionTitle: AppString.mostTrackedTitle,
//                       future: main.retrieveMostAndLeastTrackedMainCategory(
//                           firstDay: firstDayOfMonth,
//                           lastDay: lastDayOfMonth,
//                           currentUser: currentLoggedInUser,
//                           isMost: true)),

//                   // least tracked subcategory
//                   MostAndLeastTrackedResult(
//                       sectionTitle: AppString.leastTrackedTitle,
//                       future: main.retrieveMostAndLeastTrackedMainCategory(
//                           firstDay: firstDayOfMonth,
//                           lastDay: lastDayOfMonth,
//                           currentUser: currentLoggedInUser,
//                           isMost: false)),
//                 ],
//               );
//             },
//           )),
//     );
//   }
// }

// custom widget that returns a pie chart
// and their data value distribution
class PieChartAndValues extends StatelessWidget {
  const PieChartAndValues({super.key});

  // pie chart color palette
  Widget _chartColorPalette({required Color color}) {
    return Container(
      height: 14,
      width: 29,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    );
  }

  // displays the pie chart color palette in a column
  Widget _columnPieChartColorPalette() {
    return SizedBox(
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // accounted color palette
          _chartColorPalette(color: AppColor.accountedColor),

          // unaccounted color palette
          _chartColorPalette(color: AppColor.unAccountedColor)
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
          Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
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
      );
    });
  }
}

// info to the user that the sleep main category is
// not included when considering whether to assign
// most and least tracked
class InfoAboutSleep extends StatelessWidget {
  const InfoAboutSleep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: const [
          Icon(Icons.info_outline),
          Flexible(
            child: Text(
              "The amount of time you spend sleeping is not considered when determining the most and least time tracked.",
              style: TextStyle(fontSize: 10),
            ),
          )
        ],
      ),
    );
  }
}

// Row(
//                 children: [
//                   Column(
//                     children: const [
//                       // Most Tracked Main Category
//                       MostAndLeastTrackedBuilder(
//                         title: AppString.mostTrackedMainTitle,
//                         totalHours: "107.39",
//                         averageHours: "3.5hrs/day",
//                         subcategoryName: "SM/Anime/MM",
//                         iconDirection: Icons.arrow_circle_up_outlined,
//                         iconColor: AppColor.mostTrackedBorderColor,
//                       ),

//                       // Least Tracked Main Category
//                       MostAndLeastTrackedBuilder(
//                         title: AppString.leastTrackedMainTitle,
//                         totalHours: "107.39",
//                         averageHours: "3.5hrs/day",
//                         subcategoryName: "SM/Anime/MM",
//                         iconDirection: Icons.arrow_circle_down_outlined,
//                         iconColor: Colors.red,
//                       ),
//                     ],
//                   ),

//                   // Most Tracked Main Category
//                   Column(
//                     children: const [
//                       MostAndLeastTrackedBuilder(
//                           title: AppString.mostTrackedSubcategoryTitle,
//                           totalHours: "107.39",
//                           averageHours: "3.5hrs/day",
//                           subcategoryName: "SM/Anime/MM",
//                           iconDirection: Icons.arrow_circle_down_outlined,
//                           iconColor: AppColor.mostTrackedBorderColor),

//                       // Least Tracked Main Category
//                       MostAndLeastTrackedBuilder(
//                           title: AppString.leastTrackedSubcategoryTitle,
//                           totalHours: "107.39",
//                           averageHours: "3.5hrs/day",
//                           subcategoryName: "SM/Anime/MM",
//                           iconDirection: Icons.arrow_circle_down_outlined,
//                           iconColor: Colors.red),
//                     ],
//                   ),
//                 ],
//               );