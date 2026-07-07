import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_rewards/daily_xp_target_status.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import 'package:motion/motion_core/motion_widgets/home_analytics_widget.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_tips/badge_assignment.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../../../motion_themes/mth_styling/app_color.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';

/// Displays the user's efficiency score using `ExperiencePointTableProvider`.
/// Uses `FutureBuilder` to asynchronously fetch the score and handles loading
/// and error states.
/// On successful data retrieval, it shows the calculated efficiency score.

/// Get's the efficiency score for the selected date on the report
/// page heat map section
class EfficienyScoreSelectedDay extends StatelessWidget {
  final String selectedDay;

  const EfficienyScoreSelectedDay({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperiencePointTableProvider, UserUidProvider>(
        builder: (context, xp, user, child) {
      // currently logged in user uid
      final String? userUID = user.userUid;
      if (userUID == null) {
        // still loading SharedPreferences, or not signed in yet
        return const ShimmerWidget.rectangular(width: 50, height: 30);
      }

      return CachedFutureBuilder<int>(
          cacheKey: 'daily-xp-$userUID-$selectedDay-${xp.refreshKey}',
          futureFactory: () => xp.retrieveDailyExperiencePoints(
              currentUser: userUID, selectedDate: selectedDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 50, height: 30);
            } else if (snapshot.hasError) {
              return const Text("N/A");
            } else {
              final resultSnapShot = snapshot.data ?? 0;
              final String resultString = resultSnapShot.toString();

              return Text(
                "$resultString XP",
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            }
          });
    });
  }
}

// Get's the xp earned for the current day being tracked
class XPForTheCurrentDay extends StatelessWidget {
  const XPForTheCurrentDay({super.key});

  Future<DailyXpTargetStatus> _loadStatus({
    required ExperiencePointTableProvider xpProvider,
    required String currentUser,
    required String currentYear,
    required String currentDate,
  }) async {
    final score = await xpProvider.retrieveYearExperiencePointsEfficiencyScore(
      currentUser: currentUser,
      currentYear: currentYear,
    );
    return loadDailyXpTargetStatus(
      xpProvider: xpProvider,
      currentUser: currentUser,
      currentYear: currentYear,
      currentDate: currentDate,
      currentScore: score,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ExperiencePointTableProvider, CurrentDateProvider,
            CurrentYearProvider, UserUidProvider>(
        builder: (context, xp, date, year, user, child) {
      // current date
      final today = date.currentDate;

      // currently logged in user uid
      final String? currentUserUid = user.userUid;
      if (currentUserUid == null) {
        // still loading or not signed in—show same shimmer
        return const ShimmerWidget.rectangular(width: 120, height: 40);
      }

      return CachedFutureBuilder<DailyXpTargetStatus>(
          cacheKey:
              'today-xp-status-$currentUserUid-${year.currentYear}-$today-${xp.refreshKey}',
          futureFactory: () => _loadStatus(
                xpProvider: xp,
                currentUser: currentUserUid,
                currentYear: year.currentYear,
                currentDate: today,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 120, height: 40);
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final status = snapshot.data;
              final totalXPEarned = status?.earnedXp ?? 0;
              final hasMetDailyTarget = status?.hasMetTarget ?? false;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMetDailyTarget) ...[
                    Image.asset(
                      'assets/images/motion_badges/xp_earned_star.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    " $totalXPEarned XP\nEarned",
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: AppColor.accountedColor),
                  ),
                ],
              );
            }
          });
    });
  }
}

// Get's the efficiency score of the selected year or month
class EfficienyScoreSelectedYearOrMonth extends StatelessWidget {
  final String selectedYear;
  final bool getSelectedYearEfs;

  const EfficienyScoreSelectedYearOrMonth(
      {super.key,
      required this.selectedYear,
      required this.getSelectedYearEfs});

  Widget _compactBadgeImage(EfsBadgeLevel level) {
    switch (level) {
      case EfsBadgeLevel.timeNovice:
        return getImageAsset("sloth.png", 42, 42);
      case EfsBadgeLevel.focusedBeginner:
        return getImageAsset("dolphin.png", 42, 42);
      case EfsBadgeLevel.timePro:
        return getImageAsset("eagle.png", 42, 42);
      case EfsBadgeLevel.timeMaster:
        return getImageAsset("dragon.png", 42, 42);
      case EfsBadgeLevel.timeWizard:
        return getImageAsset("wizard.png", 42, 42);
    }
  }

  Widget _selectedYearEfsAndBadge(BuildContext context, double score) {
    final badge = EfsBadgePolicy.badgeForScore(score);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final badgeShellColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.07)
        : AppColor.blueMainColor.withValues(alpha: 0.08);
    final scoreShellColor = isDarkMode
        ? AppColor.blueMainColor.withValues(alpha: 0.18)
        : AppColor.blueMainColor.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: badgeShellColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 42,
                      width: 42,
                      child: _compactBadgeImage(badge.level),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Badge Earned",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 11,
                          fontweight: FontWeight.w700,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        badge.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 16,
                          fontweight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: scoreShellColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppString.efficiencyScoreTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10,
                          fontweight: FontWeight.w700,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        score.toStringAsFixed(2),
                        style: AppTextStyle.sectionTitleTextStyle(
                          fontsize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        FirstAndLastDay>(builder: (context, xp, user, fal, child) {
      // currently logged in user uid
      final String? currentUserUid = user.userUid;
      if (currentUserUid == null) {
        // still loading or not signed in—show placeholder
        return const ShimmerWidget.rectangular(width: 50, height: 30);
      }

      // the first and last day of the current month
      String firstDayOfMonth = fal.firstDay;
      String lastDayOfMonth = fal.lastDay;

      return getSelectedYearEfs
          ? CachedFutureBuilder<double>(
              cacheKey:
                  'selected-year-efs-$currentUserUid-$selectedYear-${xp.refreshKey}',
              futureFactory: () => xp.retrieveYearExperiencePointsEfficiencyScore(
                  currentUser: currentUserUid, currentYear: selectedYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  return _selectedYearEfsAndBadge(context, resultSnapShot);
                }
              })
          : CachedFutureBuilder<double>(
              cacheKey:
                  'selected-month-efs-$currentUserUid-$firstDayOfMonth-$lastDayOfMonth-${xp.refreshKey}',
              futureFactory: () => xp.retrieveMonthlyEfficiencyScore(
                  currentUser: currentUserUid,
                  firstDayOfMonth: firstDayOfMonth,
                  lastDayOfMonth: lastDayOfMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  return specialSectionTitleSelectedYear(
                      mainTitleName: resultSnapShot.toString());
                }
              });
    });
  }
}

// Returns the overall efficiency score or the efficiency score for the current year.
class EfficienyScoreWindow extends StatelessWidget {
  final bool getEntireScore;
  const EfficienyScoreWindow({super.key, required this.getEntireScore});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider>(builder: ((context, xp, user, year, child) {
      final String? currentUser = user.userUid;
      if (currentUser == null) {
        // still loading or not signed in — show placeholder
        return const ShimmerWidget.rectangular(width: 50, height: 30);
      }

      final String currentYear = year.currentYear;

      return getEntireScore
          ? CachedFutureBuilder<double>(
              cacheKey: 'entire-efs-$currentUser-${xp.refreshKey}',
              futureFactory: () => xp.retrieveExperiencePointsEfficiencyScore(
                  currentUser: currentUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  return efficiencySection(
                      score: "$resultSnapShot", getEntire: true);
                }
              })
          : CachedFutureBuilder<double>(
              cacheKey: 'year-efs-$currentUser-$currentYear-${xp.refreshKey}',
              futureFactory: () => xp.retrieveYearExperiencePointsEfficiencyScore(
                  currentUser: currentUser, currentYear: currentYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  return CurrentYearEFSDisplay(
                      score: resultSnapShot, isEntire: false);
                }
              });
    }));
  }
}

class _XpTargetDialogData {
  final NextBadgeProgress progress;
  final Map<String, int> earnedXpByCategory;
  final Map<String, double> trackedTimeByCategory;

  const _XpTargetDialogData({
    required this.progress,
    required this.earnedXpByCategory,
    required this.trackedTimeByCategory,
  });
}

// EFS Current Year Display
// Displays the current year EFS, and correnponding badge
class CurrentYearEFSDisplay extends StatelessWidget {
  final double score;
  final bool isEntire;

  const CurrentYearEFSDisplay(
      {super.key, required this.score, required this.isEntire});

  Future<NextBadgeProgress> _loadNextBadgeProgress({
    required ExperiencePointTableProvider xpProvider,
    required MainCategoryTrackerProvider trackerProvider,
    required String currentUser,
    required String currentYear,
    required String currentDate,
  }) async {
    final results = await Future.wait<Object>([
      loadDailyXpTargetStatus(
        xpProvider: xpProvider,
        currentUser: currentUser,
        currentYear: currentYear,
        currentDate: currentDate,
        currentScore: score,
      ),
      trackerProvider.retrievedUserStreak(currentUser: currentUser),
    ]);
    final status = results[0] as DailyXpTargetStatus;
    final currentStreak = results[1] as int;

    await HomeAnalyticsWidget.update(
      todayXp: status.earnedXp,
      targetXp: status.targetXp,
      currentStreak: currentStreak,
      badge: EfsBadgePolicy.badgeForScore(score),
    );

    return status.progress;
  }

  Widget _dailyXpTargetStar({
    required ExperiencePointTableProvider xpProvider,
    required String currentUser,
    required String currentYear,
    required String currentDate,
  }) {
    return CachedFutureBuilder<DailyXpTargetStatus>(
      cacheKey:
          'daily-xp-target-star-$currentUser-$currentYear-$currentDate-$score-${xpProvider.refreshKey}',
      futureFactory: () => loadDailyXpTargetStatus(
        xpProvider: xpProvider,
        currentUser: currentUser,
        currentYear: currentYear,
        currentDate: currentDate,
        currentScore: score,
      ),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            status == null ||
            !status.hasMetTarget) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Tooltip(
            message: 'Daily XP target met',
            child: Image.asset(
              'assets/images/motion_badges/xp_earned_star.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Future<_XpTargetDialogData> _loadXpTargetDialogData({
    required ExperiencePointTableProvider xpProvider,
    required MainCategoryTrackerProvider trackerProvider,
    required String currentUser,
    required String currentYear,
    required String currentDate,
  }) async {
    final progress = await _loadNextBadgeProgress(
      xpProvider: xpProvider,
      trackerProvider: trackerProvider,
      currentUser: currentUser,
      currentYear: currentYear,
      currentDate: currentDate,
    );
    final earnedXpByCategory =
        await xpProvider.retrieveDailyExperiencePointBreakdown(
      currentUser: currentUser,
      selectedDate: currentDate,
    );
    final trackedTimeByCategory =
        await xpProvider.retrieveDailyMainCategoryTimeBreakdown(
      currentUser: currentUser,
      selectedDate: currentDate,
    );

    return _XpTargetDialogData(
      progress: progress,
      earnedXpByCategory: earnedXpByCategory,
      trackedTimeByCategory: trackedTimeByCategory,
    );
  }

  Widget _xpTargetRow({
    required BadgeXpTarget target,
    required int earnedXp,
    required double trackedMinutes,
    required bool isDarkMode,
  }) {
    final hasMetTarget = earnedXp >= target.xp;
    final remainingXp = hasMetTarget ? 0 : target.xp - earnedXp;
    final targetProgress = target.xp <= 0
        ? 1.0
        : (earnedXp / target.xp).clamp(0.0, 1.0).toDouble();
    final rowColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.055)
        : AppColor.tileBackgroundColor.withValues(alpha: 0.045);
    final accentColor = hasMetTarget
        ? (isDarkMode
            ? AppColor.accountedColor.withValues(alpha: 0.85)
            : AppColor.accountedColor)
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: hasMetTarget ? 0.22 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  target.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 13,
                    fontweight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earned: $earnedXp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Target Time: ${_targetTimeLabel(target)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Tracked: ${_timeLabel(trackedMinutes.round())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: targetProgress,
                    minHeight: 5,
                    color: accentColor,
                    backgroundColor: accentColor.withValues(alpha: 0.13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${target.xp} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasMetTarget
                            ? Icons.check_circle_rounded
                            : Icons.timelapse_rounded,
                        size: 12,
                        color: accentColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        hasMetTarget ? 'Met' : '$remainingXp left',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10,
                          fontweight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyXpSummaryTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 13,
                fontweight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyXpSummaryRow({
    required int earnedToday,
    required int dailyTarget,
  }) {
    final remainingXp = dailyTarget > earnedToday ? dailyTarget - earnedToday : 0;
    final hasMetDailyTarget = earnedToday >= dailyTarget;

    return Row(
      children: [
        _dailyXpSummaryTile(
          label: 'Earned Today',
          value: '$earnedToday XP',
          color: hasMetDailyTarget ? AppColor.accountedColor : Colors.orange,
        ),
        const SizedBox(width: 8),
        _dailyXpSummaryTile(
          label: hasMetDailyTarget ? 'Daily Target' : 'Remaining',
          value: hasMetDailyTarget ? '$dailyTarget XP met' : '$remainingXp XP',
          color: hasMetDailyTarget ? AppColor.accountedColor : Colors.orange,
        ),
      ],
    );
  }

  String _targetTimeLabel(BadgeXpTarget target) {
    final minutes = _targetMinutes(target);
    return _timeLabel(minutes);
  }

  String _timeLabel(int minutes) {
    if (minutes <= 0) return '0 min';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '$mins min';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  int _targetMinutes(BadgeXpTarget target) {
    switch (target.label) {
      case 'Education':
      case 'Work':
      case 'Skills':
      case 'Self Development':
        return target.xp * 12;
      case 'Sleep':
        if (target.xp <= 8) return 300;
        if (target.xp <= 15) return 360;
        return 420;
      case 'Tracking Bonus':
        if (target.xp <= 1) return 480;
        if (target.xp == 2) return 600;
        if (target.xp == 3) return 720;
        if (target.xp == 4) return 840;
        return 960;
      default:
        return 0;
    }
  }

  Widget _xpTargetDialogShell({
    required BuildContext context,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Today's XP Target",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 16,
                            fontweight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Next badge pace',
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
                  Tooltip(
                    message: 'Close',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 6),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showXpTargetsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;

        return Consumer4<ExperiencePointTableProvider, UserUidProvider,
            CurrentYearProvider, CurrentDateProvider>(
          builder: (context, xp, user, year, date, child) {
            final currentUser = user.userUid;
            if (currentUser == null) {
              return _xpTargetDialogShell(
                context: dialogContext,
                child: const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final currentYear = year.currentYear;
            final currentDate = date.currentDate;

            return FutureBuilder<_XpTargetDialogData>(
              future: _loadXpTargetDialogData(
                xpProvider: xp,
                trackerProvider: context.read<MainCategoryTrackerProvider>(),
                currentUser: currentUser,
                currentYear: currentYear,
                currentDate: currentDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _xpTargetDialogShell(
                    context: dialogContext,
                    child: const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _xpTargetDialogShell(
                    context: dialogContext,
                    child: const Text("N/A"),
                  );
                }

                final dialogData = snapshot.data!;
                final progress = dialogData.progress;
                final nextBadge = progress.nextBadge;

                if (progress.isTopBadge || nextBadge == null) {
                  return _xpTargetDialogShell(
                    context: dialogContext,
                    child: Text(
                      'Top Badge Earned',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 14,
                        fontweight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final dailyTarget = progress.averageDailyXp.ceil();
                final targetRows = EfsBadgePolicy.dailyXpTargets(dailyTarget);
                final earnedToday = dialogData.earnedXpByCategory.values.fold(
                  0,
                  (previousValue, earnedXp) => previousValue + earnedXp,
                );

                return _xpTargetDialogShell(
                  context: dialogContext,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next Badge',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.subSectionTextStyle(
                                      fontsize: 11,
                                      fontweight: FontWeight.normal,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  Text(
                                    nextBadge.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.subSectionTextStyle(
                                      fontsize: 15,
                                      fontweight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$dailyTarget XP',
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 18,
                                fontweight: FontWeight.w900,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dailyXpSummaryRow(
                        earnedToday: earnedToday,
                        dailyTarget: dailyTarget,
                      ),
                      if (!progress.isAttainableThisYear) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Daily Max: ${MotionXpPolicy.maxDailyXp} XP',
                          textAlign: TextAlign.right,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 12,
                            fontweight: FontWeight.normal,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      ...targetRows.map(
                        (target) => _xpTargetRow(
                          target: target,
                          earnedXp:
                              dialogData.earnedXpByCategory[target.label] ?? 0,
                          trackedMinutes:
                              dialogData.trackedTimeByCategory[target.label] ??
                                  0,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // efs and total XP strcuture
  Widget _efsAndTotalXp(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // efs score for the current year
        efficiencySection(score: "$score", getEntire: isEntire),

        // total XP for the current year
        Consumer4<ExperiencePointTableProvider, UserUidProvider,
                CurrentYearProvider, CurrentDateProvider>(
            builder: (context, xps, user, year, date, child) {
          // current user that's logged in
          final String? currentUser = user.userUid;
          if (currentUser == null) {
            // still loading or not signed in—show placeholder
            return const ShimmerWidget.rectangular(width: 100, height: 30);
          }

          final String currentYear = year.currentYear;

          return CachedFutureBuilder<int>(
              cacheKey:
                  'total-xp-$currentUser-$isEntire-$currentYear-${xps.refreshKey}',
              futureFactory: () => xps.retrieveTotalXP(
                  currentUser: currentUser,
                  isEntire: isEntire,
                  year: currentYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(
                      width: 100, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final snapResults = snapshot.data ?? 0;

                  final isDarkMode =
                      Theme.of(context).brightness == Brightness.dark;

                  return Tooltip(
                    message: "Today's XP Target",
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showXpTargetsDialog(context),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColor.accountedColor
                                    .withValues(alpha: 0.12)
                                : AppColor.accountedColor
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColor.accountedColor
                                  .withValues(alpha: isDarkMode ? 0.28 : 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  "$snapResults XP",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle
                                      .accountedAndUnaccountedGallaryStyle(
                                    fontsize: 17,
                                    fontweight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppColor.accountedColor,
                              ),
                              _dailyXpTargetStar(
                                xpProvider: xps,
                                currentUser: currentUser,
                                currentYear: currentYear,
                                currentDate: date.currentDate,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              });
        })
      ],
    );
  }

  // badge and name
  Widget _badgeAndName({required EfsBadge badge, required Image badgeImage}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // badge
          badgeImage,

          // name
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              badge.name,
              style: AppTextStyle.subSectionTextStyle(fontsize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Image _badgeImage(EfsBadgeLevel level) {
    switch (level) {
      case EfsBadgeLevel.timeNovice:
        return AppImages.sloth;
      case EfsBadgeLevel.focusedBeginner:
        return AppImages.dolphine;
      case EfsBadgeLevel.timePro:
        return AppImages.eagle;
      case EfsBadgeLevel.timeMaster:
        return AppImages.dragon;
      case EfsBadgeLevel.timeWizard:
        return AppImages.wizard;
    }
  }

  // badge assignment depending on score
  Widget _getBadge(double score) {
    final badge = EfsBadgePolicy.badgeForScore(score);

    return _badgeAndName(
      badge: badge,
      badgeImage: _badgeImage(badge.level),
    );
  }

  Widget _nextBadgeProgressRow(BuildContext context) {
    return Consumer4<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider, CurrentDateProvider>(
        builder: (context, xp, user, year, date, child) {
      final String? currentUser = user.userUid;
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 160, height: 24);
      }

      final currentYear = year.currentYear;

      return CachedFutureBuilder<NextBadgeProgress>(
          cacheKey:
              'next-badge-progress-$currentUser-$currentYear-${date.currentDate}-$score-${xp.refreshKey}',
          futureFactory: () => _loadNextBadgeProgress(
                xpProvider: xp,
                trackerProvider: context.read<MainCategoryTrackerProvider>(),
                currentUser: currentUser,
                currentYear: currentYear,
                currentDate: date.currentDate,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 160, height: 24);
            } else if (snapshot.hasError) {
              return const SizedBox.shrink();
            }

            final progress = snapshot.data;
            if (progress == null) return const SizedBox.shrink();

            final nextBadgeName = progress.nextBadge?.name ?? 'Top Badge';
            final progressPercent = (progress.progress * 100).round();
            final paceText = progress.isTopBadge
                ? 'Top Badge Earned'
                : '${progress.averageDailyXp.ceil()} XP/day';

            return Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          progress.isTopBadge
                              ? 'Top Badge Earned'
                              : 'Next: $nextBadgeName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11,
                            fontweight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        progress.isTopBadge
                            ? '100%'
                            : '$progressPercent% | $paceText',
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
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 7.92,
                      color: Colors.orange,
                      backgroundColor: Colors.orange.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.24,
      width: screenWidth * 0.64,
      child: Card(
        elevation: 0,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 14.0, right: 12.0, bottom: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // efs and total XP for current year
                      Expanded(
                        flex: 4,
                        child: _efsAndTotalXp(context),
                      ),

                      const SizedBox(width: 8),

                      // BADGE depending on score
                      // When the badge is double tapped, it navigates to a page that displays
                      // the badge assignment criteria
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onDoubleTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const BadgeAssignment()));
                          },
                          child: _getBadge(score),
                        ),
                      ),
                    ],
                  ),
                  FractionallySizedBox(
                    widthFactor: 1.0,
                    child: _nextBadgeProgressRow(context),
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

// database calculated efficiency score and title
Widget efficiencySection({required String score, required bool getEntire}) {
  return Container(
    alignment: Alignment.topLeft,
    child: specialSectionTitleEFS(
      getEntire: getEntire,
      mainTitleName: score,
    ),
  );
}

/// A widget that builds and displays the most or least productive day.
/// It uses a FutureBuilder to asynchronously fetch data about the productive day.
/// - `productiveMessage`: A string to display the type of productive day (most or least).
/// - `future`: The future that fetches the productive day data.
/// This widget handles different states like loading, error, and data display.
/// It shows a shimmer effect while loading and displays the productive day once data is fetched.
class ProductiveDayBuilder extends StatelessWidget {
  final String productiveMessage;
  final Future<dynamic>? future;
  final Object? cacheKey;
  final String varableName;

  const ProductiveDayBuilder(
      {super.key,
      required this.productiveMessage,
      this.future,
      this.cacheKey,
      required this.varableName});

  Widget _productiveDisplay(
      {required String productiveMessage, required String date}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // productive message
        Text(
          productiveMessage,
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        ),

        // dots separator
        Text(
          " ....................................... ",
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        ),

        // date
        Text(
          date,
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CachedFutureBuilder<dynamic>(
        cacheKey: cacheKey ?? future ?? productiveMessage,
        futureFactory: () => future ?? Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerWidget.rectangular(width: 100, height: 30);
          } else if (snapshot.hasError) {
            return const Text("N/A");
          } else {
            final resultSnapShot = snapshot.data ?? [];
            if (resultSnapShot.isEmpty) {
              return const Text("N/A");
            }

            // (most/least) productive date
            final String date = resultSnapShot[0][varableName];

            return Padding(
                padding: const EdgeInsets.all(10.0),
                child: _productiveDisplay(
                    productiveMessage: productiveMessage, date: date)
                // Text(
                //   "$productiveMessage ....................................... $date",
                //   style: AppTextStyle.alertDialogElevatedButtonTextStyle(),
                // ),
                );
          }
        });
  }
}

/// A widget that determines and builds either the most or least productive day.
/// It uses Consumer3 to listen to changes from ExperiencePointTableProvider,
///  UserUidProvider, and FirstAndLastDay.
/// - `getMostProductiveDay`: A boolean to decide if fetching the most
///  productive day (`true`) or the least (`false`).
/// Depending on `getMostProductiveDay`, it fetches and displays the relevant
///  productive day using `ProductiveDayBuilder`. It provides the necessary
///  parameters like the user's UID and the first and last day of the current
///  month to the `ProductiveDayBuilder`.
class MostAndLeastProductiveDayBuilder extends StatelessWidget {
  final bool getMostProductiveDay;

  const MostAndLeastProductiveDayBuilder(
      {super.key, required this.getMostProductiveDay});

  @override
  Widget build(BuildContext context) {
    return getMostProductiveDay
        ? Consumer3<ExperiencePointTableProvider, UserUidProvider,
            FirstAndLastDay>(builder: (context, xp, user, firstAndLast, child) {
            // currently logged in user uid
            final currentUserUid = user.userUid;
            if (currentUserUid == null) {
              return const ShimmerWidget.rectangular(width: 100, height: 30);
            }

            // first and last day of the current month
            final String firstDayOfMonth = firstAndLast.firstDay;
            final String lastDayOfMonth = firstAndLast.lastDay;

            return ProductiveDayBuilder(
              productiveMessage: AppString.mostProductiveDay,
              cacheKey:
                  'most-productive-day-$currentUserUid-$firstDayOfMonth-$lastDayOfMonth-${xp.refreshKey}',
              future: xp.retrieveMostAndLeastProductiveDays(
                  currentUser: currentUserUid,
                  firstDay: firstDayOfMonth,
                  lastDay: lastDayOfMonth,
                  getMostProductiveDay: true),
              varableName: 'date',
            );
          })
        : Consumer3<ExperiencePointTableProvider, UserUidProvider,
            FirstAndLastDay>(builder: (context, xp, user, firstAndLast, child) {
            // currently logged in user uid
            final String? currentUserUid = user.userUid;
            if (currentUserUid == null) {
              return const ShimmerWidget.rectangular(width: 100, height: 30);
            }

            // first and last day of the current month
            final String firstDayOfMonth = firstAndLast.firstDay;
            final String lastDayOfMonth = firstAndLast.lastDay;

            return ProductiveDayBuilder(
              productiveMessage: AppString.leastProductiveDay,
              cacheKey:
                  'least-productive-day-$currentUserUid-$firstDayOfMonth-$lastDayOfMonth-${xp.refreshKey}',
              future: xp.retrieveMostAndLeastProductiveDays(
                  currentUser: currentUserUid,
                  firstDay: firstDayOfMonth,
                  lastDay: lastDayOfMonth,
                  getMostProductiveDay: false),
              varableName: 'date',
            );
          });
  }
}

// Most and Least Productive Month Builder
class MostAndLeastProductiveMonthBuilder extends StatelessWidget {
  final bool getMostProductiveMonth;
  final String year;

  const MostAndLeastProductiveMonthBuilder(
      {super.key, required this.getMostProductiveMonth, required this.year});

  @override
  Widget build(BuildContext context) {
    return getMostProductiveMonth
        ? Consumer2<ExperiencePointTableProvider, UserUidProvider>(
            builder: (context, xp, user, child) {
            // currently logged in user uid
            final currentUserUid = user.userUid;
            if (currentUserUid == null) {
              return const ShimmerWidget.rectangular(width: 100, height: 30);
            }

            return ProductiveDayBuilder(
              productiveMessage: AppString.mostProductiveMonth,
              cacheKey:
                  'most-productive-month-$currentUserUid-$year-${xp.refreshKey}',
              future: xp.retrieveMostAndLeastProductiveMonths(
                  getMostProductiveMonth: getMostProductiveMonth,
                  currentUser: currentUserUid,
                  year: year),
              varableName: 'month',
            );
          })
        : Consumer2<ExperiencePointTableProvider, UserUidProvider>(
            builder: (context, xp, user, child) {
            // currently logged in user uid
            final String? currentUserUid = user.userUid;
            if (currentUserUid == null) {
              return const ShimmerWidget.rectangular(width: 100, height: 30);
            }

            return ProductiveDayBuilder(
              productiveMessage: AppString.leastProductiveMonth,
              cacheKey:
                  'least-productive-month-$currentUserUid-$year-${xp.refreshKey}',
              future: xp.retrieveMostAndLeastProductiveMonths(
                  getMostProductiveMonth: getMostProductiveMonth,
                  currentUser: currentUserUid,
                  year: year),
              varableName: 'month',
            );
          });
  }
}
