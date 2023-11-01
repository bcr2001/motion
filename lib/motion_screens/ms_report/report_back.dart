import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../motion_reusable/db_re/sub_ui.dart';
import '../../motion_reusable/general_reuseable.dart';
import '../../motion_themes/mth_app/app_images.dart';

// A custom widget for displaying a pie chart representing accounted and unaccounted data.
class AccountedUnaccountedReportPieChart extends StatelessWidget {
  const AccountedUnaccountedReportPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
            MainCategoryTrackerProvider>(
        builder: (context, user, day, main, child) {
      return FutureBuilder(
          future: main.retrieveMonthAccountUnaccountTable(
              user.userUid!, day.firstDay, day.lastDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading state: Show a shimmer effect while data is being loaded.
              return const ShimmerWidget.rectangular(width: 100, height: 100);
            } else if (snapshot.hasError) {
              // Error state: Display an error message if there's an issue with data retrieval.
              return const Text("Error 355 :(");
            } else {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                // Data loaded state: Calculate pie chart values and display it.
                List<Map<String, dynamic>> totalAccountUnaccountedMap =
                    snapshot.data ?? [];


                // gets and converts the accounted data to hours
                double accounted =
                    (totalAccountUnaccountedMap[0]["Accounted"] / 60);

                // gets and converts the unaccounted data to hours
                double unAccounted =
                    (totalAccountUnaccountedMap[0]["Unaccounted"] / 60);

                // total between accounted and unaccounted values
                double total = accounted + unAccounted;

                // converting both the accounted and unaccounted values to double
                double accountedDouble = double.parse(
                    ((accounted / total) * 100).toStringAsFixed(1));
                double unAccountedDouble = double.parse(
                    ((unAccounted / total) * 100).toStringAsFixed(1));

                return PieChartBuilder(sections: [
                  // Accounted proportion
                  PieChartSectionData(
                      titleStyle: AppTextStyle.pieChartTextStyling(),
                      title: "$accountedDouble%",
                      value: accountedDouble,
                      color: AppColor.accountedColor),

                  // Unaccounted proportion
                  PieChartSectionData(
                      titleStyle: AppTextStyle.pieChartTextStyling(),
                      title: "$unAccountedDouble%",
                      value: unAccountedDouble,
                      color: AppColor.unAccountedColor),
                ]);
              } else {
                return const Text("");
              }
            }
          });
    });
  }
}

// displays the Main category Distribution pie chart
class MainCategoryDistributionPieChart extends StatelessWidget {
  const MainCategoryDistributionPieChart({super.key});

  Color _getCategoryColor(int index) {
    switch (index) {
      case 0:
        return AppColor.educationPieChartColor;
      case 1:
        return AppColor.entertainmentPieChartColor;
      case 2:
        return AppColor.personalGrowthPieChartColor;
      case 3:
        return AppColor.skillsPieChartColor;
      case 4:
        return AppColor.sleepPieChartColor;
      default:
        return Colors.grey; // Default color for other categories
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, day, main, child) {
        return FutureBuilder(
          future: main.retrieveMainTotalTimeSpentSpecificDates(
            currentUser: user.userUid!,
            firstDay: day.firstDay,
            lastDay: day.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading state: Show a shimmer effect while data is being loaded.
              return const ShimmerWidget.rectangular(width: 100, height: 100);
            } else if (snapshot.hasError) {
              // Error state: Display an error message if there's an issue with data retrieval.
              return const Text("Error: Unable to retrieve data.");
            } else {
              List<Map<String, dynamic>> mainTotalResults = snapshot.data ?? [];

              logger.i(mainTotalResults);

              double totalMainCategoryValues =
                  mainTotalResults.fold(0.0, (prev, element) {
                return prev + (element["totalTimeSpent"] ?? 0.0);
              });

              List<PieChartSectionData> sections = [];

              for (int i = 0; i < mainTotalResults.length; i++) {
                final totalTimeSpent =
                    mainTotalResults[i]["totalTimeSpent"] ?? 0.0;
                double categoryValue =
                    totalTimeSpent / totalMainCategoryValues * 100;
                String formattedValue = categoryValue.toStringAsFixed(1);

                sections.add(
                  PieChartSectionData(
                    titleStyle: AppTextStyle.pieChartTextStyling(),
                    title: "$formattedValue%",
                    value: categoryValue,
                    color: _getCategoryColor(
                        i), // Define this function to get category colors
                  ),
                );
              }

              return PieChartBuilder(sections: sections);
            }
          },
        );
      },
    );
  }
}

// A custom widget for displaying a pie chart using the FL Chart library.
class PieChartBuilder extends StatelessWidget {
  // List of data sections for the pie chart.
  final List<PieChartSectionData>? sections;

  // Constructor for the PieChartBuilder class.
  // It requires a list of PieChartSectionData to build the pie chart.
  const PieChartBuilder({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Width of the widget
      height: 200, // Height of the widget
      child: PieChart(
        PieChartData(
          sections: sections, // Data sections for the pie chart
        ),
      ),
    );
  }
}

// constructs the most and least tracked widgets
// for both the main and subcategories
class MostAndLeastTrackedBuilder extends StatelessWidget {
  final String title;
  final String totalHours;
  final String averageHours;
  final String subcategoryName;
  final IconData iconDirection;
  final Color iconColor;

  const MostAndLeastTrackedBuilder(
      {super.key,
      required this.title,
      required this.totalHours,
      required this.averageHours,
      required this.subcategoryName,
      required this.iconDirection,
      required this.iconColor});

  // totalHours and averageHours
  Widget totalHoursAverageHours() {
    return Column(
      children: [
        // totalHours
        Text(
          totalHours,
          style: AppTextStyle.mostAndLestTextStyleTotalHours(),
        ),

        // averageHours
        Text(
          averageHours,
          style: AppTextStyle.mostAndLestTextStyleAverageHours(),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      width: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),

          // row of icon, total hours, and averageHours
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // icon
              Icon(
                iconDirection,
                color: iconColor,
                size: 45,
              ),

              // totalHours and averageHours
              totalHoursAverageHours()
            ],
          ),

          // subcategoryName
          Align(
            alignment: Alignment.center,
            child: Container(
                margin: const EdgeInsets.all(8.0),
                height: 30,
                width: 170,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text(
                    subcategoryName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )),
          ),

          // bottom divider
          Center(
            child: Container(
              margin: const EdgeInsets.only(left: 5),
              width: 150,
              child: const Divider(
                thickness: 1.5,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MostAndLeastTrackedResult extends StatelessWidget {
  final String sectionTitle;
  final int numberOfDaysInMonth;
  final IconData resultIcon;
  final Color resultIconColor;

  final Future<List<Map<String, dynamic>>> future;

  const MostAndLeastTrackedResult({
    super.key,
    required this.future,
    required this.sectionTitle,
    required this.numberOfDaysInMonth,
    required this.resultIcon,
    required this.resultIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
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
          // Data is available, snapshot.data to get the results
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> mostLeastResults = snapshot.data!;

            // Get category name for either least or most tracked
            final resultTitle =
                mostLeastResults[0]["result_tracked_category"] ?? 'N/A';

            // Get the value result of the time spent
            double resultTimeSpent =
                (mostLeastResults[0]["time_spent"] ?? 0) / 60;

            // Get the average of the result
            double resultAverage = resultTimeSpent / numberOfDaysInMonth;

            return MostAndLeastTrackedBuilder(
              title: sectionTitle,
              totalHours: resultTimeSpent.toStringAsFixed(2),
              averageHours: "${resultAverage.toStringAsFixed(2)}hr/day",
              subcategoryName: resultTitle,
              iconDirection: resultIcon,
              iconColor: resultIconColor,
            );
          } else {
            // Handle case where data is empty or null
            return MostAndLeastTrackedBuilder(
              title: sectionTitle,
              totalHours: "0.0",
              averageHours: "0.0hr/day",
              subcategoryName: "TBD",
              iconDirection: resultIcon,
              iconColor: resultIconColor,
            );
            ;
          }
        }
      },
    );
  }
}

// A card that contains both most and least tracked
// main or subcategory
class MLTitleAndCard extends StatelessWidget {
  final String mlTitle;
  final Card cardContent;

  const MLTitleAndCard(
      {super.key, required this.mlTitle, required this.cardContent});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title (main category or subcategory)
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              mlTitle,
              style: AppTextStyle.categoryTitleTextStyle(),
            ),
          ),

          // card content
          SizedBox(height: screenHeight * 0.24, child: cardContent)
        ],
      ),
    );
  }
}

// pie chart color palette
Widget chartColorPalette({required Color color}) {
  return Container(
    height: 10,
    width: 20,
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
  );
}
