import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_windows/efficieny_window.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

import '../../motion_themes/mth_app/app_strings.dart';
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

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: HeatMapCalendar(
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
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(value);

                    // dd-mm-yyyy date format
                    String dateTitle = formatDateString(formattedDate);

                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return DynamicHeightAlertDialog(
                            alertDialogTitle: dateTitle,
                            alertDialogContent: SpecificDaySummaryHeatMap(
                                dateValue: formattedDate),
                          );
                        });
                  },
                ),
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
class SpecificDaySummaryHeatMap extends StatefulWidget {
  final String dateValue;

  const SpecificDaySummaryHeatMap({super.key, required this.dateValue});

  @override
  State<SpecificDaySummaryHeatMap> createState() =>
      _SpecificDaySummaryHeatMapState();
}

class _SpecificDaySummaryHeatMapState extends State<SpecificDaySummaryHeatMap> {
  ScrollController _scrollController1 = ScrollController();
  bool isSubcategoryActive = true; // State to track active button

  // Function to toggle the active button state
  void toggleActiveButton(bool isSubcategory) {
    setState(() {
      isSubcategoryActive = isSubcategory;
    });
  }

  // initialize scroll controller
  @override
  void initState() {
    super.initState();
    _scrollController1 = ScrollController();
  }

  @override
  void dispose() {
    _scrollController1.dispose();
    super.dispose();
  }

  // Elevated button with dynamic styling based on active state
  // Outlined button with dynamic styling based on active state
  Widget _outlineButton(
      {required void Function()? onPressed,
      required String buttonName,
      required bool isActive}) {
    return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isActive
                ? AppColor.blueMainColor
                : Colors.transparent, // Dynamic outline color
            width: 2.0, // You can adjust the width as needed
          ),
        ),
        child: Text(
          buttonName,
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        ));
  }

  // Subcategory and main category buttons
  Widget subAndMainButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 5),
      child: Row(
        children: [
          // Subcategory button
          _outlineButton(
            onPressed: () => toggleActiveButton(true),
            buttonName: AppString.subcategoryTitle,
            isActive: isSubcategoryActive,
          ),

          // Main category button
          _outlineButton(
            onPressed: () => toggleActiveButton(false),
            buttonName: AppString.mainCategoryTitle,
            isActive: !isSubcategoryActive,
          )
        ],
      ),
    );
  }

  // calculates the approriate height of the alert dialog
  // based on the number of items in the list view item count
  double calculateContainerHeight(int itemCount, double itemHeight) {
    return itemCount * itemHeight;
  }

  //
  Widget _contentContainer(
      {required double containerHeight,
      required int itemCount,
      required Widget Function(BuildContext, int) itemBuilder}) {
    return Container(
      height: containerHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Scrollbar(
        thickness: 3,
        thumbVisibility: true,
        radius: const Radius.circular(10.0),
        trackVisibility: true,
        controller: _scrollController1,
        child: ListView.builder(
            controller: _scrollController1,
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            itemBuilder: itemBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SubcategoryTrackerDatabaseProvider, UserUidProvider,
            MainCategoryTrackerProvider>(
        builder: (context, sub, user, main, child) {
      // current logged in user uid
      final String currentUserUid = user.userUid!;

      return FutureBuilder(
          future: sub.retrieveSubcategoryTotalsForSpecificDate(
              selectedDate: widget.dateValue, currentUser: currentUserUid),
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

              logger.i(widget.dateValue);

              // logger.i(snapShotData);

              // calculating total accounted time
              final double totalTimeAccounted =
                  calculateTotalTime(snapShotData);

              final String totalTimeAccountedConverted =
                  convertMinutesToTime(totalTimeAccounted);

              double maxHeight = 300.0; // Maximum height for the container
              double containerHeight = min(
                  calculateContainerHeight(snapShotData.length, 60), maxHeight);

              final String contributionScore =
                  calculateScoreFromMinutes(totalTimeAccounted);

              logger.i(totalTimeAccounted);

              return Column(
                children: [
                  // total time accounted for selected date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // total accounted time for the selected day
                      // and the contibution score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Accounted: $totalTimeAccountedConverted",
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),

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
                        ],
                      ),

                      // efficiency score for the current date
                      EfficienyScoreSelectedDay(
                        selectedDay: widget.dateValue,
                      ),
                    ],
                  ),

                  // buttons that toggle between subcategory and main category
                  // data
                  subAndMainButtons(),

                  // subcategories and their recorded time

                  isSubcategoryActive
                      ? _contentContainer(
                          containerHeight: containerHeight,
                          itemCount: snapShotData.length,
                          itemBuilder: (BuildContext context, index) {
                            // convert minutes to appropriate time format
                            final convertedTotalTimeSpent1 =
                                convertMinutesToTime(
                                    snapShotData[index]["totalTimeSpent"]);

                            return ListTile(
                              title: Text(
                                  snapShotData[index]["subcategoryName"],
                                  style: AppTextStyle.subSectionTextStyle(
                                      fontsize: 14,
                                      fontweight: FontWeight.normal)),
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
                                  style: AppTextStyle.subSectionTextStyle(fontsize: 11, color: AppColor.tileElementColor),
                                )),
                              ),
                            );
                          })
                      : FutureBuilder(
                          future: main.retrieveMCTotalAndXPEarned(
                              currentUser: currentUserUid,
                              targetDate: widget.dateValue),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColor.blueMainColor,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Text("Error 355 :(");
                            } else {
                              final resultMCTotalAndXP = snapshot.data ?? [];

                              // Maximum height for the container
                              double maxHeight = 300.0;
                              double containerHeight2 =
                                  calculateContainerHeight(
                                      resultMCTotalAndXP.length, 60);

                              double finalContainerHeight =
                                  min(containerHeight2, maxHeight);

                              logger.i(
                                  "CONTAINER HEIGHT MAIN: $containerHeight2");

                              return _contentContainer(
                                  containerHeight: finalContainerHeight,
                                  itemCount: resultMCTotalAndXP.length,
                                  itemBuilder: (BuildContext context, index) {
                                    // main category name
                                    final String rltMainCategoryName =
                                        resultMCTotalAndXP[index]
                                            ["mainCategoryName"];

                                    // total time spent
                                    final double rltTotalTimeSpent =
                                        resultMCTotalAndXP[index]
                                            ["totalTimeSpent"];
                                    final String rltTotalTimeSpentConverted =
                                        convertMinutesToTime(rltTotalTimeSpent);

                                    // total xp earned
                                    final String rltXPEarned =
                                        resultMCTotalAndXP[index]["xp_earned"];

                                    return CustomeListTile1(
                                        leadingName: rltMainCategoryName,
                                        titleName: rltTotalTimeSpentConverted,
                                        trailingName: rltMainCategoryName !=
                                                "Entertainment"
                                            ? "$rltXPEarned xp"
                                            : rltXPEarned);
                                  });
                            }
                          })
                ],
              );
            }
          });
    });
  }
}
