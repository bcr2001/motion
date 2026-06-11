import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, CurrentDateProvider,
        UserUidProvider>(builder: (context, xp, date, user, child) {
      // current date
      final today = date.currentDate;

      // currently logged in user uid
      final String? currentUserUid = user.userUid;
      if (currentUserUid == null) {
        // still loading or not signed in—show same shimmer
        return const ShimmerWidget.rectangular(width: 120, height: 40);
      }

      return CachedFutureBuilder<int>(
          cacheKey: 'today-xp-$currentUserUid-$today-${xp.refreshKey}',
          futureFactory: () => xp.retrieveDailyExperiencePoints(
              currentUser: currentUserUid, selectedDate: today),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 120, height: 40);
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final totalXPEarned = snapshot.data ?? 0;

              return Text(
                " $totalXPEarned XP\nEarned",
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppColor.accountedColor),
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

// EFS Current Year Display
// Displays the current year EFS, and correnponding badge
class CurrentYearEFSDisplay extends StatelessWidget {
  final double score;
  final bool isEntire;

  const CurrentYearEFSDisplay(
      {super.key, required this.score, required this.isEntire});

  Future<NextBadgeProgress> _loadNextBadgeProgress({
    required ExperiencePointTableProvider xpProvider,
    required String currentUser,
    required String currentYear,
  }) async {
    final totalXp = await xpProvider.retrieveTotalXP(
      currentUser: currentUser,
      isEntire: false,
      year: currentYear,
    );
    final trackedDays = await xpProvider.retrieveYearExperiencePointDays(
      currentUser: currentUser,
      year: currentYear,
    );

    return EfsBadgePolicy.nextBadgeProgress(
      currentScore: score,
      currentYearXp: totalXp,
      trackedDays: trackedDays,
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
        Consumer3<ExperiencePointTableProvider, UserUidProvider,
            CurrentYearProvider>(builder: (context, xps, user, year, child) {
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

                  return Text(
                    "$snapResults XP",
                    style: AppTextStyle.accountedAndUnaccountedGallaryStyle(
                        fontsize: 22, fontweight: FontWeight.w900),
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
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider>(builder: (context, xp, user, year, child) {
      final String? currentUser = user.userUid;
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 160, height: 24);
      }

      final currentYear = year.currentYear;

      return CachedFutureBuilder<NextBadgeProgress>(
          cacheKey:
              'next-badge-progress-$currentUser-$currentYear-$score-${xp.refreshKey}',
          futureFactory: () => _loadNextBadgeProgress(
                xpProvider: xp,
                currentUser: currentUser,
                currentYear: currentYear,
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
