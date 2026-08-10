import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_ai/personalized_daily_forecast.dart';
import 'package:motion/motion_core/motion_providers/ai_pvd/daily_forecast_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class AiForecastPage extends StatefulWidget {
  const AiForecastPage({super.key});

  @override
  State<AiForecastPage> createState() => _AiForecastPageState();
}

class _AiForecastPageState extends State<AiForecastPage> {
  String? _scheduledRequestKey;
  DailyForecastProvider? _forecastProvider;
  String? _activeUser;
  String? _activeDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = context.watch<UserUidProvider>().userUid;
    final currentDate = context.watch<CurrentDateProvider>().currentDate;
    final currentYear = context.watch<CurrentYearProvider>().currentYear;
    final revision = context.watch<ExperiencePointTableProvider>().refreshKey;
    if (currentUser == null) return;
    _forecastProvider = context.read<DailyForecastProvider>();
    _activeUser = currentUser;
    _activeDate = currentDate;

    final requestKey = '$currentUser|$currentDate|$currentYear|$revision';
    if (_scheduledRequestKey == requestKey) return;
    _scheduledRequestKey = requestKey;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<DailyForecastProvider>();
      await provider.refresh(
        currentUser: currentUser,
        currentDate: currentDate,
        currentYear: currentYear,
        experienceRevision: revision,
      );
      if (!mounted) return;
      await provider.markSeen(
        currentUser: currentUser,
        currentDate: currentDate,
      );
    });
  }

  @override
  void dispose() {
    final provider = _forecastProvider;
    final currentUser = _activeUser;
    final currentDate = _activeDate;
    if (provider != null && currentUser != null && currentDate != null) {
      provider.clearDisplayedChange(
        currentUser: currentUser,
        currentDate: currentDate,
      );
    }
    super.dispose();
  }

  Future<void> _refresh({
    required String currentUser,
    required String currentDate,
    required String currentYear,
    required int revision,
  }) async {
    final provider = context.read<DailyForecastProvider>();
    await provider.refresh(
      currentUser: currentUser,
      currentDate: currentDate,
      currentYear: currentYear,
      experienceRevision: revision,
      force: true,
    );
    if (!mounted) return;
    await provider.markSeen(
      currentUser: currentUser,
      currentDate: currentDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.watch<UserUidProvider>().userUid;
    final currentDate = context.watch<CurrentDateProvider>().currentDate;
    final currentYear = context.watch<CurrentYearProvider>().currentYear;
    final revision = context.watch<ExperiencePointTableProvider>().refreshKey;
    final forecastProvider = context.watch<DailyForecastProvider>();
    final forecast = currentUser == null
        ? null
        : forecastProvider.forecastFor(
            currentUser: currentUser,
            currentDate: currentDate,
          );
    final error = currentUser == null
        ? null
        : forecastProvider.errorFor(
            currentUser: currentUser,
            currentDate: currentDate,
          );
    final change = currentUser == null
        ? null
        : forecastProvider.changeFor(
            currentUser: currentUser,
            currentDate: currentDate,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Forecast'),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const MotionEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Preparing your forecast',
              message: 'Your account is still being loaded.',
            )
          : forecast == null
              ? _ForecastLoadingState(
                  error: error,
                  onRetry: () => _refresh(
                    currentUser: currentUser,
                    currentDate: currentDate,
                    currentYear: currentYear,
                    revision: revision,
                  ),
                )
              : RefreshIndicator(
                  color: AppColor.blueMainColor,
                  backgroundColor: isDarkMode
                      ? AppColor.darkModeContentWidget
                      : AppColor.lightModeContentWidget,
                  elevation: 1,
                  displacement: 28,
                  strokeWidth: 2.4,
                  onRefresh: () => _refresh(
                    currentUser: currentUser,
                    currentDate: currentDate,
                    currentYear: currentYear,
                    revision: revision,
                  ),
                  child: _ForecastContent(
                    forecast: forecast,
                    change: change,
                  ),
                ),
    );
  }
}

class _ForecastContent extends StatelessWidget {
  const _ForecastContent({
    required this.forecast,
    required this.change,
  });

  final PersonalizedDailyForecast forecast;
  final DailyForecastChange? change;

  @override
  Widget build(BuildContext context) {
    final status = _ForecastStatusPresentation.from(forecast.status);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        _ForecastHero(forecast: forecast, status: status),
        if (change != null) ...[
          const SizedBox(height: 18),
          const MotionSectionHeader(title: 'What Changed'),
          const SizedBox(height: 10),
          _WhatChangedPanel(change: change!),
        ],
        const SizedBox(height: 18),
        if (!forecast.hasEnoughHistory) ...[
          MotionPanel(
            child: MotionEmptyState(
              icon: Icons.auto_graph_rounded,
              title: 'Learning your routine',
              message: forecast.factors.join(' '),
            ),
          ),
        ] else ...[
          if (forecast.bestNextMove != null) ...[
            const MotionSectionHeader(title: 'Best Next Move'),
            const SizedBox(height: 10),
            _BestNextMovePanel(move: forecast.bestNextMove!),
            const SizedBox(height: 18),
          ],
          const MotionSectionHeader(
            title: 'Recommended Focus',
            subtitle: 'A realistic category mix for today',
          ),
          const SizedBox(height: 10),
          if (forecast.focus.isEmpty)
            const MotionPanel(
              child: MotionEmptyState(
                icon: Icons.track_changes_rounded,
                title: 'No category recommendation yet',
              ),
            )
          else
            ...forecast.focus.map(
              (focus) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _ForecastFocusRow(focus: focus),
              ),
            ),
          const SizedBox(height: 9),
          const MotionSectionHeader(title: 'Why This Forecast'),
          const SizedBox(height: 10),
          MotionPanel(
            child: Column(
              children: [
                for (var index = 0;
                    index < forecast.factors.length;
                    index++) ...[
                  _ForecastFactor(text: forecast.factors[index]),
                  if (index < forecast.factors.length - 1)
                    const Divider(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Calculated privately on this device. Forecasts are estimates, not guarantees.',
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10.5,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ],
    );
  }
}

class _ForecastHero extends StatelessWidget {
  const _ForecastHero({
    required this.forecast,
    required this.status,
  });

  final PersonalizedDailyForecast forecast;
  final _ForecastStatusPresentation status;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final probability = forecast.targetProbability;
    final targetProgress = forecast.targetXp <= 0
        ? 0.0
        : (forecast.earnedXp / forecast.targetXp).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.16 : 0.055),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: status.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Outlook",
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 16,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MotionDateUtils.formatDisplayDate(forecast.date),
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10.5,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              MotionStatusPill(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            forecast.hasEnoughHistory
                ? '${forecast.lowerXp}-${forecast.upperXp} XP'
                : '${forecast.earnedXp} XP so far',
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 27,
              fontweight: FontWeight.w900,
              color: status.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            forecast.hasEnoughHistory
                ? 'Expected by the end of today'
                : 'Motion is building a reliable personal baseline',
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11.5,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: MotionMetric(
                  label: 'Earned',
                  value: '${forecast.earnedXp} XP',
                ),
              ),
              Expanded(
                child: MotionMetric(
                  label: 'Daily Target',
                  value: forecast.targetXp > 0
                      ? '${forecast.targetXp} XP'
                      : 'Not available',
                ),
              ),
              Expanded(
                child: MotionMetric(
                  label: 'Likelihood',
                  value: probability == null
                      ? 'Learning'
                      : '${(probability * 100).round()}%',
                  alignRight: true,
                ),
              ),
            ],
          ),
          if (forecast.targetXp > 0) ...[
            const SizedBox(height: 13),
            MotionProgressBar(
              value: targetProgress,
              color: status.color,
              height: 8,
            ),
          ],
        ],
      ),
    );
  }
}

class _WhatChangedPanel extends StatelessWidget {
  const _WhatChangedPanel({required this.change});

  final DailyForecastChange change;

  @override
  Widget build(BuildContext context) {
    final color = switch (change.tone) {
      DailyForecastChangeTone.positive => Colors.green,
      DailyForecastChangeTone.attention => Colors.orange,
      DailyForecastChangeTone.neutral => AppColor.blueMainColor,
    };
    final icon = switch (change.tone) {
      DailyForecastChangeTone.positive => Icons.trending_up_rounded,
      DailyForecastChangeTone.attention => Icons.priority_high_rounded,
      DailyForecastChangeTone.neutral => Icons.notifications_active_rounded,
    };

    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.title,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 13,
                    fontweight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                for (var index = 0; index < change.details.length; index++) ...[
                  Text(
                    change.details[index],
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                    ),
                  ),
                  if (index < change.details.length - 1)
                    const SizedBox(height: 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestNextMovePanel extends StatelessWidget {
  const _BestNextMovePanel({required this.move});

  final DailyForecastNextMove move;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(move.category);
    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_categoryIcon(move.category), color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Earn ${move.xpToEarn} XP in about '
                  '${_durationLabel(move.minutesRequired)}',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MotionStatusPill(label: '+${move.xpToEarn} XP', color: color),
        ],
      ),
    );
  }
}

class _ForecastFocusRow extends StatelessWidget {
  const _ForecastFocusRow({required this.focus});

  final DailyForecastFocus focus;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(focus.category);
    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      borderColor: color.withValues(alpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_categoryIcon(focus.category), color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        focus.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 13,
                          fontweight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${focus.earnedXp}/${focus.suggestedXp} XP',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 11,
                        fontweight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  focus.remainingXp == 0
                      ? 'Suggested XP reached'
                      : '${focus.remainingXp} XP remaining',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  focus.remainingMinutes == 0
                      ? 'Time target reached'
                      : 'Est. time remaining: '
                          '${_durationLabel(focus.remainingMinutes)}',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
                if (focus.trackedMinutes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tracked today: ${_durationLabel(focus.trackedMinutes)}',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                MotionProgressBar(
                  value: focus.progress,
                  color: color,
                  height: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastFactor extends StatelessWidget {
  const _ForecastFactor({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColor.blueMainColor,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11.5,
              fontweight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ForecastLoadingState extends StatelessWidget {
  const _ForecastLoadingState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MotionEmptyState(
                icon: Icons.insights_rounded,
                title: 'Forecast unavailable',
                message: 'Motion could not calculate today\'s forecast.',
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Preparing today\'s forecast...'),
        ],
      ),
    );
  }
}

class _ForecastStatusPresentation {
  const _ForecastStatusPresentation({
    required this.label,
    required this.color,
  });

  factory _ForecastStatusPresentation.from(DailyForecastStatus status) {
    return switch (status) {
      DailyForecastStatus.learning => const _ForecastStatusPresentation(
          label: 'Learning',
          color: AppColor.blueMainColor,
        ),
      DailyForecastStatus.noTarget => const _ForecastStatusPresentation(
          label: 'Forecast Only',
          color: AppColor.blueMainColor,
        ),
      DailyForecastStatus.atRisk => const _ForecastStatusPresentation(
          label: 'At Risk',
          color: Colors.redAccent,
        ),
      DailyForecastStatus.withinReach => const _ForecastStatusPresentation(
          label: 'Within Reach',
          color: Colors.orange,
        ),
      DailyForecastStatus.onTrack => const _ForecastStatusPresentation(
          label: 'On Track',
          color: AppColor.tileBackgroundColor,
        ),
      DailyForecastStatus.targetAchieved => const _ForecastStatusPresentation(
          label: 'Target Achieved',
          color: Colors.green,
        ),
    };
  }

  final String label;
  final Color color;
}

Color _categoryColor(String category) {
  return switch (category) {
    'Education' => AppColor.educationPieChartColor,
    'Work' => AppColor.workPieChartColor,
    'Skills' => AppColor.blueMainColor,
    'Self Development' => AppColor.selfDevelopmentPieChartColor,
    'Sleep' => AppColor.sleepPieChartColor,
    _ => Colors.blueGrey,
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Education' => Icons.school_rounded,
    'Work' => Icons.work_rounded,
    'Skills' => Icons.psychology_alt_rounded,
    'Self Development' => Icons.self_improvement_rounded,
    'Sleep' => Icons.bedtime_rounded,
    _ => Icons.category_rounded,
  };
}

String _durationLabel(int totalMinutes) {
  if (totalMinutes <= 0) return '0 min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}
