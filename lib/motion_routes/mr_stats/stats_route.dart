import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_stats/stats_back.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';

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
        body: Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
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
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // default display image that is shown when the page is empty
                          AppImages.noAnalysisGallary,

                          // information on why it is empty
                          const InfoToTheUser(
                              sectionInformation:
                                  AppString.infoAboutAnnualOverviewEmpty)
                        ],
                      );
                    } else {
                      // if data is available, the the analysis gallaries are displayed
                      return const AnalysisGallery();
                    }
                  }
                });
          },
        ));
  }
}

// a generated grid view for yearly gallery
class AnalysisGallery extends StatelessWidget {
  const AnalysisGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
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

              logger.i(dataResults);

              return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemCount: dataResults.length,
                  itemBuilder: (context, index) {
                    // accounted total for the year
                    final double accountedYearTotal =
                        dataResults[index]["Accounted"];

                    // unaccounted total for the year
                    final double unaccountedYearTotal =
                        dataResults[index]["Unaccounted"];

                    // year
                    final String year = dataResults[index]["Year"];

                    return AnnualGallaryBuilder(
                        accountedTotal: accountedYearTotal.toStringAsFixed(2),
                        unaccountedTotal:
                            unaccountedYearTotal.toStringAsFixed(2),
                        gallaryYear: year,
                        onTap: () {
                          logger.i("$year clicked");
                        });
                  });
            }
          }));
    });
  }
}
