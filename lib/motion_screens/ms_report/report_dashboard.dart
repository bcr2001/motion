import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_screens/ms_report/report_heat_map.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class MonthlyReportLoadingSkeleton extends StatelessWidget {
  const MonthlyReportLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: const [
        _SnapshotSkeleton(),
        _HeatMapSkeleton(),
        _ChartSkeleton(titleWidth: 112),
        _ListSkeleton(titleWidth: 120, rows: 6),
        _ListSkeleton(titleWidth: 142, rows: 5),
        SizedBox(height: 18),
      ],
    );
  }
}

class MonthlySnapshotDashboard extends StatelessWidget {
  const MonthlySnapshotDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, days, main, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const _SnapshotSkeleton();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: main.retrieveMonthlyReportSnapshot(
            currentUser: currentUser,
            firstDay: days.firstDay,
            lastDay: days.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SnapshotSkeleton();
            }

            final data = snapshot.data ?? const {};
            final efs = _asDouble(data['efficiencyScore']);
            final badge = EfsBadgePolicy.badgeForScore(efs);
            final trackedDays = _asInt(data['trackedDays']);
            final totalXp = _asInt(data['totalXp']);
            final accountedMinutes = _asDouble(data['accountedMinutes']);
            final bestDay = _formatDate(data['bestDay']);
            final bestDayXp = _asInt(data['bestDayXp']);

            return _ReportPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month Snapshot',
                              style: AppTextStyle.sectionTitleTextStyle(
                                fontsize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _EfsPill(score: efs),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SnapshotMetric(
                        icon: Icons.bolt_rounded,
                        label: 'XP',
                        value: '$totalXp',
                        color: AppColor.workPieChartColor,
                      ),
                      _SnapshotMetric(
                        icon: Icons.timer_rounded,
                        label: 'Tracked',
                        value: convertMinutesToTime(accountedMinutes),
                        color: AppColor.accountedColor,
                      ),
                      _SnapshotMetric(
                        icon: Icons.calendar_month_rounded,
                        label: 'Days',
                        value: '$trackedDays/${days.days}',
                        color: AppColor.blueMainColor,
                      ),
                      _SnapshotMetric(
                        icon: Icons.trending_up_rounded,
                        label: bestDay,
                        value: '$bestDayXp XP',
                        color: AppColor.selfDevelopmentPieChartColor,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MonthlyReportHeatMapPanel extends StatelessWidget {
  const MonthlyReportHeatMapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardSectionHeader(
            icon: Icons.grid_view_rounded,
            title: 'Daily Consistency',
            trailing: _HeatMapLegend(),
          ),
          const SizedBox(height: 12),
          const ContributionsHeatMap(),
        ],
      ),
    );
  }
}

class MonthlyDailyXpTrendChart extends StatefulWidget {
  const MonthlyDailyXpTrendChart({super.key});

  @override
  State<MonthlyDailyXpTrendChart> createState() =>
      _MonthlyDailyXpTrendChartState();
}

class _MonthlyDailyXpTrendChartState extends State<MonthlyDailyXpTrendChart> {
  final ScrollController _scrollController = ScrollController();
  int? _lastAutoScrolledLength;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatestDate(int trendLength) {
    if (_lastAutoScrolledLength == trendLength) return;
    _lastAutoScrolledLength = trendLength;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, days, main, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const _ChartSkeleton(titleWidth: 112);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: main.retrieveMonthlyDailyXpTrend(
            currentUser: currentUser,
            firstDay: days.firstDay,
            lastDay: days.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ChartSkeleton(titleWidth: 112);
            }

            final trend = _filledDailyTrend(
              firstDay: days.firstDay,
              lastDay: days.lastDay,
              rows: snapshot.data ?? const [],
            );
            final trendMaxY = _trendMaxY(trend);
            _scrollToLatestDate(trend.length);

            return _ReportPanel(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DashboardSectionHeader(
                    icon: Icons.show_chart_rounded,
                    title: 'Daily XP Trend',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 190,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: max(360, trend.length * 36).toDouble(),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: trendMaxY,
                            minY: 0,
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.15),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              handleBuiltInTouches: false,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.transparent,
                                tooltipPadding: EdgeInsets.zero,
                                tooltipMargin: 4,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final item = trend[group.x.toInt()];
                                  if (item.xp <= 0) return null;
                                  return BarTooltipItem(
                                    '${item.xp}',
                                    AppTextStyle.subSectionTextStyle(
                                      fontsize: 9,
                                      fontweight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= trend.length) {
                                      return const SizedBox.shrink();
                                    }

                                    final day = trend[index].date.day;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 7),
                                      child: Text(
                                        '$day',
                                        style: AppTextStyle.chartLabelTextStyle()
                                            .copyWith(fontSize: 9.0),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < trend.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  showingTooltipIndicators:
                                      trend[i].xp > 0 ? const [0] : const [],
                                  barRods: [
                                    BarChartRodData(
                                      toY: trend[i].xp.toDouble(),
                                      width: 12,
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColor.blueMainColor,
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                        show: true,
                                        toY: trendMaxY,
                                        color: AppColor.blueMainColor
                                            .withValues(alpha: 0.10),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MonthlyCategoryBreakdownBars extends StatelessWidget {
  const MonthlyCategoryBreakdownBars({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, days, main, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const _ListSkeleton(titleWidth: 120, rows: 6);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: main.retrieveMainTotalTimeSpentSpecificDates(
            currentUser: currentUser,
            firstDay: days.firstDay,
            lastDay: days.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ListSkeleton(titleWidth: 120, rows: 6);
            }

            final rows = [...snapshot.data ?? const <Map<String, dynamic>>[]]
              ..sort(
                (a, b) => _asDouble(b['totalTimeSpent'])
                    .compareTo(_asDouble(a['totalTimeSpent'])),
              );
            final totalHours = rows.fold<double>(
              0,
              (sum, row) => sum + _asDouble(row['totalTimeSpent']),
            );

            return _ReportPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DashboardSectionHeader(
                    icon: Icons.stacked_bar_chart_rounded,
                    title: 'Where Time Went',
                  ),
                  const SizedBox(height: 12),
                  if (rows.isEmpty || totalHours <= 0)
                    const _EmptyAnalyticsMessage()
                  else
                    ...rows.map(
                      (row) {
                        final category =
                            row[MotionDbColumns.mainCategoryName].toString();
                        final hours = _asDouble(row['totalTimeSpent']);
                        final percentage =
                            totalHours <= 0 ? 0.0 : hours / totalHours;

                        return _CategoryBreakdownRow(
                          category: category,
                          hours: hours,
                          percentage: percentage,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MonthlyTopSubcategorySection extends StatelessWidget {
  const MonthlyTopSubcategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, days, main, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const _ListSkeleton(titleWidth: 142, rows: 5);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: main.retrieveTopSubcategoriesForPeriod(
            currentUser: currentUser,
            firstDay: days.firstDay,
            lastDay: days.lastDay,
            limit: 5,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ListSkeleton(titleWidth: 142, rows: 5);
            }

            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            final maxMinutes = rows.fold<double>(
              0,
              (value, row) => max(value, _asDouble(row['totalTimeSpent'])),
            );

            return _ReportPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DashboardSectionHeader(
                    icon: Icons.leaderboard_rounded,
                    title: 'Top Subcategories',
                  ),
                  const SizedBox(height: 12),
                  if (rows.isEmpty || maxMinutes <= 0)
                    const _EmptyAnalyticsMessage()
                  else
                    for (var i = 0; i < rows.length; i++)
                      _TopSubcategoryRow(
                        rank: i + 1,
                        subcategory:
                            rows[i][MotionDbColumns.subcategoryName].toString(),
                        mainCategory:
                            rows[i][MotionDbColumns.mainCategoryName].toString(),
                        minutes: _asDouble(rows[i]['totalTimeSpent']),
                        progress: _asDouble(rows[i]['totalTimeSpent']) /
                            maxMinutes,
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MonthlyInsightCards extends StatelessWidget {
  const MonthlyInsightCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
        MainCategoryTrackerProvider>(
      builder: (context, user, days, main, child) {
        final currentUser = user.userUid;
        if (currentUser == null) {
          return const _InsightsSkeleton();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: main.retrieveMonthlyReportSnapshot(
            currentUser: currentUser,
            firstDay: days.firstDay,
            lastDay: days.lastDay,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _InsightsSkeleton();
            }

            final data = snapshot.data ?? const {};
            final trackedDays = _asInt(data['trackedDays']);
            final totalXp = _asInt(data['totalXp']);
            final avgXp = trackedDays == 0 ? 0 : totalXp / trackedDays;
            final accountedMinutes = _asDouble(data['accountedMinutes']);
            final unaccountedMinutes = _asDouble(data['unaccountedMinutes']);
            final totalMinutes = accountedMinutes + unaccountedMinutes;
            final accountedPercent =
                totalMinutes <= 0 ? 0 : accountedMinutes / totalMinutes * 100;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Useful Insights',
                    style: AppTextStyle.sectionTitleTextStyle(fontsize: 17),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.insights_rounded,
                        title: 'Average',
                        value: '${avgXp.toStringAsFixed(1)} XP/day',
                        color: AppColor.blueMainColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.task_alt_rounded,
                        title: 'Accounted',
                        value: '${accountedPercent.toStringAsFixed(1)}%',
                        color: AppColor.selfDevelopmentPieChartColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.north_east_rounded,
                        title: 'Best Day',
                        value:
                            '${_formatDate(data['bestDay'])} - ${_asInt(data['bestDayXp'])} XP',
                        color: AppColor.accountedColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.south_east_rounded,
                        title: 'Lowest Day',
                        value:
                            '${_formatDate(data['lowestDay'])} - ${_asInt(data['lowestDayXp'])} XP',
                        color: AppColor.unAccountedColor,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReportPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ReportPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SnapshotSkeleton extends StatelessWidget {
  const _SnapshotSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget.rectangular(width: 150, height: 20),
                    SizedBox(height: 8),
                    ShimmerWidget.rectangular(width: 100, height: 13),
                  ],
                ),
              ),
              ShimmerWidget.rectangular(width: 70, height: 54),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < 4; i++)
                const _MetricSkeletonTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricSkeletonTile extends StatelessWidget {
  const _MetricSkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 62) / 2,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          ShimmerWidget.rectangular(width: 20, height: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget.rectangular(width: 58, height: 10),
                SizedBox(height: 7),
                ShimmerWidget.rectangular(width: 76, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatMapSkeleton extends StatelessWidget {
  const _HeatMapSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonHeader(width: 136),
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < 35; i++)
                const ShimmerWidget.rectangular(width: 28, height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  final double titleWidth;

  const _ChartSkeleton({required this.titleWidth});

  @override
  Widget build(BuildContext context) {
    final heights = [76.0, 124.0, 52.0, 142.0, 98.0, 118.0, 66.0, 150.0];
    return _ReportPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonHeader(width: titleWidth),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final height in heights) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ShimmerWidget.rectangular(
                        width: 16,
                        height: height,
                      ),
                    ),
                  ),
                  if (height != heights.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final double titleWidth;
  final int rows;

  const _ListSkeleton({required this.titleWidth, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonHeader(width: titleWidth),
          const SizedBox(height: 16),
          for (var i = 0; i < rows; i++) const _SkeletonListRow(),
        ],
      ),
    );
  }
}

class _SkeletonListRow extends StatelessWidget {
  const _SkeletonListRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              ShimmerWidget.rectangular(width: 120, height: 13),
              Spacer(),
              ShimmerWidget.rectangular(width: 58, height: 13),
            ],
          ),
          SizedBox(height: 8),
          ShimmerWidget.rectangular(width: double.infinity, height: 8),
        ],
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: ShimmerWidget.rectangular(width: 118, height: 18),
        ),
        Row(
          children: const [
            Expanded(child: _InsightSkeletonTile()),
            SizedBox(width: 10),
            Expanded(child: _InsightSkeletonTile()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(child: _InsightSkeletonTile()),
            SizedBox(width: 10),
            Expanded(child: _InsightSkeletonTile()),
          ],
        ),
      ],
    );
  }
}

class _InsightSkeletonTile extends StatelessWidget {
  const _InsightSkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget.rectangular(width: 20, height: 20),
          SizedBox(height: 9),
          ShimmerWidget.rectangular(width: 58, height: 11),
          SizedBox(height: 8),
          ShimmerWidget.rectangular(width: 92, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  final double width;

  const _SkeletonHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerWidget.rectangular(width: 32, height: 32),
        const SizedBox(width: 9),
        ShimmerWidget.rectangular(width: width, height: 17),
      ],
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _DashboardSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColor.blueMainColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.sectionTitleTextStyle(fontsize: 16),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EfsPill extends StatelessWidget {
  final double score;

  const _EfsPill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'EFS',
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10,
              color: Colors.blueGrey,
            ),
          ),
          Text(
            score.toStringAsFixed(2),
            style: AppTextStyle.sectionTitleTextStyle(fontsize: 22),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 62) / 2,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(fontsize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatMapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColor.defaultHeatMapBlockColor,
      AppColor.intensity5,
      AppColor.intensity10,
      AppColor.intensity15,
      AppColor.intensity20,
      AppColor.intensity25,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Low',
          style: AppTextStyle.chartLabelTextStyle(),
        ),
        const SizedBox(width: 5),
        for (final color in colors)
          Container(
            margin: const EdgeInsets.only(right: 3),
            height: 9,
            width: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 2),
        Text(
          'High',
          style: AppTextStyle.chartLabelTextStyle(),
        ),
      ],
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  final String category;
  final double hours;
  final double percentage;

  const _CategoryBreakdownRow({
    required this.category,
    required this.hours,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(fontsize: 13),
                ),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: AppTextStyle.subSectionTextStyle(fontsize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: percentage.clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSubcategoryRow extends StatelessWidget {
  final int rank;
  final String subcategory;
  final String mainCategory;
  final double minutes;
  final double progress;

  const _TopSubcategoryRow({
    required this.rank,
    required this.subcategory,
    required this.mainCategory,
    required this.minutes,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(mainCategory);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subcategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(fontsize: 13),
                      ),
                    ),
                    Text(
                      convertMinutesToTime(minutes),
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress.clamp(0, 1).toDouble(),
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            title,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(fontsize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyticsMessage extends StatelessWidget {
  const _EmptyAnalyticsMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          'No data yet',
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 13,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }
}

class _DailyTrendPoint {
  final DateTime date;
  final int xp;

  const _DailyTrendPoint({required this.date, required this.xp});
}

List<_DailyTrendPoint> _filledDailyTrend({
  required String firstDay,
  required String lastDay,
  required List<Map<String, dynamic>> rows,
}) {
  final first = DateTime.parse(firstDay);
  final rawLast = DateTime.parse(lastDay);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last = rawLast.isAfter(today) ? today : rawLast;
  final xpByDate = {
    for (final row in rows)
      row[MotionDbColumns.date].toString(): _asInt(row['totalXp'])
  };

  final points = <_DailyTrendPoint>[];
  for (var date = first;
      !date.isAfter(last);
      date = date.add(const Duration(days: 1))) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    points.add(_DailyTrendPoint(date: date, xp: xpByDate[key] ?? 0));
  }

  return points;
}

double _trendMaxY(List<_DailyTrendPoint> points) {
  final highest = points.fold<int>(0, (maxXp, point) => max(maxXp, point.xp));
  return max(20, (highest * 1.25).ceil()).toDouble();
}

Color _categoryColor(String category) {
  switch (category) {
    case MotionCategories.education:
      return AppColor.educationPieChartColor;
    case MotionCategories.work:
      return AppColor.workPieChartColor;
    case MotionCategories.skills:
      return AppColor.skillsPieChartColor;
    case MotionCategories.entertainment:
      return AppColor.entertainmentPieChartColor;
    case MotionCategories.selfDevelopment:
      return AppColor.selfDevelopmentPieChartColor;
    case MotionCategories.sleep:
      return AppColor.sleepPieChartColor;
    default:
      return AppColor.blueMainColor;
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(dynamic value) {
  final text = value?.toString() ?? '';
  final date = DateTime.tryParse(text);
  if (date == null) return 'TBD';
  return DateFormat('MMM d').format(date);
}
