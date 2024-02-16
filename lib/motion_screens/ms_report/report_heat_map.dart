import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

import '../../motion_themes/mth_styling/motion_text_styling.dart';

class ContributionsHeatMap extends StatelessWidget {
  const ContributionsHeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        FirstAndLastDay>(builder: (context, user, main, days, child) {
      // user firebase uid
      final String currentUserUid = user.userUid!;

      return FutureBuilder(
          future: main.retrieveDailyAccountedAndIntensities(
              currentUser: currentUserUid, getEntireIntensity: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return const Text("Error 355 :(");
            } else {
              final results = snapshot.data!;

              // logger.i(results);

              final convertedResults = datasetFormatConverter(data: results);

              return HeatMapCalendar(
                textColor: Colors.black,
                fontSize: 15,
                borderRadius: 8,
                defaultColor: AppColor.defaultHeatMapBlockColor,
                flexible: true,
                colorMode: ColorMode.color,
                datasets: convertedResults,
                colorsets: const {
                  0: AppColor.defaultHeatMapBlockColor,
                  5: AppColor.intensity5,
                  10: AppColor.intensity10,
                  15: AppColor.intensity15,
                  20: AppColor.intensity20,
                  25: AppColor.intensity25,
                },
                onClick: (value) {
                  // yyyy-mm-dd date format
                  String formattedDate = DateFormat('yyyy-MM-dd').format(value);

                  // dd-mm-yyyy date format
                  String dateTitle = formatDateString(formattedDate);

                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialogConst(
                          alertDialogTitle: dateTitle,
                          alertDialogContent: SpecificDaySummaryHeatMap(
                              dateValue: formattedDate),
                          screenHeight: 200,
                          screenWidth: 150,
                          heightFactor: 0.30,
                        );
                      });
                },
              );
            }
          });
    });
  }
}

// processing and converting a list of map objects to the
// required heatmap dataset format
Map<DateTime, int> datasetFormatConverter(
    {required List<Map<String, dynamic>> data}) {
  Map<DateTime, int> resultMap = {};

  // interate over the list of maps objects and convert each element
  // into the correct format
  for (var entry in data) {
    // date string convertion
    DateTime date = DateTime.parse(entry["date"]);

    // intensity
    int intensity = entry["intensity"];

    // map of the two
    resultMap[date] = intensity;
  }

  return resultMap;
}

/// Formats a date string in the format "yyyy-MM-dd" to "dd MMMM yyyy" format.
/// Takes a [String] inputDate in "yyyy-MM-dd" format and returns a formatted date
/// string in "dd MMMM yyyy" format. For example, if inputDate is "2023-12-21",
/// the function returns "21 December 2023".
String formatDateString(String inputDate) {
  // Parse the input date string into a DateTime object
  DateTime dateTime = DateTime.parse(inputDate);

  // Format the date as "dd MMMM yyyy"
  String formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
  return formattedDate;
}

/// Calculates the total time spent by summing the "totalTimeSpent" values
/// in the given list of maps.
/// [data] is a list of maps where each map contains a "totalTimeSpent" key
/// with a numeric value representing the time spent.
/// Returns the total time spent as a double.
double calculateTotalTime(List<Map<String, dynamic>> data) {
  double sum = 0.0;
  for (var item in data) {
    sum += item['totalTimeSpent'];
  }
  return sum;
}

/// Calculates a score based on the given number of minutes.
///
/// This function takes an input `minutes` and converts it to hours. Depending on the
String calculateScoreFromMinutes(double minutes) {
  double hours = minutes / 60; // Convert minutes to hours

  // Depending on the hours, return the appropriate score
  if (hours <= 0) {
    return "0";
  } else if (hours <= 5) {
    return "5";
  } else if (hours <= 10) {
    return "10";
  } else if (hours <= 15) {
    return "15";
  } else if (hours <= 20) {
    return "20";
  } else if (hours <= 25) {
    return "25";
  } else {
    // Handle cases where hours exceed 25
    // You can return a default value or handle it based on your requirements
    return "-1"; // For example, return -1 for an invalid input
  }
}

// Display an alert dialog when the user clicks on a specific day on the heatmap.
// This dialog provides additional information or options related to the selected day.
class SpecificDaySummaryHeatMap extends StatelessWidget {
  final String dateValue;

  SpecificDaySummaryHeatMap({super.key, required this.dateValue});

  final ScrollController _scrollController1 = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubcategoryTrackerDatabaseProvider, UserUidProvider>(
        builder: (context, sub, user, child) {
      // current logged in user uid
      final String currentUserUid = user.userUid!;

      return FutureBuilder(
          future: sub.retrieveSubcategoryTotalsForSpecificDate(
              selectedDate: dateValue, currentUser: currentUserUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return const Text("Error 355 :(");
            } else {
              final snapShotData = snapshot.data!;

              // logger.i(snapShotData);

              // calculating total accounted time
              final double totalTimeAccounted =
                  calculateTotalTime(snapShotData);

              final String totalTimeAccountedConverted =
                  convertMinutesToTime(totalTimeAccounted);

              final String contributionScore =
                  calculateScoreFromMinutes(totalTimeAccounted);

              logger.i(totalTimeAccounted);

              return Column(
                children: [
                  // contirbution Score
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Contribution Score: $contributionScore",
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // total time accounted for selected date
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Accounted: $totalTimeAccountedConverted",
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // subcategories and their recorded time
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    height: 210,
                    child: Scrollbar(
                        radius: const Radius.circular(10.0),
                        trackVisibility: true,
                        controller: _scrollController1,
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: snapShotData.length,
                            itemBuilder: (BuildContext context, index) {
                              // convert minutes to appropriate time format
                              final convertedTotalTimeSpent1 =
                                  convertMinutesToTime(
                                      snapShotData[index]["totalTimeSpent"]);

                              return ListTile(
                                title: Text(
                                    snapShotData[index]["subcategoryName"],
                                    style: AppTextStyle.leadingTextLTStyle()),
                                trailing: Container(
                                  width: 105,
                                  height: 23,
                                  decoration: BoxDecoration(
                                    color: AppColor.tileBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                      child: Text(
                                    convertedTotalTimeSpent1,
                                    style: AppTextStyle.tileElementTextStyle(),
                                  )),
                                ),
                              );
                            })),
                  ),
                ],
              );
            }
          });
    });
  }
}
