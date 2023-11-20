import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
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
      padding: const EdgeInsets.only(left: 10, top: 10.0, bottom: 35.0),
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
    // get the screen height of the device
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

              return Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                height: screenHeight * 0.42,
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

                        // number of days
                        String numberOfDays =
                            convertMinutesToDays(singleItem["total"]);

                        return ListTile(
                          leading: Text(mainCatName,
                              style: AppTextStyle.leadingTextLTStyle()),
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
                              style: AppTextStyle.leadingStatsTextLTStyle()),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
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

// highest time tracked per subcategory
// for the entire
class YearHighestTrackedTimePerSubcategory extends StatelessWidget {
  final String year;

  const YearHighestTrackedTimePerSubcategory({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, sub, child) {
      final String currentUserUid = user.userUid!;

      return GridHighestTrackedSubcategory(
          future: sub.retrieveHighestTrackedTimePerSubcategory(
              currentUser: currentUserUid,
              firstDay: "$year-01-01",
              lastDay: "$year-12-31"));
    });
  }
}

// accounted and unaccounted distribution grouped
// bar graph
class GroupedPieChartAccountedUnaccounted extends StatelessWidget {
  final String year;

  const GroupedPieChartAccountedUnaccounted({super.key, required this.year});

  final double width = 10;

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 3,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColor.galleryPieChartAccountedColor,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: AppColor.galleryPieChartUnaccountedColor,
          width: width,
        ),
      ],
    );
  }

  // bottom titles representing the months
  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final Widget text = Text(
      titles[value.toInt() % titles.length],
      style: const TextStyle(
        color: Color(0xff7589a2),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10, //margin top
      child: text,
    );
  }

  // y-axis titles
  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    if (value == 0) {
      text = '0H';
    } else if (value == 12) {
      text = '12H';
    } else if (value == 24) {
      text = '24H';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 2,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
        builder: (context, user, main, child) {
      final String currentLoggedInUser = user.userUid!;

      return FutureBuilder(
          future: main.retrieveMonthDistibutionOfAccountedUnaccounted(
              currentUser: currentLoggedInUser, year: year),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final currentYearData = snapshot.data;

              List<BarChartGroupData> showingBarGroups = [];

              for (int i = 0; i < currentYearData!.length; i++) {
                // month
                final int month = int.parse(currentYearData[i]["Month"]) - 1;

                // accounted
                final double accounted = currentYearData[i]["Accounted"] / 24;
                final String accountedStringDpChange =
                    accounted.toStringAsFixed(2);
                final double accountedRounded =
                    double.parse(accountedStringDpChange);

                // unaccounted
                final double unaccounted =
                    currentYearData[i]["Unaccounted"] / 24;
                final String unaccountedStringDpChange =
                    unaccounted.toStringAsFixed(2);
                final double unaccountedRounded =
                    double.parse(unaccountedStringDpChange);

                final barGroup =
                    makeGroupData(month, accountedRounded, unaccountedRounded);

                showingBarGroups.add(barGroup);
              }

              logger.i(currentYearData);

              return AspectRatio(
                aspectRatio: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          makeTransactionsIcon(),
                          const SizedBox(
                            width: 38,
                          ),
                          specialSectionTitle(
                            mainTitleName: AppString.distributionTitle, 
                            elevatedTitleName: AppString.statusTitle),
                          
                        ],
                      ),
                    ),

                    // info about the distribution
                    const InfoToTheUser(
                      sectionInformation: 
                      AppString.infoAboutGroupedBarChart),

                    // grouped barchart
                    Expanded(
                        child: BarChart(BarChartData(
                            maxY: 30,
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: bottomTitles,
                                  reservedSize: 48,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 1,
                                getTitlesWidget: leftTitles,
                              )),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: showingBarGroups,
                            gridData: FlGridData(show: false)))),
                  ],
                ),
              );
            }
          });
    });
  }
}
