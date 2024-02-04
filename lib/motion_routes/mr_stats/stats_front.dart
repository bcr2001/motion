import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../motion_reusable/general_reuseable.dart';
import '../../motion_themes/mth_app/app_strings.dart';

// Main Categories Summary
// this section displays both the
// entire data summary and pie chart
class CategorySummaryReport extends StatelessWidget {
  const CategorySummaryReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      children: [
        // entire data
        const EntireDataStatistic(),

        // Pie Chart Title
        specialSectionTitle(
            mainTitleName: AppString.entireLifeTitle,
            elevatedTitleName: AppString.entireLifeInSlicesTitle),

        // pie chart
        const AnalyticsMainCategoryDistributionPieChart()
      ],
    ));
  }
}

// This section displays a summary of the main categories, including their
// distribution by days, hours, and daily average for the entire
// dataset collected.
class EntireDataStatistic extends StatelessWidget {
  const EntireDataStatistic({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MainCategoryTrackerProvider, UserUidProvider>(
        builder: (context, main, user, child) {
      // current user uid
      final String userUid = user.userUid!;

      return FutureBuilder(
          future: main.retrieveAllMainCategoryTotals(currentUser: userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final allMainCategoryTotals = snapshot.data;

              logger.i(allMainCategoryTotals);

              return Container(
                  margin: const EdgeInsets.all(10.0),
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // sleep
                          CategoryBuilder(
                            mainCategoryName: AppString.sleepMainCategory,
                            galleryInitials: "SP",
                            totalHours:
                                "${allMainCategoryTotals![0]["sleepHours"]} HRS",
                            totalDays:
                                "${allMainCategoryTotals[0]["sleepDays"]} days",
                            average:
                                "${allMainCategoryTotals[0]["sleepAverage"]} hrs/day",
                          ),

                          // Education Information
                          CategoryBuilder(
                            mainCategoryName: AppString.educationMainCategory,
                            galleryInitials: "ED",
                            totalHours:
                                "${allMainCategoryTotals[0]["educationHours"]} HRS",
                            totalDays:
                                "${allMainCategoryTotals[0]["educationDays"]} days",
                            average:
                                "${allMainCategoryTotals[0]["educationAverage"]} hrs/day",
                          ),

                          // Skills Information
                          CategoryBuilder(
                            mainCategoryName: AppString.skillMainCategory,
                            galleryInitials: "SK",
                            totalHours:
                                "${allMainCategoryTotals[0]["skillHours"]} HRS",
                            totalDays:
                                "${allMainCategoryTotals[0]["skillDays"]} days",
                            average:
                                "${allMainCategoryTotals[0]["skillAverage"]} hrs/day",
                          ),

                          // Entertainment Information
                          CategoryBuilder(
                            mainCategoryName:
                                AppString.entertainmentMainCategory,
                            galleryInitials: "ET",
                            totalHours:
                                "${allMainCategoryTotals[0]["entertainmentHours"]} HRS",
                            totalDays:
                                "${allMainCategoryTotals[0]["entertainmentDays"]} days",
                            average:
                                "${allMainCategoryTotals[0]["entertainmentAverage"]} hrs/day",
                          ),

                          // Self Development Information
                          CategoryBuilder(
                            mainCategoryName:
                                AppString.selfDevelopmentMainCategory,
                            galleryInitials: "PG",
                            totalHours:
                                "${allMainCategoryTotals[0]["pgHours"]} HRS",
                            totalDays:
                                "${allMainCategoryTotals[0]["pgDays"]} days",
                            average:
                                "${allMainCategoryTotals[0]["pgAverage"]} hrs/day",
                          ),
                        ],
                      )));
            }
          });
    });
  }
}

// Main Category Gallery Builder
// This class is responsible for creating the gallery that displays detailed
// information for each main category.
// It handles the construction and layout of the gallery, ensuring that each
// main category is presented effectively.
class CategoryBuilder extends StatelessWidget {
  final String mainCategoryName;
  final String galleryInitials;
  final String totalHours;
  final String totalDays;
  final String average;

  const CategoryBuilder(
      {super.key,
      required this.mainCategoryName,
      required this.galleryInitials,
      required this.totalHours,
      required this.totalDays,
      required this.average});

  // days and average text layout
  Widget _daysAndAverageTextLayout(bool isdays) {
    return isdays
        ? Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Text(
              totalDays,
              style: AppTextStyle.daysTextStyleCSR(),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(right: 50),
            child: Text(
              average,
              style: AppTextStyle.daysTextStyleCSR(),
            ),
          );
  }

  // hours text layour
  Widget _hoursTextLayout() {
    return Text(
      totalHours,
      style: AppTextStyle.hoursTextStyleCSR(),
    );
  }

  // hours, days, and average
  Widget _hoursDaysAverage() {
    return Column(
      children: [
        // days
        _daysAndAverageTextLayout(true),

        // hours
        _hoursTextLayout(),

        // average
        _daysAndAverageTextLayout(false)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // main category name and image
          Text(
            mainCategoryName,
            style: AppTextStyle.subSectionTitleTextStyle(),
          ),

          // hours, days, and average
          Center(child: _hoursDaysAverage()),

          // main category image representation
          Align(
              alignment: Alignment.bottomRight,
              child: Text(
                galleryInitials,
                style: AppTextStyle.statsElementTextStyle(),
              )),

          // gallery divider
          const SizedBox(width: 120, child: Divider())
        ],
      ),
    );
  }
}
