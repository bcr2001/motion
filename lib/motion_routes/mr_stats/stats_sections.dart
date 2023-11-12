import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_screens/ms_report/report_front.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

// Section 1: Pie Chart
class YearPieChartDistributionAccountedUnaccounted extends StatelessWidget {
  final String accountedTotalHours;
  final String unAccountedTotalHours;

  const YearPieChartDistributionAccountedUnaccounted(
      {super.key,
      required this.accountedTotalHours,
      required this.unAccountedTotalHours});

  Widget _blockAndTextLegend(
      {required Color blockColor, required String legendName}) {
    return Row(
      children: [
        // block color
        Container(
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
              color: blockColor, borderRadius: BorderRadius.circular(2.8)),
          height: 15,
          width: 15,
        ),

        // legend name
        Text(legendName, style: AppTextStyle.legendTextStyling())
      ],
    );
  }

  // pie chart legend
  Widget _pieChartLegend() {
    return Container(
      margin: const EdgeInsets.only(left: 35),
      height: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // accounted legend
          _blockAndTextLegend(
              blockColor: AppColor.galleryPieChartAccountedColor,
              legendName: AppString.accountedTitle),

          // unaccounted legend
          _blockAndTextLegend(
              blockColor: AppColor.galleryPieChartUnaccountedColor,
              legendName: AppString.unAccountedTitle)
        ],
      ),
    );
  }

  // pie chart distribution of accounted and unaccounted values
  Widget _sectioOnePieChartDistributionAccountedUnaccounted() {
    // percentage calculations of accounted and unaccounted
    // distribution

    // accounted and unaccounted doubles
    double accountedDoubled = double.parse(accountedTotalHours);
    double unaccountedDoubled = double.parse(unAccountedTotalHours);

    double valueTotals = accountedDoubled + unaccountedDoubled;

    // converting both the accounted and unaccounted values to double percentage
    double accountedDoublePercent = (accountedDoubled / valueTotals) * 100;
    double unAccountedDoublePercent = (unaccountedDoubled / valueTotals) * 100;

    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10.0, bottom: 15.0),
      child: Row(
        children: [
          PieChartBuilder(sections: [
            // accounted proportions
            PieChartSectionData(
                titleStyle: AppTextStyle.pieChartTextStyling(),
                title: "${accountedDoublePercent.toStringAsFixed(1)}%",
                value: accountedDoublePercent,
                color: AppColor.galleryPieChartAccountedColor),

            // Unaccounted proportion
            PieChartSectionData(
                titleStyle: AppTextStyle.pieChartTextStyling(),
                title: "${unAccountedDoublePercent.toStringAsFixed(1)}%",
                value: unAccountedDoublePercent,
                color: AppColor.galleryPieChartUnaccountedColor)
          ]),
          _pieChartLegend()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sectioOnePieChartDistributionAccountedUnaccounted();
  }
}

// Section 2: Main Category Overview
class YearMainCategoryOveriew extends StatelessWidget {
  final String year;

  const YearMainCategoryOveriew({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    // get the screen heigh of the device
    final screenHeight = MediaQuery.of(context).size.height;

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

              logger.i(snapshotData);

              return Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                height: screenHeight * 0.33,
                child: Card(
                  child: ListView.builder(
                      itemCount: snapshotData!.length,
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

                        return ListTile(
                          leading: Text(
                            mainCatName,
                            style: AppTextStyle
                                .accountedAndUnaccountedGallaryStyle(),
                          ),
                          title: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColor.blueMainColor),
                              child: Center(
                                child: Text(
                                  convertedTotal,
                                  style: const TextStyle(
                                      color: AppColor.lightModeContentWidget,
                                      fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                          trailing: Text(convertedAverage,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }),
                ),
              );
            }
          });
    });
  }
}

// Section 2: A Year In Slices
class AYearInSummaryPieChartDistribution extends StatelessWidget {
  final String year;

  const AYearInSummaryPieChartDistribution({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
          builder: (context, user, main, child) {
        // user uid
        final String currentUser = user.userUid!;
        return PieChartDataMainCategoryDistribution(
          future: main.retrieveMainTotalTimeSpentSpecificDates(
              currentUser: currentUser,
              firstDay: "$year-01-01",
              lastDay: "$year-12-31"),
        );
      }),
    );
  }
}
