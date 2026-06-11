import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
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

  Widget _summaryHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.donut_large_rounded,
            color: AppColor.blueMainColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppString.mainCategoryTotalTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 15,
                  fontweight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "All-time category distribution",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColor.accountedColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColor.accountedColor.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            "Lifetime",
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10.5,
              fontweight: FontWeight.w800,
              color: AppColor.accountedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _subcategoryViewTotals(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const SubTotalsPage(),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColor.blueMainColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.view_list_rounded,
                    color: AppColor.blueMainColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    AppString.viewSubcategoryTotalsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12.5,
                      fontweight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pieChartHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: AppColor.selfDevelopmentPieChartColor
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              color: AppColor.selfDevelopmentPieChartColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: specialSectionTitle(
              mainTitleName: AppString.entireLifeTitle,
              elevatedTitleName: AppString.entireLifeInSlicesTitle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 22),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryHeader(context),
          const SizedBox(height: 14),
          const EntireDataStatistic(),
          _subcategoryViewTotals(context),
          _pieChartHeader(context),
          const AnalyticsMainCategoryDistributionPieChart(),
        ],
      ),
    );
  }
}

class _CategorySummaryItem {
  final String name;
  final String initials;
  final String totalHours;
  final String totalDays;
  final String average;
  final Color accentColor;
  final IconData icon;

  const _CategorySummaryItem({
    required this.name,
    required this.initials,
    required this.totalHours,
    required this.totalDays,
    required this.average,
    required this.accentColor,
    required this.icon,
  });
}

List<_CategorySummaryItem> _categorySummaryItems(
  Map<String, dynamic> totals,
) {
  String value(String key, String suffix) {
    return "${totals[key] ?? 0} $suffix";
  }

  return [
    _CategorySummaryItem(
      name: AppString.sleepMainCategory,
      initials: "SP",
      totalHours: value("sleepHours", "HRS"),
      totalDays: value("sleepDays", "days"),
      average: value("sleepAverage", "hrs/day"),
      accentColor: AppColor.sleepPieChartColor,
      icon: Icons.bedtime_rounded,
    ),
    _CategorySummaryItem(
      name: AppString.educationMainCategory,
      initials: "ED",
      totalHours: value("educationHours", "HRS"),
      totalDays: value("educationDays", "days"),
      average: value("educationAverage", "hrs/day"),
      accentColor: AppColor.educationPieChartColor,
      icon: Icons.school_rounded,
    ),
    _CategorySummaryItem(
      name: AppString.workMainCategory,
      initials: "WK",
      totalHours: value("workHours", "HRS"),
      totalDays: value("workDays", "days"),
      average: value("workAverage", "hrs/day"),
      accentColor: AppColor.workPieChartColor,
      icon: Icons.work_rounded,
    ),
    _CategorySummaryItem(
      name: AppString.skillMainCategory,
      initials: "SK",
      totalHours: value("skillHours", "HRS"),
      totalDays: value("skillDays", "days"),
      average: value("skillAverage", "hrs/day"),
      accentColor: AppColor.skillsPieChartColor,
      icon: Icons.psychology_rounded,
    ),
    _CategorySummaryItem(
      name: AppString.entertainmentMainCategory,
      initials: "ET",
      totalHours: value("entertainmentHours", "HRS"),
      totalDays: value("entertainmentDays", "days"),
      average: value("entertainmentAverage", "hrs/day"),
      accentColor: AppColor.entertainmentPieChartColor,
      icon: Icons.movie_filter_rounded,
    ),
    _CategorySummaryItem(
      name: AppString.selfDevelopmentMainCategory,
      initials: "PG",
      totalHours: value("pgHours", "HRS"),
      totalDays: value("pgDays", "days"),
      average: value("pgAverage", "hrs/day"),
      accentColor: AppColor.selfDevelopmentPieChartColor,
      icon: Icons.self_improvement_rounded,
    ),
  ];
}

Widget _categoryLoadingState() {
  return const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: CircularProgressIndicator(
        color: AppColor.blueMainColor,
      ),
    ),
  );
}

Widget _categoryErrorState(Object? error) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      'Error: $error',
      style: AppTextStyle.subSectionTextStyle(
        fontsize: 12,
        fontweight: FontWeight.normal,
        color: Colors.redAccent,
      ),
    ),
  );
}

Widget _categoryEmptyState() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Text(
        AppString.informationAboutNoData,
        textAlign: TextAlign.center,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 12,
          fontweight: FontWeight.normal,
          color: Colors.blueGrey,
        ),
      ),
    ),
  );
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
      final userUid = user.userUid;

      if (userUid == null) {
        return userLoadingIndicator();
      }

      return CachedFutureBuilder<List<Map<String, dynamic>>>(
          cacheKey: 'category-summary-report-$userUid-${main.refreshKey}',
          futureFactory: () =>
              main.retrieveAllMainCategoryTotals(currentUser: userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _categoryLoadingState();
            } else if (snapshot.hasError) {
              return _categoryErrorState(snapshot.error);
            } else {
              final allMainCategoryTotals = snapshot.data ?? [];

              if (allMainCategoryTotals.isEmpty) {
                return _categoryEmptyState();
              }

              final categoryItems =
                  _categorySummaryItems(allMainCategoryTotals.first);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 360;
                  final cardWidth = useTwoColumns
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in categoryItems)
                        _CategoryBuilder(
                          item: item,
                          width: cardWidth,
                        ),
                    ],
                  );
                },
              );
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
class _CategoryBuilder extends StatelessWidget {
  final _CategorySummaryItem item;
  final double width;

  const _CategoryBuilder({
    super.key,
    required this.item,
    required this.width,
  });

  Widget _smallMetric({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Text(
        "$label\n$value",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 10.5,
          fontweight: FontWeight.w700,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final tileColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.white.withValues(alpha: 0.72);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12.5,
                          fontweight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.initials,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10,
                        fontweight: FontWeight.w800,
                        color: item.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.totalHours,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.sectionTitleTextStyle(
                    fontsize: 16,
                  ).copyWith(color: item.accentColor),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _smallMetric(label: "Days", value: item.totalDays),
                    const SizedBox(width: 6),
                    _smallMetric(label: "Avg", value: item.average),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
