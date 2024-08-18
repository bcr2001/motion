import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_screens/ms_subcategory/sub_totals.dart';
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

  // button that takes users to the subcategory totals page
  // page that contains the all time totals for the subcategory
  Widget _subcategoryViewTotals(context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 12, bottom: 15),
      child: GestureDetector(
        onTap: (() {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const SubTotalsPage()));
        }),
        child: Row(
          children: [
            // view subcategory totals
            Text(
              AppString.viewSubcategoryTotalsTitle,
              style: AppTextStyle.mainCategoryTotalTitle(),
            ),

            // click icon
            AvatarGlow(
              glowColor: AppColor.accountedColor,
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.ads_click_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Category Totals Title
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 12),
          child: Text(
            AppString.mainCategoryTotalTitle,
            style: AppTextStyle.mainCategoryTotalTitle(),
          ),
        ),
        // entire data
        const EntireDataStatistic(),

        // view subcategory totals route
        _subcategoryViewTotals(context),

        // Pie Chart Title
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              makeTransactionsIcon(),
              const SizedBox(
                width: 10,
              ),
              specialSectionTitle(
                  mainTitleName: AppString.entireLifeTitle,
                  elevatedTitleName: AppString.entireLifeInSlicesTitle),
            ],
          ),
        ),

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
  final double? dividerWidth;

  const CategoryBuilder({
    super.key,
    required this.mainCategoryName,
    required this.galleryInitials,
    required this.totalHours,
    required this.totalDays,
    required this.average,
    this.dividerWidth = 120, // Default value
  });

  // days and average text layout
  Widget _daysAndAverageTextLayout(bool isDays) {
    return Padding(
      padding: isDays
          ? const EdgeInsets.only(left: 50)
          : const EdgeInsets.only(right: 50),
      child: Text(
        isDays ? totalDays : average,
        style: AppTextStyle.subSectionTextStyle(
            fontsize: 12, color: AppColor.tileBackgroundColor),
      ),
    );
  }

  // hours text layout
  Widget _hoursTextLayout() {
    return Text(
      totalHours,
      style: AppTextStyle.sectionTitleTextStyle(fontsize: 20),
    );
  }

  // hours, days, and average
  Widget _hoursDaysAverage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // days
        _daysAndAverageTextLayout(true),

        // hours
        _hoursTextLayout(),

        // average
        _daysAndAverageTextLayout(false),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // main category name and image
          Text(
            mainCategoryName,
            style:
                AppTextStyle.subSectionTextStyle(fontweight: FontWeight.normal),
          ),

          // hours, days, and average
          Center(child: _hoursDaysAverage()),

          // main category image representation
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              galleryInitials,
              style: AppTextStyle.subSectionTextStyle(fontsize: 11.5),
            ),
          ),

          // gallery divider
          SizedBox(
            width: dividerWidth,
            child: const Divider(),
          ),
        ],
      ),
    );
  }
}
