import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
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
      final currentUserUid = user.userUid;
      if (currentUserUid == null) {
        return userLoadingIndicator();
      }

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

              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              final borderColor = isDarkMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black12;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.025),
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: HeatMap(
                    startDate: DateTime(year, 1, 1),
                    endDate: DateTime(year, 12, 31),
                    fontSize: 11,
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

  Color _categoryColor(String categoryName) {
    switch (categoryName) {
      case "Education":
        return AppColor.educationPieChartColor;
      case "Work":
        return AppColor.workPieChartColor;
      case "Skills":
        return AppColor.skillsPieChartColor;
      case "Entertainment":
        return AppColor.entertainmentPieChartColor;
      case "Self Development":
        return AppColor.selfDevelopmentPieChartColor;
      case "Sleep":
        return AppColor.sleepPieChartColor;
      default:
        return AppColor.blueMainColor;
    }
  }

  Widget _categoryOverviewRow({
    required BuildContext context,
    required Map<String, dynamic> item,
    required double totalMinutes,
  }) {
    final mainCatName = item["mainCategoryName"]?.toString() ?? "N/A";
    final categoryTotal = (item["total"] as num?)?.toDouble() ?? 0.0;
    final average = (item["average"] as num?)?.toDouble() ?? 0.0;
    final progress = totalMinutes <= 0 ? 0.0 : categoryTotal / totalMinutes;
    final color = _categoryColor(mainCatName);
    final convertedTotal = convertMinutesToTime(categoryTotal);
    final convertedAverage = convertMinutesToHoursMonth(average);
    final numberOfDays = convertMinutesToDays(categoryTotal);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.black.withValues(alpha: 0.025);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.category_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainCatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 13,
                        fontweight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$numberOfDays | Avg $convertedAverage",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                convertedTotal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, sub, child) {
      // currently logged in user
      final currentUser = user.userUid;
      if (currentUser == null) {
        return userLoadingIndicator();
      }

      // if the total amount of time for the current
      // month is 0, then the summary page info
      // is displayed
      return FutureBuilder<List<Map<String, dynamic>>>(
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
              final snapshotData = snapshot.data ?? <Map<String, dynamic>>[];
              final totalMinutes = snapshotData.fold<double>(
                0.0,
                (sum, item) => sum + ((item["total"] as num?)?.toDouble() ?? 0),
              );

              if (snapshotData.isEmpty) {
                return Text(
                  "No main category data for $year.",
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                );
              }

              return Column(
                children: snapshotData
                    .map(
                      (item) => _categoryOverviewRow(
                        context: context,
                        item: item,
                        totalMinutes: totalMinutes,
                      ),
                    )
                    .toList(),
              );
            }
          });
    });
  }
}

// SECTION 4: HIGHEST TRACKED TIME

