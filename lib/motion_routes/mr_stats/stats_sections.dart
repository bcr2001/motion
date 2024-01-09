import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';



// Section 2: Main Category Overview
// the hours, days, and average time spent on the 5 main categories
class YearMainCategoryOveriew extends StatelessWidget {
  final String year;

  const YearMainCategoryOveriew({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    // get the screen height of the device
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, sub, child) {
      // currently logged in user
      final String currentUser = user.userUid!;

      // if the total amount of time for the current
      // month is 0, then the summary page info
      // is displayed
      return FutureBuilder(
          future: sub.retrieveMonthTotalAndAverage(
              currentUser, "$year-01-01", "$year-12-31", false),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                height: screenHeight * 0.42,
                child: Card(
                  child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshotData!.length,
                      itemBuilder: (BuildContext context, index) {
                        // single item index
                        final singleItem = snapshotData[index];

                        // main category name
                        final String mainCatName =
                            singleItem["mainCategoryName"];

                        // total minuted converted to hours and minutes
                        final convertedTotal =
                            convertMinutesToTime(singleItem["total"]);

                        // average minutes converted to time
                        final convertedAverage =
                            convertMinutesToHoursMonth(singleItem["average"]);

                        // number of days
                        String numberOfDays =
                            convertMinutesToDays(singleItem["total"]);

                        return ListTile(
                          leading: Text(mainCatName,
                              style: AppTextStyle.leadingTextLTStyle()),
                          title: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColor.tileBackgroundColor),
                              child: Center(
                                child: Text(
                                  convertedTotal,
                                  style: AppTextStyle.tileElementTextStyle(),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                          subtitle: Text(
                            numberOfDays,
                            style: const TextStyle(
                                color: AppColor.tileBackgroundColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(convertedAverage,
                              style: AppTextStyle.leadingStatsTextLTStyle()),
                        );
                      }),
                ),
              );
            }
          });
    });
  }
}


// SECTION 4: HIGHEST TRACKED TIME
// highest time tracked per subcategory
// for the entire year. 
class YearHighestTrackedTimePerSubcategory extends StatelessWidget {
  final String year;

  const YearHighestTrackedTimePerSubcategory({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, sub, child) {
      final String currentUserUid = user.userUid!;

      return GridHighestTrackedSubcategory(
          future: sub.retrieveHighestTrackedTimePerSubcategory(
              currentUser: currentUserUid,
              firstDay: "$year-01-01",
              lastDay: "$year-12-31"));
    });
  }
}