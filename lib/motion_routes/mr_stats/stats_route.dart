import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_routes/mr_home/home_windows/total_acc_unacc.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_routes/mr_stats/stats_front.dart';
import 'package:motion/motion_routes/route_action.dart';
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
          actions: const [MotionActionButtons()],
        ),
        body: SingleChildScrollView(
          child: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
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
                        return const _AnalyticsEmptyState();
                      } else {
                        // if data is available,the analysis
                        // gallaries are displayed
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(12, 12, 12, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AnalyticsHeroPanel(),
                              _AnalyticsSection(
                                title: "Tracked Time",
                                subtitle:
                                    "Accounted and unaccounted time across your history",
                                icon: Icons.query_stats_rounded,
                                child: TotalAccountedAndUnaccounted(
                                    getEntireTotal: true),
                              ),
                              CategorySummaryReport(),
                              _AnalyticsSection(
                                title: AppString.yearlyReportTitle,
                                subtitle:
                                    "Explore yearly trends, XP, badges, and consistency",
                                icon: Icons.calendar_month_rounded,
                                child: AnalysisGallery(),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  });
            },
          ),
        ));
  }
}

class _AnalyticsHeroPanel extends StatelessWidget {
  const _AnalyticsHeroPanel();

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(15),
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
                      "Lifetime Summary",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 18,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Your all-time performance at a glance",
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
          ),
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
                  color: AppColor.blueMainColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
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
            futureFactory: () => main.retrieveAccountedAndUnaccountedBrokenByYears(
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
