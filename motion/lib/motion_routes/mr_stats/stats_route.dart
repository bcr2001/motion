import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_routes/mr_home/home_windows/total_acc_unacc.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_routes/mr_stats/stats_front.dart';
// import 'package:motion/motion_routes/mr_stats/stats_sections.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
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
              final String currentUser = user.userUid!;

              // depending on whether the accounted time is 0
              // or >0, a image will be shown of the screen to
              // indicate to the user that there is no data
              //  available and if data is available, then
              // the gallary windows for the years will be shown
              return FutureBuilder(
                  future: main.retrieveEntireTotalMainCategoryTable(
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
                        return SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // default display image that is shown
                              // when the page is empty
                              AppImages.noAnalysisGallary,
                          
                              // information on why it is empty
                              const InfoToTheUser(
                                  sectionInformation:
                                      AppString.infoAboutAnnualOverviewEmpty)
                            ],
                          ),
                        );
                      } else {
                        // if data is available,the analysis
                        // gallaries are displayed
                        return Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // users all time efficiency score
                              // total number of days
                              const EfficiencyAndNumberOfDays(
                                efficiencyScore: Padding(
                                  padding: EdgeInsets.only(left: 20),
                                  child: EfficienyScoreWindow(
                                  getEntireScore: true,
                                                                ),
                                ), numberOfDays: Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: NumberOfDaysMainCategory(
                                        getAllDays: true),
                                  )),

                              // displays the total time accounted 
                              // and unaccounted for the entire period
                              const TotalAccountedAndUnaccounted(
                                  getEntireTotal: true),

                              // Main Category Summary
                              sectionTitle(
                                  titleName:
                                      AppString.mainCategorySummaryTitle),


                              const CategorySummaryReport(),

                              // Yealry Report
                              sectionTitle(
                                  titleName: AppString.yearlyReportTitle),
                              const AnalysisGallery(),
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

// a generated grid view for yearly gallery
class AnalysisGallery extends StatelessWidget {
  const AnalysisGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom:50.0),
      child: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
          builder: (context, user, main, child) {
        // current user uid
        final String currentUser = user.userUid!;
    
        // returns a grid view of yearly break down gallaries
        return FutureBuilder(
            future: main.retrieveAccountedAndUnaccountedBrokenByYears(
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
                    // info to the user'
                    const InfoToTheUser(
                        sectionInformation: AppString.infoAboutGalleys),
    
                    // yearly gallary
                    GridView.builder(
                        shrinkWrap: true,
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
                              logger.i("$year clicked");
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
