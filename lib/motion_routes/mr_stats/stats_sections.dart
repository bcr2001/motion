import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_screens/ms_report/report_heat_map.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
// import '../../motion_reusable/general_reuseable.dart';

// Section 1: HeatMap Calender
class SummaryContributionHeatMap extends StatelessWidget {
  final int year;

  const SummaryContributionHeatMap({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, MainCategoryTrackerProvider,
        FirstAndLastDay>(builder: (context, user, main, days, child) {
      // user firebase uid
      final String currentUserUid = user.userUid!;
      final String targetYearData = year.toString();

      return FutureBuilder(
          future: main.retrieveDailyAccountedAndIntensities(
              currentUser: currentUserUid,
              year: targetYearData,
              getEntireIntensity: false),
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

              return Container(
                padding: const EdgeInsets.all(5),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColor.tileBackgroundColor, width: 2.0),
                    borderRadius: BorderRadius.circular(10)),
                child: HeatMap(
                  startDate: DateTime(year, 1, 1),
                  endDate: DateTime(year, 12, 31),
                  fontSize: 12,
                  scrollable: true,
                  defaultColor: AppColor.defaultHeatMapBlockColor,
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
                ),
              );
            }
          });
    });
  }
}

// Section 2: Main Category Overview
// the hours, days, and average time spent on the 5 main categories
class YearMainCategoryOveriew extends StatelessWidget {
  final String year;

  const YearMainCategoryOveriew({super.key, required this.year});

  // calculates the approriate height of the alert dialog
  // based on the number of items in the list view item count
  double calculateContainerHeight(int itemCount, double itemHeight) {
    return itemCount * itemHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, sub, child) {
      // currently logged in user
      final String currentUser = user.userUid!;

      // if the total amount of time for the current
      // month is 0, then the summary page info
      // is displayed
      return FutureBuilder(
          future: sub.retrieveMonthTotalAndAverage(
              currentUser, "$year-01-01", "$year-12-31", false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the data is loading, a shimmer effect is shown
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final snapshotData = snapshot.data;

              double maxHeight = 380.0; // Maximum height for the container
              double containerHeight = min(
                  calculateContainerHeight(snapshotData!.length, 80),
                  maxHeight);

              return Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                padding: const EdgeInsets.only(top: 12),
                height: containerHeight,
                child: Card(
                  child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshotData.length,
                      itemBuilder: (BuildContext context, index) {
                        // single item index
                        final singleItem = snapshotData[index];

                        // main category name
                        final String mainCatName =
                            singleItem["mainCategoryName"];

                        // total minuted converted to hours and minutes
                        final convertedTotal =
                            convertMinutesToTime(singleItem["total"]);

                        // average minutes converted to time
                        final convertedAverage =
                            convertMinutesToHoursMonth(singleItem["average"]);

                        // number of days
                        String numberOfDays =
                            convertMinutesToDays(singleItem["total"]);

                        return ListTile(
                          leading: Text(mainCatName,
                              style: AppTextStyle.subSectionTextStyle(
                                  fontsize: 14, fontweight: FontWeight.normal)),
                          title: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColor.tileBackgroundColor),
                              child: Center(
                                child: Text(
                                  convertedTotal,
                                  style: AppTextStyle.tileElementTextStyle(),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                          subtitle: Text(
                            numberOfDays,
                            style: const TextStyle(
                                color: AppColor.tileBackgroundColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(convertedAverage,
                              style: AppTextStyle.subSectionTextStyle(fontsize: 12.5, fontweight: FontWeight.normal)),
                        );
                      }),
                ),
              );
            }
          });
    });
  }
}

// SECTION 4: HIGHEST TRACKED TIME

