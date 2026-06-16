import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_stats/stats_graphs.dart';
import 'package:motion/motion_routes/mr_stats/stats_sections.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

// the summary report of the year the user clicks on
class YearsWorthOfSummaryStatitics extends StatelessWidget {
  final String year;
  final String accountedDays;
  final String accountedHours;
  final String unaccountedDays;
  final String unaccountedHours;

  const YearsWorthOfSummaryStatitics(
      {super.key,
      required this.year,
      required this.accountedDays,
      required this.accountedHours,
      required this.unaccountedDays,
      required this.unaccountedHours});

  @override
  Widget build(BuildContext context) {
    final sectionBuilders = <Widget Function()>[
      () => YearReviewSnapshot(
            year: year,
            accountedHours: accountedHours,
            unaccountedHours: unaccountedHours,
          ),
      () => _YearReportSection(
            title: "Consistency",
            subtitle: "Daily tracking intensity across $year",
            child: SummaryContributionHeatMap(year: int.parse(year)),
          ),
      () => _YearReportSection(
            title: AppString.accountedVsUnaccounterTitle,
            subtitle: "Tracked time compared with untracked time",
            child: Column(
              children: [
                YearTotalsAccountedUnaccountedBuilder(
                    accountedDays: accountedDays,
                    accountedHours: accountedHours,
                    unaccountedDays: unaccountedDays,
                    unaccountedHours: unaccountedHours),
                YearPieChartDistributionAccountedUnaccounted(
                    accountedTotalHours: accountedHours,
                    unAccountedTotalHours: unaccountedHours),
                GroupedPieChartAccountedUnaccounted
                    .groupedBarChartAccountedUnaccounted(year: year),
              ],
            ),
          ),
      () => _YearReportSection(
            title: AppString.mainCategoryOverview,
            subtitle: "Where your recorded time went",
            child: YearMainCategoryOveriew(year: year),
          ),
      () => _YearReportSection(
            title: AppString.aYearInSlicesTitle,
            subtitle: "Main category share for the full year",
            child: AYearInSummaryPieChartDistribution(year: year),
          ),
      () => _YearReportSection(
            title: AppString.chartingAYearInLinesTitle,
            subtitle: "How each main category changed month by month",
            child: LineChartOfMainCategoryYearlyDistribution(year: year),
          ),
      () => _YearReportSection(
            title: AppString.stackingAYearInLinesTitle,
            subtitle: "Monthly category mix at a glance",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StackedBarChartOfMainCategoryDistribution(year: year),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: chartLegend(),
                )
              ],
            ),
          ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(year),
      ),
      body: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        cacheExtent: 120,
        itemCount: sectionBuilders.length,
        itemBuilder: (context, index) => sectionBuilders[index](),
      ),
    );
  }
}

class _YearReportData {
  final double efsScore;
  final EfsBadge badge;
  final int totalXp;
  final int trackedDays;
  final double accountedHours;
  final double unaccountedHours;
  final String bestMonth;
  final int bestMonthXp;
  final String lowestMonth;
  final int lowestMonthXp;
  final String bestDay;
  final int bestDayXp;
  final String topMainCategory;
  final double topMainCategoryMinutes;
  final List<Map<String, dynamic>> topSubcategories;

  const _YearReportData({
    required this.efsScore,
    required this.badge,
    required this.totalXp,
    required this.trackedDays,
    required this.accountedHours,
    required this.unaccountedHours,
    required this.bestMonth,
    required this.bestMonthXp,
    required this.lowestMonth,
    required this.lowestMonthXp,
    required this.bestDay,
    required this.bestDayXp,
    required this.topMainCategory,
    required this.topMainCategoryMinutes,
    required this.topSubcategories,
  });

  double get accountedPercent {
    final totalHours = accountedHours + unaccountedHours;
    if (totalHours <= 0) return 0;
    return accountedHours / totalHours * 100;
  }

  double get averageXpPerTrackedDay {
    if (trackedDays <= 0) return 0;
    return totalXp / trackedDays;
  }
}

class YearReviewSnapshot extends StatelessWidget {
  final String year;
  final String accountedHours;
  final String unaccountedHours;

  const YearReviewSnapshot({
    super.key,
    required this.year,
    required this.accountedHours,
    required this.unaccountedHours,
  });

  Future<_YearReportData> _loadData({
    required String currentUser,
    required ExperiencePointTableProvider xp,
    required MainCategoryTrackerProvider main,
    required SubcategoryTrackerDatabaseProvider sub,
  }) async {
    return _loadYearReportData(
      year: year,
      currentUser: currentUser,
      xp: xp,
      main: main,
      sub: sub,
      accountedHours: accountedHours,
      unaccountedHours: unaccountedHours,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<UserUidProvider, ExperiencePointTableProvider,
        MainCategoryTrackerProvider, SubcategoryTrackerDatabaseProvider>(
      builder: (context, user, xp, main, sub, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return userLoadingIndicator();
        }

        return FutureBuilder<_YearReportData>(
          future: _loadData(
            currentUser: currentUser,
            xp: xp,
            main: main,
            sub: sub,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              final panelColor = isDarkMode
                  ? AppColor.darkModeContentWidget
                  : AppColor.lightModeContentWidget;
              final borderColor = isDarkMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black12;

              return Container(
                height: 460,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColor.blueMainColor,
                  ),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Text("Unable to load year snapshot");
            }

            final data = snapshot.data!;
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final panelColor = isDarkMode
                ? AppColor.darkModeContentWidget
                : AppColor.lightModeContentWidget;
            final borderColor =
                isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColor.accountedColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: AppColor.accountedColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$year Year Review",
                                  style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 18,
                                    fontweight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Badge Earned: ${data.badge.name}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 12,
                                    fontweight: FontWeight.normal,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _YearMetricTile(
                            label: "EFS",
                            value: data.efsScore.toStringAsFixed(1),
                            icon: Icons.speed_rounded,
                            color: AppColor.accountedColor,
                          ),
                          _YearMetricTile(
                            label: "Total XP",
                            value: data.totalXp.toString(),
                            icon: Icons.bolt_rounded,
                            color: Colors.orange,
                          ),
                          _YearMetricTile(
                            label: "Tracked Days",
                            value: "${data.trackedDays}/365",
                            icon: Icons.calendar_today_rounded,
                            color: AppColor.blueMainColor,
                          ),
                          _YearMetricTile(
                            label: "Accounted",
                            value:
                                "${data.accountedPercent.toStringAsFixed(1)}%",
                            icon: Icons.fact_check_rounded,
                            color: AppColor.educationPieChartColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _YearHighlightsSection(year: year, data: data),
              ],
            );
          },
        );
      },
    );
  }
}

class _YearHighlightsSection extends StatelessWidget {
  final String year;
  final _YearReportData data;

  const _YearHighlightsSection({
    required this.year,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _YearReportSection(
      title: "Year Highlights",
      subtitle: "What stood out most in $year",
      child: Column(
        children: [
          _YearInsightRow(
            icon: Icons.emoji_events_outlined,
            label: "Best Month",
            value: "${data.bestMonth} | ${data.bestMonthXp} XP",
            color: AppColor.accountedColor,
          ),
          _YearInsightRow(
            icon: Icons.trending_down_rounded,
            label: "Lowest Month",
            value: "${data.lowestMonth} | ${data.lowestMonthXp} XP",
            color: Colors.blueGrey,
          ),
          _YearInsightRow(
            icon: Icons.flash_on_rounded,
            label: "Best Day",
            value: "${_formatShortDate(data.bestDay)} | ${data.bestDayXp} XP",
            color: Colors.orange,
          ),
          _YearInsightRow(
            icon: Icons.category_outlined,
            label: "Top Main Category",
            value:
                "${data.topMainCategory} | ${convertMinutesToTime(data.topMainCategoryMinutes)}",
            color: AppColor.blueMainColor,
          ),
          if (data.topSubcategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...data.topSubcategories.map(
              (item) => _YearInsightRow(
                icon: Icons.label_outline_rounded,
                label: item["subcategoryName"]?.toString() ?? "N/A",
                value: convertMinutesToTime(
                  _readDouble(item["totalTimeSpent"]),
                ),
                color: Colors.deepPurple,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _YearInsightRow(
            icon: Icons.show_chart_rounded,
            label: "Average XP / tracked day",
            value: data.averageXpPerTrackedDay.toStringAsFixed(1),
            color: AppColor.selfDevelopmentPieChartColor,
          ),
        ],
      ),
    );
  }
}

class _YearReportSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _YearReportSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 11,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _YearMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _YearMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 54) / 2,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 14,
                      fontweight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearInsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _YearInsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<_YearReportData> _loadYearReportData({
  required String year,
  required String currentUser,
  required ExperiencePointTableProvider xp,
  required MainCategoryTrackerProvider main,
  required SubcategoryTrackerDatabaseProvider sub,
  required String accountedHours,
  required String unaccountedHours,
}) async {
  final firstDay = "$year-01-01";
  final lastDay = "$year-12-31";

  final efsScoreFuture = xp.retrieveYearExperiencePointsEfficiencyScore(
    currentUser: currentUser,
    currentYear: year,
  );
  final totalXpFuture = xp.retrieveTotalXP(
    currentUser: currentUser,
    isEntire: false,
    year: year,
  );
  final trackedDaysFuture = xp.retrieveYearExperiencePointDays(
    currentUser: currentUser,
    year: year,
  );
  final bestMonthsFuture = xp.retrieveMostAndLeastProductiveMonths(
    getMostProductiveMonth: true,
    currentUser: currentUser,
    year: year,
  );
  final lowestMonthsFuture = xp.retrieveMostAndLeastProductiveMonths(
    getMostProductiveMonth: false,
    currentUser: currentUser,
    year: year,
  );
  final bestDaysFuture = xp.retrieveMostAndLeastProductiveDays(
    currentUser: currentUser,
    firstDay: firstDay,
    lastDay: lastDay,
    getMostProductiveDay: true,
  );
  final mainCategoriesFuture = sub.retrieveMonthTotalAndAverage(
    currentUser,
    firstDay,
    lastDay,
    false,
  );
  final topSubcategoriesFuture = main.retrieveTopSubcategoriesForPeriod(
    currentUser: currentUser,
    firstDay: firstDay,
    lastDay: lastDay,
    limit: 3,
  );

  final efsScore = await efsScoreFuture;
  final totalXp = await totalXpFuture;
  final trackedDays = await trackedDaysFuture;
  final bestMonths = await bestMonthsFuture;
  final lowestMonths = await lowestMonthsFuture;
  final bestDays = await bestDaysFuture;
  final mainCategories = await mainCategoriesFuture;
  final topSubcategories = await topSubcategoriesFuture;

  final topMainCategory =
      mainCategories.isEmpty ? const <String, dynamic>{} : mainCategories.first;
  final bestMonth = bestMonths.isEmpty ? const <String, dynamic>{} : bestMonths.first;
  final lowestMonth =
      lowestMonths.isEmpty ? const <String, dynamic>{} : lowestMonths.first;
  final bestDay = bestDays.isEmpty ? const <String, dynamic>{} : bestDays.first;

  return _YearReportData(
    efsScore: efsScore,
    badge: EfsBadgePolicy.badgeForScore(efsScore),
    totalXp: totalXp,
    trackedDays: trackedDays,
    accountedHours: _readDouble(accountedHours),
    unaccountedHours: _readDouble(unaccountedHours),
    bestMonth: bestMonth["month"]?.toString() ?? "N/A",
    bestMonthXp: _readInt(bestMonth["most_productive"]),
    lowestMonth: lowestMonth["month"]?.toString() ?? "N/A",
    lowestMonthXp: _readInt(lowestMonth["totalLeastXP"]),
    bestDay: bestDay["date"]?.toString() ?? "N/A",
    bestDayXp: _readInt(bestDay["most_productive"]),
    topMainCategory: topMainCategory["mainCategoryName"]?.toString() ?? "N/A",
    topMainCategoryMinutes: _readDouble(topMainCategory["total"]),
    topSubcategories: topSubcategories,
  );
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? "") ?? 0.0;
}

int _readInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

String _formatShortDate(String value) {
  final parts = value.split("-");
  if (parts.length != 3) return value;
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  final month = int.tryParse(parts[1]) ?? 1;
  final day = int.tryParse(parts[2]) ?? 1;
  final monthIndex = (month - 1).clamp(0, 11).toInt();
  final monthName = months[monthIndex];
  return "$monthName $day";
}

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String gallaryYear;
  final VoidCallback onTap;

  const AnnualGallaryBuilder(
      {super.key, required this.gallaryYear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final tileColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(9.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: AppColor.blueMainColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColor.blueMainColor,
                      size: 16,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        gallaryYear,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.sectionTitleTextStyle(
                          fontsize: 16,
                        ).copyWith(color: AppColor.blueMainColor),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// yearly accounted and unaccounted totals
class YearTotalsAccountedUnaccountedBuilder extends StatelessWidget {
  final String accountedDays;
  final String accountedHours;
  final String unaccountedDays;
  final String unaccountedHours;

  const YearTotalsAccountedUnaccountedBuilder(
      {super.key,
      required this.accountedDays,
      required this.accountedHours,
      required this.unaccountedDays,
      required this.unaccountedHours});

  // function that builds out the accounted and unaccounted
  // sections
  Widget _onePieceData(
      {required String sectionName,
      required String sectionDays,
      required String sectionHours,
      required TextStyle sectionDataValueStyle,
      required Color lineChartIconColor}) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // section title
          Text(
            sectionName,
            style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),
          ),

          // days
          Row(
            children: [
              Icon(
                Icons.line_axis_rounded,
                size: 30,
                color: lineChartIconColor,
              ),
              Column(
                children: [
                  Text(
                    "$sectionDays days",
                    style: sectionDataValueStyle,
                  ),

                  // hours
                  Text(
                    "$sectionHours hours",
                    style: sectionDataValueStyle,
                  ),
                ],
              ),
            ],
          ),

          // section divider
          const SizedBox(
            width: 100,
            child: Divider(
              thickness: 2,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // accounted with data
          _onePieceData(
              sectionName: AppString.totalAccountedTitle,
              sectionDays: accountedDays,
              sectionHours: accountedHours,
              sectionDataValueStyle: AppTextStyle.subSectionTextStyle(fontsize: 12),
              lineChartIconColor: Colors.green),

          // unaccounted with data
          _onePieceData(
              sectionName: AppString.totalUnaccountedTitle,
              sectionDays: unaccountedDays,
              sectionHours: unaccountedHours,
              sectionDataValueStyle: AppTextStyle.subSectionTextStyle(fontsize: 12),
              lineChartIconColor: Colors.red),
        ],
      ),
    );
  }
}

Widget makeTransactionsIcon() {
  const width = 4.5;
  const space = 3.5;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: width,
        height: 10,
        color: const Color(0xFFA9A9A9),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 28,
        color: const Color(0xFF909090),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 42,
        color: const Color(0xFFCFCFCF),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 28,
        color: const Color(0xFF909090),
      ),
      const SizedBox(
        width: space,
      ),
      Container(
        width: width,
        height: 10,
        color: const Color(0xFFA9A9A9),
      ),
    ],
  );
}
