import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_analytics/analytics_models.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import 'date_range_analysis_data.dart';
import 'date_range_analysis_components.dart';

class DateRangeAnalysisPage extends StatefulWidget {
  const DateRangeAnalysisPage({super.key});

  @override
  State<DateRangeAnalysisPage> createState() => _DateRangeAnalysisPageState();
}

class _DateRangeAnalysisPageState extends State<DateRangeAnalysisPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final today = MotionDateUtils.today();
    final currentMonth = MotionDateUtils.monthRange(today);
    _startDate = currentMonth.start;
    _endDate = today;
  }

  Future<void> _selectRange() async {
    final today = MotionDateUtils.today();
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColor.accountedColor,
                  surface: isDarkMode
                      ? AppColor.darkModeContentWidget
                      : AppColor.lightModeContentWidget,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selectedRange == null || !mounted) return;
    setState(() {
      _startDate = MotionDateUtils.dateOnly(selectedRange.start);
      _endDate = MotionDateUtils.dateOnly(selectedRange.end);
    });
  }

  String _displayRange() {
    return '${MotionDateUtils.formatDisplayDate(_startDate)} - ${MotionDateUtils.formatDisplayDate(_endDate)}';
  }

  Future<DateRangeAnalysisData> _loadAnalysisData({
    required MainCategoryTrackerProvider mainProvider,
    required SubcategoryTrackerDatabaseProvider subProvider,
    required String currentUser,
  }) async {
    return DateRangeAnalysisLoader(
      mainProvider: mainProvider,
      subcategoryProvider: subProvider,
    ).load(
      currentUser: currentUser,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Range Analysis'),
      ),
      body: Consumer3<UserUidProvider, MainCategoryTrackerProvider,
          SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, mainProvider, subProvider, child) {
          final currentUser = user.userUid;
          if (currentUser == null) {
            return const _RangeAnalysisLoading();
          }

          return FutureBuilder<DateRangeAnalysisData>(
            future: _loadAnalysisData(
              mainProvider: mainProvider,
              subProvider: subProvider,
              currentUser: currentUser,
            ),
            builder: (context, snapshot) {
              final content = <Widget>[
                DateRangeSelectorPanel(
                  rangeLabel: _displayRange(),
                  selectedDays: MotionDateUtils.inclusiveDaysBetween(
                      _startDate, _endDate),
                  onSelectRange: _selectRange,
                ),
              ];

              if (snapshot.connectionState == ConnectionState.waiting) {
                content.add(const _RangeAnalysisLoading());
              } else if (snapshot.hasError) {
                content.add(_RangeAnalysisEmptyState(
                  title: 'Analysis unavailable',
                  message: '${snapshot.error}',
                ));
              } else {
                final data = snapshot.data;
                if (data == null || !data.hasTrackedData) {
                  content.add(const _RangeAnalysisEmptyState(
                    title: 'No data in this range',
                    message: 'Choose another range or track time first.',
                  ));
                } else {
                  content.addAll([
                    _RangeSnapshotPanel(data: data),
                    _DailyXpTrendPanel(rows: data.dailyXpTrend),
                    _MainCategoryBreakdownPanel(
                      rows: data.mainCategoryBreakdown,
                    ),
                    _TopSubcategoryPanel(rows: data.topSubcategories),
                    const SizedBox(height: 18),
                  ]);
                }
              }

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: content,
              );
            },
          );
        },
      ),
    );
  }
}

class _RangeSnapshotPanel extends StatelessWidget {
  final DateRangeAnalysisData data;

  const _RangeSnapshotPanel({required this.data});

  String _dateValue(Object? value) {
    final parsedDate = MotionDateUtils.parseStoredDate(value);
    if (parsedDate == null) return 'TBD';
    return MotionDateUtils.formatDisplayDate(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    final averageTime = convertMinutesToTime(data.averageTrackedMinutes);
    return DateRangeAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.analytics_outlined,
            title: 'Range Snapshot',
            subtitle: 'What happened during the selected period',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Tracked Time',
                value: convertMinutesToTime(data.totalTrackedMinutes),
                color: AppColor.accountedColor,
              ),
              _MetricTile(
                label: 'Total XP',
                value: '${data.totalXp} XP',
                color: Colors.orange,
              ),
              _MetricTile(
                label: 'EFS',
                value: data.efsScore.toStringAsFixed(1),
                color: AppColor.blueMainColor,
              ),
              _MetricTile(
                label: 'Tracked Days',
                value: '${data.trackedDays}/${data.totalSelectedDays}',
                color: Colors.purple,
              ),
              _MetricTile(
                label: 'Average/Day',
                value: averageTime,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  icon: Icons.north_east_rounded,
                  label: 'Best XP Day',
                  value:
                      '${_dateValue(data.snapshot.bestDay)} - ${data.snapshot.bestDayXp} XP',
                  color: AppColor.accountedColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  icon: Icons.south_east_rounded,
                  label: 'Lowest XP Day',
                  value:
                      '${_dateValue(data.snapshot.lowestDay)} - ${data.snapshot.lowestDayXp} XP',
                  color: AppColor.unAccountedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyXpTrendPanel extends StatelessWidget {
  final List<DailyXpPoint> rows;

  const _DailyXpTrendPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final maxXp = rows.fold<int>(
      0,
      (maxValue, row) => math.max(maxValue, row.totalXp),
    );

    return DateRangeAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Daily XP Trend',
            subtitle: 'XP earned on each tracked day',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: rows.map((row) {
                final date = MotionDateUtils.parseStoredDate(row.date) ??
                    MotionDateUtils.today();
                final xp = row.totalXp;
                final height = maxXp <= 0 ? 8.0 : 22 + (xp / maxXp) * 88;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$xp',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10.5,
                          fontweight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        width: 26,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${date.day}',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10,
                          fontweight: FontWeight.normal,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainCategoryBreakdownPanel extends StatelessWidget {
  final List<CategoryTimeTotal> rows;

  const _MainCategoryBreakdownPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final maxHours = rows.fold<double>(
      0,
      (maxValue, row) => math.max(maxValue, row.totalHours),
    );

    return DateRangeAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Category Breakdown',
            subtitle: 'Main categories ranked by tracked time',
          ),
          const SizedBox(height: 12),
          ...rows.map((row) {
            final name = row.mainCategoryName;
            final hours = row.totalHours;
            final progress = maxHours <= 0 ? 0.0 : hours / maxHours;
            final color = _categoryColor(name);

            return _ProgressRow(
              label: name,
              value: '${hours.toStringAsFixed(1)} hrs',
              progress: progress,
              color: color,
            );
          }),
        ],
      ),
    );
  }
}

class _TopSubcategoryPanel extends StatelessWidget {
  final List<SubcategoryTimeTotal> rows;

  const _TopSubcategoryPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return DateRangeAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.leaderboard_outlined,
            title: 'Top Subcategories',
            subtitle: 'Your most tracked activities in this range',
          ),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final name = row.subcategoryName;
            final category = row.mainCategoryName;
            final minutes = row.totalMinutes;

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _categoryColor(category).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _categoryColor(category).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 12,
                        fontweight: FontWeight.w900,
                        color: _categoryColor(category),
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
                        Text(
                          category,
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
                  Text(
                    convertMinutesToTime(minutes),
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.w800,
                      color: _categoryColor(category),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: AppColor.blueMainColor),
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
              Text(
                subtitle,
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
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 58) / 2;
    return Container(
      width: math.max(132, width),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 15,
              fontweight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12,
              fontweight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12.5,
                    fontweight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeAnalysisLoading extends StatelessWidget {
  const _RangeAnalysisLoading();

  @override
  Widget build(BuildContext context) {
    return const DateRangeAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget.rectangular(width: 170, height: 20),
          SizedBox(height: 14),
          ShimmerWidget.rectangular(width: double.infinity, height: 58),
          SizedBox(height: 10),
          ShimmerWidget.rectangular(width: double.infinity, height: 58),
        ],
      ),
    );
  }
}

class _RangeAnalysisEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _RangeAnalysisEmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImages.noAnalysisGallary,
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 17,
              fontweight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12.5,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Education':
      return const Color(0xFF4F8BFF);
    case 'Work':
      return Colors.indigo;
    case 'Skills':
      return const Color(0xFF16A34A);
    case 'Entertainment':
      return const Color(0xFFEF4444);
    case 'Self Development':
      return const Color(0xFF8B5CF6);
    case 'Sleep':
      return const Color(0xFF14B8A6);
    default:
      return AppColor.blueMainColor;
  }
}
