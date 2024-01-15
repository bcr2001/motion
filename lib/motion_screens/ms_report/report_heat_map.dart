import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ContributionsHeatMap extends StatelessWidget {
  const ContributionsHeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        FirstAndLastDay>(builder: (context, user, main, days, child) {
      // user firebase uid
      final String currentUserUid = user.userUid!;

      // first and last day of the current month
      final String firstDayOfMonth = days.firstDay;
      final String lastDayOfMonth = days.lastDay;

      return FutureBuilder(
          future: main.retrieveDailyAccountedAndIntensities(
              currentUser: currentUserUid,
              firstDayOfMonth: firstDayOfMonth,
              lastDayOfMonth: lastDayOfMonth),
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

              final convertedResults = datasetFormatConverter(data: results);

              logger.i(results);

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
                  3: AppColor.intensity3,
                  6: AppColor.intensity6,
                  9: AppColor.intensity9,
                  12: AppColor.intensity12,
                  15: AppColor.intensity15,
                  18: AppColor.intensity18,
                  21: AppColor.intensity21,
                  24: AppColor.intensity24,
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
                            screenWidth: 150);
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

// Display an alert dialog when the user clicks on a specific day on the heatmap.
// This dialog provides additional information or options related to the selected day.
class SpecificDaySummaryHeatMap extends StatelessWidget {
  final String dateValue;

  const SpecificDaySummaryHeatMap({super.key, required this.dateValue});

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

              logger.i(snapShotData);

              return Column();
            }
          });
    });
  }
}
