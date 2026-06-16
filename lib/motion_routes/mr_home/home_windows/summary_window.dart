import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_screens/ms_streak/streak_detail_page.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

// Where the summary for the month is displayed
// button toggles (Subcategory and Category)
// total time accounted for the current month
class SummaryWindow extends StatelessWidget {
  const SummaryWindow({super.key});

  void _showSummaryDialog({
    required BuildContext context,
    required String title,
    required bool isSubcategory,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final panelColor = isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;
        final borderColor =
            isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
        final accentColor = isSubcategory
            ? AppColor.blueMainColor
            : AppColor.selfDevelopmentPieChartColor;
        final icon = isSubcategory
            ? Icons.view_list_rounded
            : Icons.donut_large_rounded;

        return Dialog(
          backgroundColor: panelColor,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 590),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          icon,
                          color: accentColor,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 16,
                                fontweight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Totals and daily averages",
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
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: _dialogSummaryList(
                      isSubcategory: isSubcategory,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12.5,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.85),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _summaryAccentForName(String name) {
    if (name == AppString.educationMainCategory) {
      return AppColor.educationPieChartColor;
    }
    if (name == AppString.workMainCategory) {
      return AppColor.workPieChartColor;
    }
    if (name == AppString.skillMainCategory) {
      return AppColor.skillsPieChartColor;
    }
    if (name == AppString.entertainmentMainCategory) {
      return AppColor.entertainmentPieChartColor;
    }
    if (name == AppString.selfDevelopmentMainCategory) {
      return AppColor.selfDevelopmentPieChartColor;
    }
    if (name == AppString.sleepMainCategory) {
      return AppColor.sleepPieChartColor;
    }

    return AppColor.blueMainColor;
  }

  Widget _dialogSummaryRow({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String columnName,
    required bool isSubcategory,
    required int index,
  }) {
    final name = item[columnName].toString();
    final total = convertMinutesToTime(item["total"]);
    final average = convertMinutesToHoursOnly(item["average"]);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isSubcategory ? AppColor.blueMainColor : _summaryAccentForName(name);
    final rowColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 13,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Avg $average',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total,
            textAlign: TextAlign.right,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12.5,
              fontweight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSummaryList({
    required bool isSubcategory,
  }) {
    return Consumer3<SubcategoryTrackerDatabaseProvider, UserUidProvider,
        FirstAndLastDay>(builder: (context, sub, user, day, child) {
      final currentUser = user.userUid;
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 100, height: 30);
      }

      final columnName = isSubcategory ? "subcategoryName" : "mainCategoryName";
      final cachePrefix = isSubcategory ? "dialog-subcategory" : "dialog-main";

      return CachedFutureBuilder<List<Map<String, dynamic>>>(
        cacheKey:
            '$cachePrefix-$currentUser-${day.firstDay}-${day.lastDay}-${sub.refreshKey}',
        futureFactory: () => sub.retrieveMonthTotalAndAverage(
          currentUser,
          day.firstDay,
          day.lastDay,
          isSubcategory,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildShimmerProgress();
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                "No tracked time yet",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 13,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            );
          }

          final totalMinutes = items.fold<double>(
            0,
            (sum, item) => sum + ((item["total"] as num?)?.toDouble() ?? 0),
          );

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryMetric(
                        label: isSubcategory ? "Subcategories" : "Categories",
                        value: items.length.toString(),
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: Colors.blueGrey.withValues(alpha: 0.18),
                    ),
                    Expanded(
                      child: _summaryMetric(
                        label: "Tracked",
                        value: convertMinutesToTime(totalMinutes),
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  radius: const Radius.circular(10),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) => _dialogSummaryRow(
                      context: context,
                      item: items[index],
                      columnName: columnName,
                      isSubcategory: isSubcategory,
                      index: index,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 10.5,
            fontweight: FontWeight.normal,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 13,
            fontweight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 85.0),
      child: Consumer3<UserUidProvider, FirstAndLastDay,
              MainCategoryTrackerProvider>(
          builder: (context, user, day, main, child) {
        // currently logged in user
        final currentUser = user.userUid;

        if (currentUser == null) {
          return userLoadingIndicator();
        }
    
        // first and last day of the current month
        final String firstDayOfMonth = day.firstDay;
        final String lastDayOfMonth = day.lastDay;
    
        // if the total amount of time for the current
        // month is 0, then the summary page info
        // is displayed
        return CachedFutureBuilder<double>(
            cacheKey:
                'summary-month-$currentUser-$firstDayOfMonth-$lastDayOfMonth-${main.refreshKey}',
            futureFactory: () => main.retrieveEntireMonthlyTotalMainCategoryTable(
                currentUser, firstDayOfMonth, lastDayOfMonth, false),
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
    
                if (snapshotData! <= 0) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoToTheUser(
                          sectionInformation: AppString.infoAboutSummaryWindow),
                      SizedBox(height: 16),
                      HomeStreaksSection(),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _summaryButton(
                            context: context,
                            title: AppString.homeSubcategoryTitle,
                            icon: Icons.view_list_rounded,
                            color: AppColor.blueMainColor,
                            onTap: () => _showSummaryDialog(
                              context: context,
                              title: AppString.homeSubcategoryTitle,
                              isSubcategory: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _summaryButton(
                            context: context,
                            title: AppString.mainCategoryTitle,
                            icon: Icons.donut_large_rounded,
                            color: AppColor.selfDevelopmentPieChartColor,
                            onTap: () => _showSummaryDialog(
                              context: context,
                              title: AppString.mainCategoryTitle,
                              isSubcategory: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const HomeStreaksSection(),
                    ],
                  );
                }
              }
            });
      }),
    );
  }
}

class HomeStreaksSection extends StatelessWidget {
  const HomeStreaksSection({super.key});

  Color _statusColor(SubcategoryStreakTodayStatus status) {
    switch (status) {
      case SubcategoryStreakTodayStatus.metToday:
        return AppColor.accountedColor;
      case SubcategoryStreakTodayStatus.atRisk:
        return Colors.orange;
      case SubcategoryStreakTodayStatus.missed:
        return Colors.redAccent;
    }
  }

  String _statusLabel(SubcategoryStreakTodayStatus status) {
    switch (status) {
      case SubcategoryStreakTodayStatus.metToday:
        return 'Met Today';
      case SubcategoryStreakTodayStatus.atRisk:
        return 'At Risk';
      case SubcategoryStreakTodayStatus.missed:
        return 'Missed';
    }
  }

  Widget _streakCard({
    required BuildContext context,
    required Assigner assigner,
    required String currentUser,
    required String currentDate,
    required int refreshKey,
  }) {
    final tracker = context.read<MainCategoryTrackerProvider>();
    final streakType =
        SubcategoryStreakTypeValues.fromStoredValue(assigner.streakType);

    return CachedFutureBuilder<SubcategoryStreakStatus>(
      cacheKey:
          'home-streak-${assigner.subcategoryName}-${assigner.mainCategoryName}-$currentDate-$refreshKey',
      futureFactory: () => tracker.retrieveSubcategoryStreakStatus(
          currentUser: currentUser,
          subcategoryName: assigner.subcategoryName,
          mainCategoryName: assigner.mainCategoryName,
          streakType: streakType,
          targetMinutes: assigner.streakTargetMinutes,
          startDate: assigner.streakStartDate,
          currentDate: currentDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerWidget.rectangular(width: double.infinity, height: 58),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final streak = snapshot.data!;
        final statusColor = _statusColor(streak.todayStatus);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final borderColor =
            isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
        final panelColor = isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StreakDetailPage(streak: streak),
                  ),
                );
              },
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            streak.subcategoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 13,
                              fontweight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${streak.currentStreak} days | ${_statusLabel(streak.todayStatus)}',
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AssignerMainProvider, UserUidProvider, CurrentDateProvider,
        SubcategoryTrackerDatabaseProvider>(
      builder: (context, assigner, user, date, sub, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const SizedBox.shrink();
        }

        final activeStreaks = assigner.assignerItems
            .where((item) =>
                item.currentLoggedInUser == currentUser &&
                item.isArchive == 0 &&
                item.isStreakActive == 1)
            .toList();

        if (activeStreaks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subSectionTitle2(titleName: 'Streaks'),
            ...activeStreaks.map(
              (item) {
                final refreshKey = sub.refreshKeyForSubcategory(
                  currentUser: currentUser,
                  mainCategoryName: item.mainCategoryName,
                  subcategoryName: item.subcategoryName,
                );

                return _streakCard(
                  context: context,
                  assigner: item,
                  currentUser: currentUser,
                  currentDate: date.currentDate,
                  refreshKey: refreshKey,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
