import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_rewards/daily_xp_target_status.dart';
import 'package:motion/motion_reusable/date_re/year_progress.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_routes/manual_tracking.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/shared_pvd/share.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';
import '../home_windows/efficieny_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Set<String> _activeDailyXpCelebrations = <String>{};

Future<void> maybeShowDailyXpTargetCelebration(BuildContext context) async {
  if (!context.mounted) return;

  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (!context.mounted) return;

  final currentUser = context.read<UserUidProvider>().userUid;
  if (currentUser == null) {
    debugLog('XP TARGET CELEBRATION DIRECT: skipped because UID is not ready.');
    return;
  }

  final xpProvider = context.read<ExperiencePointTableProvider>();
  final currentDate = context.read<CurrentDateProvider>().currentDate;
  final currentYear = context.read<CurrentYearProvider>().currentYear;
  final prefs = await SharedPreferences.getInstance();
  final celebrationKey =
      'daily_xp_target_celebration_v4_$currentUser-$currentDate';

  final score = await xpProvider.retrieveYearExperiencePointsEfficiencyScore(
    currentUser: currentUser,
    currentYear: currentYear,
  );
  final status = await loadDailyXpTargetStatus(
    xpProvider: xpProvider,
    currentUser: currentUser,
    currentYear: currentYear,
    currentDate: currentDate,
    currentScore: score,
  );
  final targetXp = status.targetXp;
  final earnedXp = status.earnedXp;

  debugLog(
    'XP TARGET CELEBRATION DIRECT: date=$currentDate earned=$earnedXp target=$targetXp '
    'score=$score',
  );

  if (targetXp <= 0) return;

  final hasAlreadyShown = prefs.getBool(celebrationKey) == true;
  if (!status.hasMetTarget) {
    if (hasAlreadyShown) {
      await prefs.remove(celebrationKey);
      await prefs.remove('${celebrationKey}_earned_xp');
      _activeDailyXpCelebrations.remove(celebrationKey);
      debugLog(
        'XP TARGET CELEBRATION DIRECT: reset shown state because earned XP dropped below target.',
      );
    }
    return;
  }

  if (hasAlreadyShown) {
    debugLog(
      'XP TARGET CELEBRATION DIRECT: skipped because the target star is already visible for $currentDate.',
    );
    return;
  }

  if (!context.mounted) return;

  if (!_activeDailyXpCelebrations.add(celebrationKey)) {
    debugLog(
      'XP TARGET CELEBRATION DIRECT: skipped because a congrats dialog is already active for $currentDate.',
    );
    return;
  }

  await prefs.setBool(celebrationKey, true);
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _DailyXpTargetCelebrationDialog(
          earnedXp: earnedXp,
          targetXp: targetXp,
        );
      },
    );
  } finally {
    _activeDailyXpCelebrations.remove(celebrationKey);
  }
}

class _DailyXpTargetCelebrationDialog extends StatefulWidget {
  final int earnedXp;
  final int targetXp;

  const _DailyXpTargetCelebrationDialog({
    required this.earnedXp,
    required this.targetXp,
  });

  @override
  State<_DailyXpTargetCelebrationDialog> createState() =>
      _DailyXpTargetCelebrationDialogState();
}

class _DailyXpTargetCelebrationDialogState
    extends State<_DailyXpTargetCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _confettiController;
  late final Animation<double> _progress;
  late final Animation<double> _iconTurns;
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    final targetProgress = widget.targetXp <= 0
        ? 1.0
        : (widget.earnedXp / widget.targetXp).clamp(0.0, 1.0).toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0, end: targetProgress));
    _iconTurns = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0, end: 1));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasVibrated) {
        _hasVibrated = true;
        _playCelebrationHaptic();
      }
    });
    _controller.forward();
    _confettiController.forward();
  }

  Future<void> _playCelebrationHaptic() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 85));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final detailColor = isDarkMode ? Colors.white70 : Colors.blueGrey;
    final earnedBeyondTarget =
        (widget.earnedXp - widget.targetXp).clamp(0, widget.earnedXp);

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CelebrationConfettiPainter(
                      progress: _confettiController.value,
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColor.accountedColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColor.accountedColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        RotationTransition(
                          turns: _iconTurns,
                          child: Container(
                            height: 48,
                            width: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColor.accountedColor
                                  .withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.accountedColor
                                    .withValues(alpha: 0.32),
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColor.accountedColor,
                              size: 29,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Daily Target Met',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.subSectionTextStyle(
                                  fontsize: 17,
                                  fontweight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                earnedBeyondTarget > 0
                                    ? '$earnedBeyondTarget XP above target'
                                    : 'Right on target',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.subSectionTextStyle(
                                  fontsize: 12,
                                  fontweight: FontWeight.w700,
                                  color: AppColor.accountedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You earned ${widget.earnedXp} XP today and reached your ${widget.targetXp} XP target.',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12.5,
                      fontweight: FontWeight.normal,
                      color: detailColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.035)
                              : Colors.black.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _DailyTargetMetric(
                                    label: 'Earned',
                                    value: '${widget.earnedXp} XP',
                                    color: AppColor.accountedColor,
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: borderColor,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                ),
                                Expanded(
                                  child: _DailyTargetMetric(
                                    label: 'Target',
                                    value: '${widget.targetXp} XP',
                                    color: detailColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 11,
                                value: _progress.value,
                                color: AppColor.accountedColor,
                                backgroundColor: AppColor.accountedColor
                                    .withValues(alpha: 0.16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(_progress.value * 100).round()}%',
                                style: AppTextStyle.subSectionTextStyle(
                                  fontsize: 11.5,
                                  fontweight: FontWeight.w800,
                                  color: detailColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.blueMainColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Continue'),
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

class _CelebrationConfettiPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  const _CelebrationConfettiPainter({
    required this.progress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final easedProgress = Curves.easeOutCubic.transform(progress);
    final fade = progress < 0.72
        ? 1.0
        : (1 - ((progress - 0.72) / 0.28)).clamp(0.0, 1.0);
    final colors = <Color>[
      AppColor.accountedColor,
      AppColor.blueMainColor,
      Colors.amber,
      Colors.orangeAccent,
      isDarkMode ? Colors.white70 : Colors.black54,
    ];

    for (var i = 0; i < 34; i++) {
      final lane = (i % 17) / 16;
      final side = i.isEven ? -1.0 : 1.0;
      final burst = 22 + (i % 5) * 8;
      final drift = side * burst * math.sin((progress * math.pi) + i);
      final x = (size.width * lane) + drift;
      final y = 8 + (size.height * 0.58 * easedProgress) + ((i % 4) * 8);
      final opacity = (fade * (0.35 + ((i % 3) * 0.18))).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((progress * math.pi * 2) + i);

      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 2.2 + (i % 2), paint);
      } else {
        final width = 4.0 + (i % 3);
        final height = 7.0 + (i % 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: height,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

class _DailyTargetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DailyTargetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 3),
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
    );
  }
}

//Displays a life progress bar based on a user's birthdate.
class LifeCompleted extends StatelessWidget {
  const LifeCompleted({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrentYearProvider, UserUidProvider>(
        builder: (context, year, user, child) {
      // current year
      final currentYear = year.currentYear;

      // user uid
      final currentUser = user.userUid;

      final dateOfBirthStorage = DateOfBirthStorage();

      return CachedFutureBuilder<DateTime?>(
        cacheKey: 'birthdate-$currentUser',
        futureFactory: () => currentUser != null
            ? dateOfBirthStorage.getDateOfBirth(currentUser)
            : Future.value(null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerWidget.rectangular(width: 50, height: 30);
          } else if (snapshot.hasError) {
            return const Text("N/A");
          } else {
            // date
            final date = snapshot.data;

            if (date == null) {
              return const SizedBox();
            } else {
              // year born
              final yearBorn = int.parse(date.year.toString());

              // age
              final currentAge = int.parse(currentYear) - yearBorn;

              // (current age/ life expectance age) = life_completed
              final double lifeCompleted = currentAge / 72.6;
              final double lifeCompletedProgress =
                  lifeCompleted.clamp(0.0, 1.0).toDouble();

              final String lifeCompletedPercent =
                  (lifeCompleted * 100).toStringAsFixed(2);
              final bool isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              final Color borderColor = isDarkMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black12;
              final Color trackColor = AppColor.accountedColor
                  .withValues(alpha: isDarkMode ? 0.22 : 0.18);

              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppString.lifeTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.subSectionTextStyle(
                                      fontsize: 14,
                                      fontweight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Age $currentAge of 72.6',
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
                            const SizedBox(width: 12),
                            Text(
                              "$lifeCompletedPercent%",
                              style: AppTextStyle.sectionTitleTextStyle(
                                  fontsize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: lifeCompletedProgress,
                            minHeight: 9,
                            color: AppColor.accountedColor,
                            backgroundColor: trackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }
        },
      );
    });
  }
}

// total all time accounted for and unaccounted for
Widget entireTimeAccountedAndUnaccounted(
    {required Future<dynamic> future,
    Object? cacheKey,
    required String resultName,
    required TextStyle dayStyle,
    required TextStyle hoursStyle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // table result (accounted/ unaccounted)
        CachedFutureBuilder<dynamic>(
            cacheKey: cacheKey ?? future,
            futureFactory: () => future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerWidget.rectangular(width: 100, height: 25);
              } else if (snapshot.hasError) {
                return const Text("Error 355 :(");
              } else {
                // results for the sqlite query
                final tableResult = snapshot.data ?? 0.0;

                // convert the minutes to hours
                final accountedConvertedResultsHours =
                    convertMinutesToHoursOnly(tableResult!,
                        isFirstSection: true);

                // convert hours to days
                final accountedConvertedResultsDays =
                    convertHoursToDays(tableResult);

                // display both the total hours and number of days
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // number of days
                    Text(
                      accountedConvertedResultsDays,
                      textAlign: TextAlign.right,
                      style: dayStyle,
                    ),

                    // total number of hours
                    Text(
                      accountedConvertedResultsHours,
                      style: hoursStyle,
                      textAlign: TextAlign.center,
                    )
                  ],
                );
              }
            }),

        // result name (Accounted or Unaccounted)
        Text(
          resultName,
          style: dayStyle,
        )
      ],
    ),
  );
}

// A widget that displays the total number of days accounted for in
// the main_category table. It can show the total number of days for either
// all time or for a specific year, based on the value of `getAllDays`.
class NumberOfDaysMainCategory extends StatelessWidget {
  final bool getAllDays;
  const NumberOfDaysMainCategory({super.key, required this.getAllDays});

  // displayes the number of days and the percent of the year completed
  Widget _numberOfDaysAndPercentCompleted(
      {required String numberOfDays,
      required String percentCompleted,
      required String daysInYear}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          // percent completed
          Text(
            "$percentCompleted%",
            style: AppTextStyle.resultTitleStyle(false),
            textAlign: TextAlign.right,
          ),

          // number of days
          Text(
            "Day: $numberOfDays/$daysInYear",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          // completed
          Text(
            "Completed",
            style: AppTextStyle.resultTitleStyle(false),
            textAlign: TextAlign.left,
          )
        ],
      ),
    );
  }

  // A helper method that creates a FutureBuilder to fetch and display the data.
  // It shows a loading indicator while waiting, an error message in case of
  // an error, and the total number of days when data is available.
  Widget _futureData(
      {Future<dynamic>? future,
      Object? cacheKey,
      required bool percent,
      int? displayYear}) {
    return CachedFutureBuilder<dynamic>(
      cacheKey: cacheKey ?? future ?? Object(),
      futureFactory: () => future ?? Future.value(0),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display shimmer effect while the data is being loaded
          return const ShimmerWidget.rectangular(width: 20, height: 20);
        } else if (snapshot.hasError) {
          // Display an error message if there is an error
          return Text('Error: ${snapshot.error}');
        } else {
          // Extract and display the total number of days
          final totalNumberOfDays =
              snapshot.data is int ? snapshot.data as int : 0;
          final year = displayYear ?? DateTime.now().year;
          final daysInYear = YearProgress.daysInYear(year);

          // percent of days completed
          final percentCompleted = YearProgress.percentComplete(
              elapsedDays: totalNumberOfDays, year: year);
          final percentCompletedFormatted2 =
              double.parse(percentCompleted.toStringAsFixed(2)).toString();

          return percent
              ? _numberOfDaysAndPercentCompleted(
                  numberOfDays: totalNumberOfDays.toString(),
                  percentCompleted: percentCompletedFormatted2,
                  daysInYear: daysInYear.toString())
              : Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    "Day: $totalNumberOfDays",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using Consumer3 to access three different providers
    return Consumer3<MainCategoryTrackerProvider, UserUidProvider,
        CurrentYearProvider>(
      builder: (context, main, user, year, child) {
        final String? userUid = user.userUid;

        // ✂️ Changed: check for null UID before proceeding
        if (userUid == null) {
          // show placeholder until UID is available
          return const ShimmerWidget.rectangular(width: 50, height: 30);
        }
        final currentYear = year.currentYear; // Current year
        final currentYearInt = int.tryParse(currentYear);

        // Decide which future to use based on the value of getAllDays
        // and call _futureData to build the UI accordingly
        return getAllDays
            ? _futureData(
                cacheKey: 'days-all-$userUid-${main.refreshKey}',
                future: main.retrievedNumberOfDays(currentUser: userUid),
                percent: false)
            : _futureData(
                cacheKey: 'days-year-$userUid-$currentYear-${main.refreshKey}',
                future: main.retrievedNumberOfDays(
                    currentUser: userUid,
                    currentYear: currentYear,
                    getAllDays: false),
                percent: true,
                displayYear: currentYearInt);
      },
    );
  }
}

// Arranges the efficiency score and number of days in a horizontal layout with spacing.
class EfficiencyAndNumberOfDays extends StatelessWidget {
  final Widget efficiencyScore;
  final Widget numberOfDays;
  const EfficiencyAndNumberOfDays(
      {super.key, required this.efficiencyScore, required this.numberOfDays});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // efficiency score
        efficiencyScore,

        // number of days
        numberOfDays
      ],
    );
  }
}

// returns the total time accounted for the current date
// and the current date text to the right
Widget timeAccountedCurrentDateXP() {
  return const TimeAccountedCurrentDateXP();
}

class TimeAccountedCurrentDateXP extends StatefulWidget {
  const TimeAccountedCurrentDateXP({super.key});

  @override
  State<TimeAccountedCurrentDateXP> createState() =>
      _TimeAccountedCurrentDateXPState();
}

class _TimeAccountedCurrentDateXPState
    extends State<TimeAccountedCurrentDateXP> {
  Future<double>? _totalFuture;
  String? _totalKey;
  String? _latestTotalKey;
  double? _latestTotal;

  Future<double> _totalFor({
    required SubcategoryTrackerDatabaseProvider sub,
    required String currentDate,
    required String currentUser,
  }) {
    final displayKey = '$currentUser-$currentDate';
    final key = '$displayKey-${sub.refreshKey}';

    if (_totalKey != key || _totalFuture == null) {
      _totalKey = key;
      _totalFuture = sub.retrieveTotalTimeSpentAllSubs(
        currentDate,
        currentUser,
      );
      _totalFuture!.then((total) {
        if (!mounted || _totalKey != key) return;
        setState(() {
          _latestTotalKey = displayKey;
          _latestTotal = total;
        });
      });
    }

    return _totalFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SubcategoryTrackerDatabaseProvider, CurrentDateProvider,
        UserUidProvider>(
      builder: (context, sub, date, user, child) {
      String formattedDate = date.getFormattedDate();

      final String? currentUser = user.userUid;
      // ✂️ add null-check guard for currentUser
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 120, height: 40);
      }

      return Padding(
        padding:
            const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // current (today's) date
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 15),
              child: Text(
                formattedDate,
                style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12, color: Colors.blueGrey),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Accounted
                FutureBuilder<double>(
                  future: _totalFor(
                    sub: sub,
                    currentDate: date.currentDate,
                    currentUser: currentUser,
                  ),
                  builder: (BuildContext context, snapshot) {
                    final currentKey = '$currentUser-${date.currentDate}';
                    final canUseCachedTotal = _latestTotalKey == currentKey &&
                        _latestTotal != null;

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !canUseCachedTotal) {
                      return const ShimmerWidget.rectangular(
                          width: 120, height: 40);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final totalTimeSpentAllSub =
                          snapshot.data ?? _latestTotal ?? 0.0;

                      final convertedAllTotalTimeSpent =
                          convertMinutesToTime(totalTimeSpentAllSub);

                      return Text(
                        "$convertedAllTotalTimeSpent\n   Accounted",
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: AppColor.tileBackgroundColor),
                      );
                    }
                  },
                ),

                // total XP earned (today)
                const XPForTheCurrentDay()
              ],
            ),
            const SizedBox.shrink(), // Add some spacing
          ],
        ),
      );
      },
    );
  }
}

// total time spent for the month in all subcategories
Widget totalMonthTimeSpent() {
  return Consumer4<SubcategoryTrackerDatabaseProvider, UserUidProvider,
          FirstAndLastDay, CurrentMonthProvider>(
      builder: (context, sub, user, dayPvd, month, child) {
    final String? currentUser = user.userUid;
    if (currentUser == null) {
      return const ShimmerWidget.rectangular(width: 120, height: 40);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
      child: CachedFutureBuilder<double>(
          cacheKey:
              'month-total-$currentUser-${dayPvd.firstDay}-${dayPvd.lastDay}-${sub.refreshKey}',
          futureFactory: () => sub.retrieveMonthTotalTimeSpent(
              currentUser, dayPvd.firstDay, dayPvd.lastDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 120, height: 40);
            } else if (snapshot.hasError) {
              return const Text("Error 355 :(");
            } else {
              final monthTotal = snapshot.data ?? 0.0;

              final convertedMonthTotal = convertMinutesToTime(monthTotal);

              return Text(
                "$convertedMonthTotal\nAccounted",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
          }),
    );
  });
}

class SubcategoryAndCurrentDayTotals extends StatefulWidget {
  const SubcategoryAndCurrentDayTotals({super.key});

  @override
  State<SubcategoryAndCurrentDayTotals> createState() =>
      _SubcategoryAndCurrentDayTotalsState();
}

class _SubcategoryAndCurrentDayTotalsState
    extends State<SubcategoryAndCurrentDayTotals> {
  final ScrollController _scrollController = ScrollController();
  Future<Map<String, double>>? _dailyTotalsFuture;
  String? _dailyTotalsKey;
  String? _latestDailyTotalsKey;
  Map<String, double> _latestDailyTotals = {};

  Future<Map<String, double>> _dailyTotalsFor({
    required SubcategoryTrackerDatabaseProvider sub,
    required String currentDate,
    required String currentUser,
    bool forceRefresh = false,
  }) {
    final displayKey = '$currentUser-$currentDate';
    final key = '$displayKey-${sub.refreshKey}';

    if (forceRefresh || _dailyTotalsKey != key || _dailyTotalsFuture == null) {
      _dailyTotalsKey = key;
      _dailyTotalsFuture =
          sub.retrieveSubcategoryTotalsForDate(currentDate, currentUser);
      _dailyTotalsFuture!.then((totals) {
        if (!mounted || _dailyTotalsKey != key) return;
        setState(() {
          _latestDailyTotalsKey = displayKey;
          _latestDailyTotals = totals;
        });
      });
    }

    return _dailyTotalsFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return // subcategory + total time spent
        Consumer4<AssignerMainProvider, SubcategoryTrackerDatabaseProvider,
            CurrentDateProvider, UserUidProvider>(
      builder: (context, active, sub, date, user, child) {
        final String? currentUser = user.userUid;
        if (currentUser == null) {
          // show placeholder while UID loads
          return buildShimmerProgress();
        }

        var activeItems = active.assignerItems;

        // generates list tiles of categories where
        // isActive = 1
        // else returns an empty widget
        final visibleItems = activeItems.where((item) {
          return item.isActive == 1 &&
              item.currentLoggedInUser == currentUser &&
              item.isArchive == 0;
        }).toList();

        final dailyTotalsKey = '$currentUser-${date.currentDate}';

        return FutureBuilder<Map<String, double>>(
          future: _dailyTotalsFor(
            sub: sub,
            currentDate: date.currentDate,
            currentUser: currentUser,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                (_latestDailyTotalsKey != dailyTotalsKey ||
                    _latestDailyTotals.isEmpty)) {
              return buildShimmerProgress();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final dailyTotals = snapshot.data ??
                (_latestDailyTotalsKey == dailyTotalsKey
                    ? _latestDailyTotals
                    : <String, double>{});

            return Scrollbar(
              radius: const Radius.circular(10.0),
              trackVisibility: true,
              controller: _scrollController,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: visibleItems.length,
                itemBuilder: (BuildContext context, index) {
                  final item = visibleItems[index];
                  final totalTimeSpentSub =
                      dailyTotals[item.subcategoryName] ?? 0.0;
                  final convertedTotalTimeSpent =
                      convertMinutesToTime(totalTimeSpentSub);

                  return ListTile(
                    title: Text(
                      item.subcategoryName,
                      style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14, fontweight: FontWeight.normal),
                    ),
                    subtitle: Text(
                      item.mainCategoryName,
                      style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12, color: Colors.blueGrey),
                    ),
                    trailing: Container(
                      width: 105,
                      height: 23,
                      decoration: BoxDecoration(
                        color: AppColor.tileBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                          child: Text(
                        convertedTotalTimeSpent,
                        style: AppTextStyle.tileElementTextStyle(),
                      )),
                    ),
                    onTap: () async {
                      final hasChangedTrackedTime = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManualTimeRecordingRoute(
                            subcategoryName: item.subcategoryName,
                            mainCategoryName: item.mainCategoryName,
                          ),
                        ),
                      );
                      if (context.mounted) {
                        setState(() {
                          _dailyTotalsFuture = _dailyTotalsFor(
                            sub: sub,
                            currentDate: date.currentDate,
                            currentUser: currentUser,
                            forceRefresh: true,
                          );
                        });
                        context
                            .read<ExperiencePointTableProvider>()
                            .refreshExperiencePointViews();
                        if (hasChangedTrackedTime == true) {
                          await maybeShowDailyXpTargetCelebration(context);
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Summary(subcategories and their totals and averages)
// returns the subcategory or main category
// ListView with scroll bar
class SubcategoryMonthTotalsAndAverages extends StatefulWidget {
  final bool isSubcategory;

  const SubcategoryMonthTotalsAndAverages(
      {super.key, required this.isSubcategory});

  @override
  State<SubcategoryMonthTotalsAndAverages> createState() =>
      _SubcategoryMonthTotalsAndAveragesState();
}

class _SubcategoryMonthTotalsAndAveragesState
    extends State<SubcategoryMonthTotalsAndAverages> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<SubcategoryTrackerDatabaseProvider, UserUidProvider,
        FirstAndLastDay>(builder: (context, sub, user, day, child) {
      final String? currentUser = user.userUid;
      // ✂️ Changed: check for null UID before using
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 100, height: 30);
      }

      return widget.isSubcategory
          ? ScrollingListBuilder(
              cacheKey:
                  'month-subcategory-list-$currentUser-${day.firstDay}-${day.lastDay}-${sub.refreshKey}',
              future: sub.retrieveMonthTotalAndAverage(
                  currentUser, day.firstDay, day.lastDay, true),
              columnName: "subcategoryName")
          : ScrollingListBuilder(
              cacheKey:
                  'month-main-list-$currentUser-${day.firstDay}-${day.lastDay}-${sub.refreshKey}',
              future: sub.retrieveMonthTotalAndAverage(
                  currentUser, day.firstDay, day.lastDay, false),
              columnName: "mainCategoryName");
    });
  }
}

// information displayed in the home page when
// there is no data in the database tables
class InfoAboutHomePageSections extends StatelessWidget {
  final String infoText;

  const InfoAboutHomePageSections({super.key, required this.infoText});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF00B0F0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // info icon

            // info text
            Flexible(
                child: Text(
              infoText,
              style: AppTextStyle.subSectionTextStyle(
                  fontsize: 15, fontweight: FontWeight.normal),
            ))
          ],
        ),
      ),
    );
  }
}
