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
                    return const Center(child: CircularProgressIndicator(color: AppColor.blueMainColor,),);
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final snapshotData = snapshot.data;

                    logger.i(snapshot);

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
                      return Text("It didn't work? ");
                    }
                  }
                });
          },
        ));
  }
}
