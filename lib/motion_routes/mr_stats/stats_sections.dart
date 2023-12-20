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

// chart text style
TextStyle style = AppTextStyle.chartLabelTextStyle();

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
                      physics: const NeverScrollableScrollPhysics(),
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
    TextStyle style = AppTextStyle.chartLabelTextStyle();
    String text;
    if (value == 0) {
      text = '0';
    } else if (value == 15) {
      text = '15';
    } else if (value == 30) {
      text = '31';
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
                        sectionInformation: AppString.infoAboutGroupedBarChart),

                    const SizedBox(
                      height: 25,
                    ),

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

// section 5: line plot of main category distributions

// chart legends
Widget chartLegend() {
  return // piechart legend
      Container(
    margin: const EdgeInsets.only(top: 40),
    height: 60,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // first row legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // sleep
            mainCategoryPieChartLegend(
                color: AppColor.sleepPieChartColor,
                mainCategoryName: AppString.sleepMainCategory),

            // education
            mainCategoryPieChartLegend(
                color: AppColor.educationPieChartColor,
                mainCategoryName: AppString.educationMainCategory),

            // skills
            mainCategoryPieChartLegend(
                color: AppColor.skillsPieChartColor,
                mainCategoryName: AppString.skillMainCategory),
          ],
        ),
        // second row legends
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // entertainment
            mainCategoryPieChartLegend(
                color: AppColor.entertainmentPieChartColor,
                mainCategoryName: AppString.entertainmentMainCategory),

            // personal growth
            mainCategoryPieChartLegend(
                color: AppColor.personalGrowthPieChartColor,
                mainCategoryName: AppString.personalGrowthMainCategory)
          ],
        )
      ],
    ),
  );
}


// the function below generates a line chart 
// 
class LineChartOfMainCategoryYearlyDistribution extends StatelessWidget {
  final String year;

  const LineChartOfMainCategoryYearlyDistribution(
      {super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
        builder: (context, user, main, child) {
      final String currentUser = user.userUid!;

      return FutureBuilder(
          future: main.retrieveYearlyTotalsForAllMainCatgories(
              currentUser: currentUser, year: year),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final currentYearData = snapshot.data;

              // Create LineChartBarData instances outside the loop
              List<LineChartBarData> lineBarData = [
                createLineChartBarData(
                  data: currentYearData!,
                  getCategoryValues: (data) => data["education"],
                  color: AppColor.educationPieChartColor,
                ),
                createLineChartBarData(
                  data: currentYearData,
                  getCategoryValues: (data) => data["skills"],
                  color: AppColor.skillsPieChartColor,
                ),
                createLineChartBarData(
                  data: currentYearData,
                  getCategoryValues: (data) => data["entertainment"],
                  color: AppColor.entertainmentPieChartColor,
                ),
                createLineChartBarData(
                  data: currentYearData,
                  getCategoryValues: (data) => data["personalGrowth"],
                  color: AppColor.personalGrowthPieChartColor,
                ),
                createLineChartBarData(
                  data: currentYearData,
                  getCategoryValues: (data) => data["sleep"],
                  color: AppColor.sleepPieChartColor,
                ),
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // chart title
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, bottom: 20, top: 15),
                          child: Row(
                            children: [
                              // chart icon
                              makeTransactionsIcon(),

                              // title name
                              specialSectionTitle(
                                  mainTitleName: AppString.distributionTitle2,
                                  elevatedTitleName:
                                      AppString.mainCategoryTitle)
                            ],
                          ),
                        ),

                        // information to the user
                        const InfoToTheUser(
                            sectionInformation:
                                AppString.infoAboutLineChartData),

                        // line chart
                        SizedBox(
                          height: 300,
                          child: LineChart(LineChartData(
                            lineTouchData: _LineChartBuilder().lineTouchData1,
                            gridData: _LineChartBuilder().gridData,
                            titlesData: _LineChartBuilder().titlesData1,
                            borderData: _LineChartBuilder().borderData,
                            lineBarsData: lineBarData,
                            minX: 1,
                            maxX: 13,
                            maxY: 400,
                            minY: 0,
                          )),
                        ),

                        // legend
                        chartLegend()
                      ],
                    ),
                  ),
                ),
              );
            }
          });
    });
  }
}

// Function to create LineChartBarData
LineChartBarData createLineChartBarData({
  required List<Map<String, dynamic>> data,
  required double Function(Map<String, dynamic>) getCategoryValues,
  required Color color,
}) {
  return LineChartBarData(
    isCurved: false,
    color: color,
    barWidth: 3,
    isStrokeCapRound: true,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: List.generate(
      data.length,
      (index) {
        final int month = int.parse(data[index]["Month"]);
        final double categoryValue = getCategoryValues(data[index]);

        return FlSpot(month.toDouble(), categoryValue);
      },
    ),
  );
}

// bottom line chart titles
// bottom titles representing the months
Widget bottomTitleWidgets(double value, TitleMeta meta) {
  Widget text;
  switch (value.toInt()) {
    case 1:
      text = Text('Jan', style: style);
      break;
    case 2:
      text = Text('Feb', style: style);
      break;
    case 3:
      text = Text('Mar', style: style);
      break;
    case 4:
      text = Text('Apr', style: style);
      break;
    case 5:
      text = Text('May', style: style);
      break;
    case 6:
      text = Text('Jun', style: style);
      break;
    case 7:
      text = Text('Jul', style: style);
      break;
    case 8:
      text = Text('Aug', style: style);
      break;
    case 9:
      text = Text('Sep', style: style);
      break;
    case 10:
      text = Text('Oct', style: style);
      break;
    case 11:
      text = Text('Nov', style: style);
      break;
    case 12:
      text = Text('Dec', style: style);
      break;
    default:
      text = const Text('');
      break;
  }

  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 12,
    child: text,
  );
}

class _LineChartBuilder {
  // line chart touch gestures
  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.8),
        ),
      );

  // do not show the grid lines
  FlGridData get gridData => FlGridData(show: false);

  // titles to display on screen
  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  // vertical y-axis titles
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    TextStyle style = AppTextStyle.chartLabelTextStyle();
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0h';
        break;
      case 50:
        text = '50h';
        break;
      case 100:
        text = '100h';
        break;
      case 150:
        text = '150h';
        break;
      case 200:
        text = '200h';
        break;
      case 250:
        text = '250h';
        break;
      case 300:
        text = '300h';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 35,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  // border styling and configuration
  FlBorderData get borderData => FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(width: 1.5),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );
}

// Section 6: Stack Bar Chart

class StackedBarChartOfMainCategoryDistribution extends StatelessWidget {
  final String year;

  const StackedBarChartOfMainCategoryDistribution(
      {super.key, required this.year});

  // space between bars
  final double betweenSpace = 15;

  // bar widths
  final double barWidthInd = 10.0;

// function to created stack bar chart
  BarChartGroupData generateGroupData(
    int x,
    double education,
    double skills,
    double entertainment,
    double personalGrowth,
    double sleep,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        // education bar
        BarChartRodData(
          fromY: 0,
          toY: education,
          color: AppColor.educationPieChartColor,
          width: barWidthInd,
        ),

        // skills bar
        BarChartRodData(
          fromY: education + betweenSpace,
          toY: education + betweenSpace + skills,
          color: AppColor.skillsPieChartColor,
          width: barWidthInd,
        ),

        // entertainment bar
        BarChartRodData(
          fromY: education + betweenSpace + skills + betweenSpace,
          toY: education + betweenSpace + skills + betweenSpace + entertainment,
          color: AppColor.entertainmentPieChartColor,
          width: barWidthInd,
        ),

        // personal growth bar
        BarChartRodData(
          fromY: education +
              betweenSpace +
              skills +
              betweenSpace +
              entertainment +
              betweenSpace,
          toY: education +
              betweenSpace +
              skills +
              betweenSpace +
              entertainment +
              betweenSpace +
              personalGrowth,
          color: AppColor.personalGrowthPieChartColor,
          width: barWidthInd,
        ),

        // sleep bar
        BarChartRodData(
          fromY: education +
              betweenSpace +
              skills +
              betweenSpace +
              entertainment +
              betweenSpace +
              personalGrowth +
              betweenSpace,
          toY: education +
              betweenSpace +
              skills +
              betweenSpace +
              entertainment +
              betweenSpace +
              personalGrowth +
              betweenSpace +
              sleep,
          color: AppColor.sleepPieChartColor,
          width: barWidthInd,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
        builder: (context, user, main, child) {
      final String currentUser = user.userUid!;

      return FutureBuilder(
          future: main.retrieveYearlyTotalsForAllMainCatgories(
              currentUser: currentUser, year: year),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final currentYearData = snapshot.data;

              List<BarChartGroupData> stackBarGroups = [];

              for (int i = 0; i < currentYearData!.length; i++) {
                // month value
                final int month = int.parse(currentYearData[i]["Month"]);

                // education
                final double educationValue = currentYearData[i]["education"];

                // skills
                final double skillValue = currentYearData[i]["skills"];

                // entertainment
                final double entertainmentValue =
                    currentYearData[i]["entertainment"];

                // personalGrowth
                final double personalGrowthValue =
                    currentYearData[i]["personalGrowth"];

                // sleep
                final double sleepValue = currentYearData[i]["sleep"];

                final stackBarGroup = generateGroupData(
                    month,
                    educationValue,
                    skillValue,
                    entertainmentValue,
                    personalGrowthValue,
                    sleepValue);

                stackBarGroups.add(stackBarGroup);
              }
              return Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // stacked bar chart
                      Expanded(
                          child: BarChart(BarChartData(
                              alignment: BarChartAlignment.spaceBetween,
                              groupsSpace: 2,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(),
                                rightTitles: AxisTitles(),
                                topTitles: AxisTitles(),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: bottomTitleWidgets,
                                    reservedSize: 30,
                                  ),
                                ),
                              ),
                              barTouchData: BarTouchData(enabled: false),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                              barGroups: stackBarGroups)))
                    ],
                  ),
                ),
              );
            }
          });
    });
  }
}