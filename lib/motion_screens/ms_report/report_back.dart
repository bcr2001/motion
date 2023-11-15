import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_report/report_front.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../motion_reusable/db_re/sub_ui.dart';

// A custom widget for displaying a pie chart
//representing accounted and unaccounted data.
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
              if (snapshot.data != null && snapshot.data!.isNotEmpty) {
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

                if (accounted == 0 && unAccounted == 0) {
                  return const InfoAboutNoData();
                } else {
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
                }
              } else {
                return const InfoAboutNoData();
              }
            }
          });
    });
  }
}

// displays the Main category Distribution pie chart
class MainCategoryDistributionPieChart extends StatelessWidget {
  final Future<List<Map<String, dynamic>>?> future;

  const MainCategoryDistributionPieChart({super.key, required this.future});

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
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading state: Show a shimmer effect while data is being loaded.
          return const ShimmerWidget.rectangular(width: 100, height: 100);
        } else if (snapshot.hasError) {
          // Error state: Display an error message if there's an issue with data retrieval.
          return const Text("Error: Unable to retrieve data.");
        } else {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> mainTotalResults = snapshot.data ?? [];

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
          } else {
            return const InfoAboutNoData();
          }
        }
      },
    );
  }
}

// A custom widget for displaying a pie chart using the FL Chart library.
class PieChartBuilder extends StatelessWidget {
  final List<PieChartSectionData>? sections;

  const PieChartBuilder({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    if (sections != null && sections!.isNotEmpty) {
      final cleanSections = sections!
          .where((section) => !section.value.isNaN && section.value > 0)
          .toList();

      if (cleanSections.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        width: 200,
        height: 200,
        child: PieChart(
          PieChartData(
            sections: cleanSections,
            startDegreeOffset: 45,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
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
              style: AppTextStyle.topAndBottomTextStyle(),
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
                    style: AppTextStyle.topAndBottomTextStyle(),
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
            final String resultTitle =
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

// information to the user
class InfoToTheUser extends StatelessWidget {
  final String sectionInformation;

  const InfoToTheUser({super.key, required this.sectionInformation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // info icon
          const Padding(
            padding: EdgeInsets.only(right: 6.0),
            child: Icon(Icons.info_outline, size: 18,),
          ),

          // information about the specific section
          Flexible(
            child: Text(
              sectionInformation,
              style: AppTextStyle.informationTextStyle(),
            ),
          )
        ],
      ),
    );
  }
}

// highest tracked time per subcategory section element builder
// it shows the subcategory name, time spent on the subcategory
// and the date the subcategory total was tracked
class HighestTrackedSectionElement extends StatelessWidget {
  final String subcategoryName;
  final String timeSpent;
  final String date;

  const HighestTrackedSectionElement(
      {super.key,
      required this.subcategoryName,
      required this.timeSpent,
      required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // subcategory name
        Text(
          subcategoryName,
          style: AppTextStyle.topAndBottomTextStyle(),
          textAlign: TextAlign.center,
        ),

        // total time tracked
        Text(
          timeSpent,
          style: AppTextStyle.mostAndLestTextStyleTotalHours(),
        ),

        // date recorded
        Text(
          date,
          style: AppTextStyle.topAndBottomTextStyle(),
        ),

        // blue divider
        const SizedBox(
          width: 105,
          child: Divider(
            thickness: 2.0,
            color: AppColor.blueMainColor,
          ),
        ),
      ],
    );
  }
}

// a grid of highest tracked subcategories
// each subcategiry that is being tracked in the course of the month
// has it's max, the class below displays the max of these subcategories
class GridHighestTrackedSubcategory extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;

  const GridHighestTrackedSubcategory({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    // get the screen height of the device
    final screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While the data is loading, a shimmer effect is shown
            return const ShimmerWidget.rectangular(
              height: 200,
              width: 200,
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Data is available, snapshot.data to get the results
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.isNotEmpty) {
              // a list of the database query result
              List<Map<String, dynamic>> highestResults = snapshot.data!;


              return Container(
                margin: const EdgeInsets.only(bottom: 30.0),
                height: screenHeight * 0.45,
                child: Card(
                  child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0),
                      itemCount: highestResults.length,
                      itemBuilder: (BuildContext context, index) {
                        // element subcategory name
                        final String elementSubName =
                            highestResults[index]["subcategoryName"];

                        // element total time spent
                        final String elementTimeSpent = convertHoursToTimeGrid(
                            highestResults[index]["timeSpent"]);

                        // element date
                        final String elementDate =
                            highestResults[index]["date"];

                        return HighestTrackedSectionElement(
                            subcategoryName: elementSubName,
                            timeSpent: elementTimeSpent,
                            date: elementDate);
                      }),
                ),
              );
            } else {
              // when the database table is empty and there is no data to be
              // displayed, then the placeholder grid below is shown
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // first place holder: Subcategory 1
                  HighestTrackedSectionElement(
                      subcategoryName: AppString.subcategory1,
                      timeSpent: AppString.hoursTimeSpentHolder,
                      date: AppString.firstDayOfTrackingEver),

                  // first place holder: Subcategory 2
                  HighestTrackedSectionElement(
                      subcategoryName: AppString.subcategory2,
                      timeSpent: AppString.hoursTimeSpentHolder,
                      date: AppString.firstDayOfTrackingEver),

                  // first place holder: Subcategory 3
                  HighestTrackedSectionElement(
                      subcategoryName: AppString.subcategory3,
                      timeSpent: AppString.hoursTimeSpentHolder,
                      date: AppString.firstDayOfTrackingEver),
                ],
              );
            }
          }
        });
  }
}
