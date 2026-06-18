import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class StreakDetailPage extends StatefulWidget {
  final SubcategoryStreakStatus streak;

  const StreakDetailPage({
    super.key,
    required this.streak,
  });

  @override
  State<StreakDetailPage> createState() => _StreakDetailPageState();
}

class _StreakDetailPageState extends State<StreakDetailPage> {
  bool _showAnalytics = false;

  SubcategoryStreakStatus get streak => widget.streak;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        setState(() => _showAnalytics = true);
      });
    });
  }

  String get _ruleLabel {
    if (streak.streakType == SubcategoryStreakType.targetTime) {
      return 'Target Time';
    }
    return 'Any Time';
  }

  IconData get _ruleIcon {
    if (streak.streakType == SubcategoryStreakType.targetTime) {
      return Icons.timer_outlined;
    }
    return Icons.check_circle_outline_rounded;
  }

  String get _ruleDescription {
    if (streak.streakType == SubcategoryStreakType.targetTime) {
      return 'The streak continues when the daily target is reached.';
    }
    return 'The streak continues when any time is tracked for the day.';
  }

  String get _statusLabel {
    switch (streak.todayStatus) {
      case SubcategoryStreakTodayStatus.metToday:
        return 'Met Today';
      case SubcategoryStreakTodayStatus.atRisk:
        return 'At Risk';
      case SubcategoryStreakTodayStatus.missed:
        return 'Missed';
    }
  }

  Color get _statusColor {
    switch (streak.todayStatus) {
      case SubcategoryStreakTodayStatus.metToday:
        return AppColor.accountedColor;
      case SubcategoryStreakTodayStatus.atRisk:
        return Colors.orange;
      case SubcategoryStreakTodayStatus.missed:
        return Colors.redAccent;
    }
  }

  String _formatDisplayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    const months = [
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
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  String get _currentStreakContext {
    if (streak.currentStreak <= 0 || streak.currentStreakStartDate.isEmpty) {
      return 'No active run yet';
    }

    return 'Started ${_formatDisplayDate(streak.currentStreakStartDate)}';
  }

  String get _bestStreakRange {
    if (streak.bestStreak <= 0 ||
        streak.bestStreakStartDate.isEmpty ||
        streak.bestStreakEndDate.isEmpty) {
      return 'No best run yet';
    }

    return '${streak.bestStreak} days - ${_formatDisplayDate(streak.bestStreakStartDate)} to ${_formatDisplayDate(streak.bestStreakEndDate)}';
  }

  String get _completionRateText {
    if (streak.totalDays <= 0) return '0%';
    final percent = (streak.metDays * 100 / streak.totalDays).round();
    return '$percent%';
  }

  String get _completionDetailText {
    return '${streak.metDays} of ${streak.totalDays} days met';
  }

  String get _recoveryText {
    if (streak.todayStatus == SubcategoryStreakTodayStatus.metToday) {
      return 'Today is covered. Keep the run alive tomorrow.';
    }

    if (streak.streakType == SubcategoryStreakType.targetTime) {
      final remaining =
          math.max(0.0, streak.targetMinutes - streak.todayMinutes);
      return 'Track ${convertMinutesToTime(remaining)} today to keep this streak alive.';
    }

    return 'Track any time today to keep this streak alive.';
  }

  Widget _streakInsightCard({
    required bool isDarkMode,
    required Color borderColor,
  }) {
    final recoveryColor = streak.todayStatus == SubcategoryStreakTodayStatus.metToday
        ? AppColor.accountedColor
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.blueGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _insightLine(
                  icon: Icons.timeline_rounded,
                  label: 'Current run',
                  value: _currentStreakContext,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColor.accountedColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _completionRateText,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 14,
                        fontweight: FontWeight.w900,
                        color: AppColor.accountedColor,
                      ),
                    ),
                    Text(
                      'Consistency',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 9.5,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _insightLine(
            icon: Icons.workspace_premium_outlined,
            label: 'Best run',
            value: _bestStreakRange,
            color: AppColor.blueMainColor,
          ),
          const SizedBox(height: 10),
          _insightLine(
            icon: Icons.flag_outlined,
            label: _completionDetailText,
            value: _recoveryText,
            color: recoveryColor,
          ),
        ],
      ),
    );
  }

  Widget _insightLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
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

  Widget _loadingPanel({
    required bool isDarkMode,
    required Color borderColor,
  }) {
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerWidget.rectangular(width: 180, height: 18),
          SizedBox(height: 14),
          ShimmerWidget.rectangular(width: double.infinity, height: 92),
          SizedBox(height: 10),
          ShimmerWidget.rectangular(width: double.infinity, height: 92),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
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
      ),
    );
  }

  Widget _ruleCard({
    required BuildContext context,
    required String targetText,
    required Color borderColor,
  }) {
    final accentColor = streak.streakType == SubcategoryStreakType.targetTime
        ? AppColor.selfDevelopmentPieChartColor
        : AppColor.blueMainColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _ruleIcon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ruleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 13.5,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        targetText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10.5,
                          fontweight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _ruleDescription,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
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
    final targetText = streak.streakType == SubcategoryStreakType.targetTime
        ? convertMinutesToTime(streak.targetMinutes)
        : 'Any tracked time';

    return Scaffold(
      appBar: AppBar(
        title: Text('${streak.subcategoryName} Streak'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            streak.subcategoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 16,
                              fontweight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            streak.mainCategoryName,
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metricTile(
                      label: 'Current',
                      value: '${streak.currentStreak} days',
                      color: _statusColor,
                    ),
                    const SizedBox(width: 10),
                    _metricTile(
                      label: 'Best',
                      value: '${streak.bestStreak} days',
                      color: AppColor.blueMainColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metricTile(
                      label: 'Today',
                      value: _statusLabel,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 10),
                    _metricTile(
                      label: 'Tracked',
                      value: convertMinutesToTime(streak.todayMinutes),
                      color: AppColor.selfDevelopmentPieChartColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _streakInsightCard(
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 14),
                Text(
                  'Rule',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12,
                    fontweight: FontWeight.w800,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                _ruleCard(
                  context: context,
                  targetText: targetText,
                  borderColor: borderColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_showAnalytics)
            _loadingPanel(
              isDarkMode: isDarkMode,
              borderColor: borderColor,
            )
          else ...[
            StreakHistorySection(
              streak: streak,
              borderColor: borderColor,
            ),
            const SizedBox(height: 14),
            StreakConsistencyStripSection(
              streak: streak,
              borderColor: borderColor,
            ),
            const SizedBox(height: 14),
            BestStreaksSection(
              streak: streak,
              borderColor: borderColor,
            ),
          ],
        ],
      ),
    );
  }
}

class StreakHistorySection extends StatefulWidget {
  final SubcategoryStreakStatus streak;
  final Color borderColor;

  const StreakHistorySection({
    super.key,
    required this.streak,
    required this.borderColor,
  });

  @override
  State<StreakHistorySection> createState() => _StreakHistorySectionState();
}

class _StreakHistorySectionState extends State<StreakHistorySection> {
  final ScrollController _historyScrollController = ScrollController();
  SubcategoryStreakHistoryRange _selectedRange =
      SubcategoryStreakHistoryRange.month;
  bool _shouldScrollToLatest = true;

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  String _rangeLabel(SubcategoryStreakHistoryRange range) {
    switch (range) {
      case SubcategoryStreakHistoryRange.week:
        return SubcategoryStreakHistoryRangeValues.week;
      case SubcategoryStreakHistoryRange.month:
        return SubcategoryStreakHistoryRangeValues.month;
      case SubcategoryStreakHistoryRange.year:
        return SubcategoryStreakHistoryRangeValues.year;
    }
  }

  String _historyCaption() {
    switch (_selectedRange) {
      case SubcategoryStreakHistoryRange.week:
        return 'Best streak reached in each recent week';
      case SubcategoryStreakHistoryRange.month:
        return 'Best streak reached in each month this year';
      case SubcategoryStreakHistoryRange.year:
        return 'Best streak reached in each tracked year';
    }
  }

  int _yearFromDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.year;

    final parts = value.split('/');
    if (parts.length == 3) {
      return int.tryParse(parts[2]) ?? DateTime.now().year;
    }

    return DateTime.now().year;
  }

  Widget _bottomTitle(
    double value,
    TitleMeta meta,
    List<SubcategoryStreakHistoryPoint> history,
    int currentYear,
  ) {
    final index = value.toInt();
    if (index < 0 || index >= history.length) {
      return const SizedBox.shrink();
    }

    final label = history[index].label;
    final showYear = index == 0 &&
        ((_selectedRange == SubcategoryStreakHistoryRange.month &&
                label == 'Jan') ||
            (_selectedRange == SubcategoryStreakHistoryRange.week &&
                label == 'W1'));

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 9.5,
              fontweight: FontWeight.w700,
              color: Colors.blueGrey,
            ),
          ),
          if (showYear)
            Text(
              currentYear.toString(),
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 8,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    if (value < 0 || value % 5 != 0) {
      return const SizedBox.shrink();
    }

    return Text(
      value.toInt().toString(),
      style: AppTextStyle.subSectionTextStyle(
        fontsize: 9,
        fontweight: FontWeight.normal,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _historyChart({
    required List<SubcategoryStreakHistoryPoint> history,
    required Color accentColor,
    required bool isDarkMode,
    required int currentYear,
  }) {
    final maxStreak = history.fold<int>(
      0,
      (maxValue, point) => math.max(maxValue, point.bestStreak),
    );
    final maxY = math.max(5, maxStreak + 2).toDouble();
    final chartWidth = math.max(320.0, history.length * 44.0);

    if (_shouldScrollToLatest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_historyScrollController.hasClients) return;
        _historyScrollController.jumpTo(
          _historyScrollController.position.maxScrollExtent,
        );
        _shouldScrollToLatest = false;
      });
    }

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        controller: _historyScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 5,
                    getTitlesWidget: _leftTitle,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitle(value, meta, history, currentYear),
                  ),
                ),
              ),
              barGroups: history.asMap().entries.map((entry) {
                final point = entry.value;
                final hasStreak = point.bestStreak > 0;

                return BarChartGroupData(
                  x: entry.key,
                  showingTooltipIndicators: const [0],
                  barRods: [
                    BarChartRodData(
                      toY: point.bestStreak.toDouble(),
                      width: 14,
                      color: hasStreak
                          ? accentColor
                          : Colors.blueGrey.withValues(alpha: 0.24),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 4,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = history[group.x.toInt()];
                    return BarTooltipItem(
                      point.bestStreak.toString(),
                      AppTextStyle.subSectionTextStyle(
                        fontsize: 10,
                        fontweight: FontWeight.w900,
                        color: accentColor,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    const accentColor = AppColor.blueMainColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColor.blueMainColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _historyCaption(),
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
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SubcategoryStreakHistoryRange>(
                    value: _selectedRange,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    items: SubcategoryStreakHistoryRange.values.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(
                          _rangeLabel(range),
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 12,
                            fontweight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRange = value;
                        _shouldScrollToLatest = true;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer2<UserUidProvider, CurrentDateProvider>(
            builder: (context, user, date, child) {
              final currentUser = user.userUid;
              if (currentUser == null) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracker = context.read<MainCategoryTrackerProvider>();

              return FutureBuilder<List<SubcategoryStreakHistoryPoint>>(
                future: tracker.retrieveSubcategoryStreakHistory(
                  currentUser: currentUser,
                  subcategoryName: widget.streak.subcategoryName,
                  mainCategoryName: widget.streak.mainCategoryName,
                  streakType: widget.streak.streakType,
                  targetMinutes: widget.streak.targetMinutes,
                  startDate: widget.streak.startDate,
                  currentDate: date.currentDate,
                  range: _selectedRange,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Text('Error: ${snapshot.error}'),
                      ),
                    );
                  }

                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          'No streak history yet',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  return _historyChart(
                    history: history,
                    accentColor: accentColor,
                    isDarkMode: isDarkMode,
                    currentYear: _yearFromDate(date.currentDate),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class StreakConsistencyStripSection extends StatefulWidget {
  final SubcategoryStreakStatus streak;
  final Color borderColor;

  const StreakConsistencyStripSection({
    super.key,
    required this.streak,
    required this.borderColor,
  });

  @override
  State<StreakConsistencyStripSection> createState() =>
      _StreakConsistencyStripSectionState();
}

class _StreakConsistencyStripSectionState
    extends State<StreakConsistencyStripSection> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldScrollToLatest = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    return DateTime.tryParse(value);
  }

  String _formatIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _shortDate(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return value;
    const months = [
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
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  Widget _dayCell({
    required DateTime date,
    required DateTime firstDay,
    required DateTime lastDay,
    required Map<String, SubcategoryStreakDay> daysByDate,
    required bool isDarkMode,
  }) {
    if (date.isBefore(firstDay) || date.isAfter(lastDay)) {
      return const SizedBox(width: 9, height: 9);
    }

    final day = daysByDate[_formatIsoDate(date)];
    final met = day?.metTarget ?? false;
    final tracked = (day?.minutesTracked ?? 0) > 0;
    final color = met
        ? AppColor.accountedColor
        : tracked
            ? Colors.orange.withValues(alpha: 0.70)
            : Colors.blueGrey.withValues(alpha: isDarkMode ? 0.24 : 0.16);

    final message = met
        ? 'Met'
        : tracked
            ? 'Tracked ${convertMinutesToTime(day!.minutesTracked)}, target missed'
            : 'Missed';

    return Tooltip(
      message: '${_shortDate(_formatIsoDate(date))}: $message',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _heatStrip({
    required List<SubcategoryStreakDay> days,
    required bool isDarkMode,
  }) {
    final firstDay = _parseDate(days.first.date);
    final lastDay = _parseDate(days.last.date);
    if (firstDay == null || lastDay == null) {
      return const SizedBox.shrink();
    }

    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final weekCount = lastDay.difference(gridStart).inDays ~/ 7 + 1;
    final daysByDate = {
      for (final day in days) day.date: day,
    };

    if (_shouldScrollToLatest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _shouldScrollToLatest = false;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 86,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: weekCount,
            itemExtent: 13,
            itemBuilder: (context, weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: [
                    for (var dayIndex = 0; dayIndex < 7; dayIndex++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _dayCell(
                          date: gridStart.add(
                            Duration(days: weekIndex * 7 + dayIndex),
                          ),
                          firstDay: firstDay,
                          lastDay: lastDay,
                          daysByDate: daysByDate,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(AppColor.accountedColor, 'Met'),
            const SizedBox(width: 10),
            _legendDot(Colors.orange.withValues(alpha: 0.70), 'Partial'),
            const SizedBox(width: 10),
            _legendDot(
              Colors.blueGrey.withValues(alpha: isDarkMode ? 0.24 : 0.16),
              'Missed',
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${_shortDate(days.first.date)} - ${_shortDate(days.last.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 10,
            fontweight: FontWeight.normal,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    const accentColor = AppColor.accountedColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.view_week_outlined,
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
                      'Consistency Map',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scroll to review past streak days',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'All history',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer2<UserUidProvider, CurrentDateProvider>(
            builder: (context, user, date, child) {
              final currentUser = user.userUid;
              if (currentUser == null) {
                return const SizedBox(
                  height: 116,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracker = context.read<MainCategoryTrackerProvider>();
              return FutureBuilder<List<SubcategoryStreakDay>>(
                future: tracker.retrieveSubcategoryStreakDays(
                  currentUser: currentUser,
                  subcategoryName: widget.streak.subcategoryName,
                  mainCategoryName: widget.streak.mainCategoryName,
                  streakType: widget.streak.streakType,
                  targetMinutes: widget.streak.targetMinutes,
                  startDate: widget.streak.startDate,
                  currentDate: date.currentDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 116,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 116,
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final days = snapshot.data ?? [];
                  if (days.isEmpty) {
                    return SizedBox(
                      height: 116,
                      child: Center(
                        child: Text(
                          'No streak days yet',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  return _heatStrip(days: days, isDarkMode: isDarkMode);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class BestStreaksSection extends StatelessWidget {
  final SubcategoryStreakStatus streak;
  final Color borderColor;

  const BestStreaksSection({
    super.key,
    required this.streak,
    required this.borderColor,
  });

  String _formatDisplayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    const months = [
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
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  List<SubcategoryBestStreakRun> _centerBestRun(
    List<SubcategoryBestStreakRun> runs,
  ) {
    if (runs.length <= 2) return runs;

    final maxStreak = runs.fold<int>(
      0,
      (maxValue, run) => math.max(maxValue, run.streakLength),
    );
    final bestIndex = runs.indexWhere((run) => run.streakLength == maxStreak);
    final bestRun = runs[bestIndex];
    final otherRuns = [...runs]..removeAt(bestIndex);

    otherRuns.sort((a, b) => b.endDate.compareTo(a.endDate));

    final aboveCount = otherRuns.length ~/ 2;
    return [
      ...otherRuns.take(aboveCount),
      bestRun,
      ...otherRuns.skip(aboveCount),
    ];
  }

  Widget _streakRunRow({
    required SubcategoryBestStreakRun run,
    required int maxStreak,
    required bool isBest,
    required bool isDarkMode,
  }) {
    final factor = maxStreak <= 0
        ? 0.0
        : (run.streakLength / maxStreak).clamp(0.14, 1.0).toDouble();
    final accentColor = isBest
        ? AppColor.accountedColor
        : run.streakLength >= (maxStreak * 0.55)
            ? AppColor.accountedColor.withValues(alpha: 0.64)
            : Colors.blueGrey.withValues(alpha: isDarkMode ? 0.35 : 0.22);
    final textColor = isBest
        ? (isDarkMode ? Colors.black : Colors.black87)
        : (isDarkMode ? Colors.white70 : Colors.blueGrey.shade700);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBest ? 5 : 3),
      child: Row(
        children: [
          Expanded(
            flex: 31,
            child: Text(
              _formatDisplayDate(run.startDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 38,
            child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: factor,
                child: Container(
                  height: isBest ? 25 : 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isBest
                        ? [
                            BoxShadow(
                              color: AppColor.accountedColor
                                  .withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    run.streakLength.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: isBest ? 12.5 : 11,
                      fontweight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 31,
            child: Text(
              _formatDisplayDate(run.endDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
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
    const accentColor = AppColor.accountedColor;
    return Container(
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
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
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
                      'Best Streaks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Top runs across all years',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'All time',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer2<UserUidProvider, CurrentDateProvider>(
            builder: (context, user, date, child) {
              final currentUser = user.userUid;
              if (currentUser == null) {
                return const SizedBox(
                  height: 148,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tracker = context.read<MainCategoryTrackerProvider>();
              return FutureBuilder<List<SubcategoryBestStreakRun>>(
                future: tracker.retrieveSubcategoryBestStreakRuns(
                  currentUser: currentUser,
                  subcategoryName: streak.subcategoryName,
                  mainCategoryName: streak.mainCategoryName,
                  streakType: streak.streakType,
                  targetMinutes: streak.targetMinutes,
                  startDate: streak.startDate,
                  currentDate: date.currentDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 148,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 148,
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final runs = snapshot.data ?? [];
                  if (runs.isEmpty) {
                    return SizedBox(
                      height: 148,
                      child: Center(
                        child: Text(
                          'No completed streaks yet',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  final displayRuns = _centerBestRun(runs);
                  final maxStreak = runs.fold<int>(
                    0,
                    (maxValue, run) =>
                        math.max(maxValue, run.streakLength),
                  );

                  return Column(
                    children: [
                      for (final run in displayRuns)
                        _streakRunRow(
                          run: run,
                          maxStreak: maxStreak,
                          isBest: run.streakLength == maxStreak,
                          isDarkMode: isDarkMode,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
