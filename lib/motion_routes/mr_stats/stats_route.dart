import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_awards/award_definition.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_routes/mr_home/home_windows/total_acc_unacc.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_routes/mr_stats/stats_front.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_screens/ms_daily_review/daily_review_page.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../mr_home/home_windows/efficieny_window.dart';

// stats route
class MotionStatesRoute extends StatelessWidget {
  const MotionStatesRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            AppString.statsRouteTitle,
          ),
          actions: [
            IconButton(
              tooltip: 'Daily Review',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyReviewPage(),
                ),
              ),
              icon: const Icon(Icons.calendar_view_day_rounded),
            ),
            const MotionActionButtons(),
          ],
        ),
        body: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
          builder: (context, user, main, child) {
            // current user uid
            final currentUser = user.userUid;

            if (currentUser == null) {
              return userLoadingIndicator();
            }

            // depending on whether the accounted time is 0
            // or >0, a image will be shown of the screen to
            // indicate to the user that there is no data
            //  available and if data is available, then
            // the gallary windows for the years will be shown
            return CachedFutureBuilder<double>(
                cacheKey: 'stats-entire-total-$currentUser-${main.refreshKey}',
                futureFactory: () => main.retrieveEntireTotalMainCategoryTable(
                    currentUser, false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _AnalyticsLoadingState();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final snapshotData = snapshot.data;

                    if (snapshotData! <= 0) {
                      return const _AnalyticsEmptyState();
                    } else {
                      // if data is available,the analysis
                      // gallaries are displayed
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AnalyticsHeroPanel(
                                trackedHours: snapshotData / 60,
                              ),
                              const SizedBox(height: 26),
                              const _AnalyticsSection(
                                title: "Tracked Time",
                                subtitle:
                                    "Your complete accounted and unaccounted record",
                                icon: Icons.query_stats_rounded,
                                child: TotalAccountedAndUnaccounted(
                                    getEntireTotal: true),
                              ),
                              const CategorySummaryReport(),
                              const _AnalyticsSection(
                                title: AppString.yearlyReportTitle,
                                subtitle:
                                    "Open a year to see its complete report",
                                icon: Icons.calendar_month_rounded,
                                child: AnalysisGallery(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                });
          },
        ));
  }
}

class _AnalyticsHeroPanel extends StatelessWidget {
  const _AnalyticsHeroPanel({required this.trackedHours});

  final double trackedHours;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(
          alpha: isDarkMode ? 0.10 : 0.06,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColor.accountedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColor.accountedColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lifetime Snapshot",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 18,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CurrentMilestoneAward(trackedHours: trackedHours),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
          const EfficiencyAndNumberOfDays(
            efficiencyScore: EfficienyScoreWindow(getEntireScore: true),
            numberOfDays: NumberOfDaysMainCategory(getAllDays: true),
          ),
        ],
      ),
    );
  }
}

class _CurrentMilestoneAward extends StatelessWidget {
  const _CurrentMilestoneAward({required this.trackedHours});

  final double trackedHours;

  @override
  Widget build(BuildContext context) {
    final currentAward = MotionAwards.earnedAt(trackedHours);
    final displayedAward = currentAward ?? MotionAwards.all.first;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            currentAward?.assetPath ?? displayedAward.lockedAssetPath,
            width: 150,
            height: 150,
            fit: BoxFit.contain,
            cacheWidth: 450,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 150,
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.accountedColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColor.accountedColor,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Current Milestone',
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10.5,
              fontweight: FontWeight.normal,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                currentAward?.name ?? 'No milestone earned yet',
                textAlign: TextAlign.center,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 14,
                  fontweight: FontWeight.w900,
                ),
              ),
              if (currentAward != null)
                Text(
                  '${currentAward.requiredHours}h',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w900,
                    color: AppColor.accountedColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _AnalyticsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColor.blueMainColor,
                  size: 20,
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
                        fontsize: 15,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
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
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AnalyticsLoadingState extends StatelessWidget {
  const _AnalyticsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: const [
        MotionPanel(
          padding: EdgeInsets.all(18),
          child: SizedBox(
            height: 112,
            child: Center(
              child: CircularProgressIndicator(color: AppColor.blueMainColor),
            ),
          ),
        ),
        SizedBox(height: 28),
        ShimmerWidget.rectangular(width: double.infinity, height: 84),
        SizedBox(height: 28),
        ShimmerWidget.rectangular(width: double.infinity, height: 220),
      ],
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.78,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 180,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AppImages.noAnalysisGallary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No Analytics Yet",
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 18,
                fontweight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppString.infoAboutAnnualOverviewEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// a generated grid view for yearly gallery
class AnalysisGallery extends StatelessWidget {
  const AnalysisGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
          builder: (context, user, main, child) {
        // current user uid
        final currentUser = user.userUid;

        if (currentUser == null) {
          return userLoadingIndicator();
        }

        // returns a grid view of yearly break down gallaries
        return CachedFutureBuilder<List<Map<String, dynamic>>>(
            cacheKey: 'annual-gallery-$currentUser-${main.refreshKey}',
            futureFactory: () =>
                main.retrieveAccountedAndUnaccountedBrokenByYears(
                    currentUser: currentUser),
            builder: ((context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading state: Show a shimmer effect while data is being loaded.
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                // Error state: Display an error message if there's an issue with data retrieval.
                return const Text("Error 355 :(");
              } else {
                final dataResults = snapshot.data!;

                return Column(
                  children: [
                    // yearly gallary
                    GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                mainAxisExtent: 100,
                                crossAxisCount: 3,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5),
                        itemCount: dataResults.length,
                        itemBuilder: (context, index) {
                          // accounted total for the year in hours
                          final double accountedYearTotal =
                              dataResults[index]["Accounted"];
                          final String accountedYearTotalString =
                              accountedYearTotal.toStringAsFixed(2);

                          // accounted total for the year in days
                          final double accountedDaysTotal =
                              accountedYearTotal / 24;
                          final String accountedDaysTotalString =
                              accountedDaysTotal.toStringAsFixed(2);

                          // unaccounted total for the year in hours
                          final double unaccountedYearTotal =
                              dataResults[index]["Unaccounted"];
                          final String unaccountedYearTotalString =
                              unaccountedYearTotal.toStringAsFixed(2);

                          // unaccounted total for the years in days
                          final double unaccountedDaysTotal =
                              unaccountedYearTotal / 24;
                          final String unaccountedDaysTotalString =
                              unaccountedDaysTotal.toStringAsFixed(2);

                          // year
                          final String year = dataResults[index]["Year"];

                          return AnnualGallaryBuilder(
                            gallaryYear: year,
                            onTap: () {
                              debugLog("$year clicked");
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (BuildContext context) {
                                return YearsWorthOfSummaryStatitics(
                                  year: year,
                                  accountedDays: accountedDaysTotalString,
                                  accountedHours: accountedYearTotalString,
                                  unaccountedDays: unaccountedDaysTotalString,
                                  unaccountedHours: unaccountedYearTotalString,
                                );
                              }));
                            },
                          );
                        })
                  ],
                );
              }
            }));
      }),
    );
  }
}
