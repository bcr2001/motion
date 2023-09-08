import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_screens/manual_tracking.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
import 'package:provider/provider.dart';

// title builder
Widget cardTitle({required String titleName}) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 10),
    child: Text(
      titleName,
      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600),
    ),
  );
}

// returns the total time accounted for the current date
// and the current date text to the right
Widget timeAccountedAndCurrentDate() {
  return Consumer3<SubcategoryTrackerDatabaseProvider, CurrentDateProvider,
      UserUidProvider>(
    builder: (context, sub, date, user, child) {
      String formattedDate = date.getFormattedDate();

      return Padding(
        padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Accounted
                FutureBuilder<double>(
                  future: sub.retrieveTotalTimeSpentAllSubs(
                    date.currentData,
                    user.userUid!,
                  ),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ShimmerWidget.rectangular(
                          width: 120, height: 40);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final totalTimeSpentAllSub = snapshot.data ?? 0.0;

                      final convertedAllTotalTimeSpent =
                          convertMinutesToTime(totalTimeSpentAllSub);

                      return Text(
                        "$convertedAllTotalTimeSpent\nAccounted",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                  },
                ),
                // current date
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox.shrink(), // Add some spacing
          ],
        ),
      );
    },
  );
}

Widget subcategoryAndCurrentDayTotals() {
  return // subcategory + total time spent
      Consumer4<AssignerMainProvider, SubcategoryTrackerDatabaseProvider,
          CurrentDateProvider, UserUidProvider>(
    builder: (context, active, sub, date, user, child) {
      var activeItems = active.assignerItems;

      // generates list tiles of categories where
      // isActive = 1
      // else is returns an empty widget
      return ListView.builder(
          shrinkWrap: true,
          itemCount: activeItems.length,
          itemBuilder: (BuildContext context, index) {
            return activeItems[index].isActive == 1
                ? FutureBuilder<double>(
                    future: sub.retrieveTotalTimeSpentSubSpecific(
                        date.currentData,
                        user.userUid!,
                        activeItems[index].subcategoryName),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Return a loading indicator while waiting for the data
                        return Center(
                          child: CircularProgressIndicator(
                            color: lightModeContentWidget,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        // Handle any errors here
                        return Text('Error: ${snapshot.error}');
                      } else {
                        // Data is available, use it to build the ListTile
                        final totalTimeSpentSub = snapshot.data ?? 0.0;

                        // convert total
                        final convertedTotalTimeSpent =
                            convertMinutesToTime(totalTimeSpentSub);

                        return ListTile(
                          title: Text(activeItems[index].subcategoryName),
                          trailing: Text(
                            convertedTotalTimeSpent,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManualTimeRecordingRoute(
                                  subcategoryName:
                                      activeItems[index].subcategoryName,
                                  mainCategoryName:
                                      activeItems[index].mainCategoryName,
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  )
                : const SizedBox.shrink();
          });
    },
  );
}

Widget weeklySummaryView(
    {required String startingDate, required String endingDate, avgValue = 7}) {

  // Create a UniqueKey to control the FutureBuilder
  final uniqueKey = UniqueKey();


  return Consumer3<AssignerMainProvider, UserUidProvider,
          SubcategoryTrackerDatabaseProvider>(
      builder: (context, active, user, sub, child) {
    var activeWeeklyItems = active.assignerItems;

    // generates list tiles of categories where
    // isActive = 1
    // else is returns an empty widget
    return ListView.builder(
        itemCount: activeWeeklyItems.length,
        itemBuilder: (BuildContext context, index) {
          return activeWeeklyItems[index].isActive == 1
              ? FutureBuilder(
                  key: uniqueKey,
                  future: sub.retrieveWeeklyTotalAndAverage(
                      activeWeeklyItems[index].subcategoryName,
                      user.userUid!,
                      startingDate,
                      endingDate),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: lightModeContentWidget,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      double totalAndAverage = snapshot.data!;

                      String convertedtotalAndAverage =
                          convertMinutesToTime(totalAndAverage);

                      // average
                      String average =
                          convertMinutesToHoursOnly(totalAndAverage / avgValue);

                      return totalAndAverage > 0
                          ? ListTile(
                              title: Text(
                                  activeWeeklyItems[index].subcategoryName),
                              trailing: Text(
                                convertedtotalAndAverage,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              subtitle: Text(average,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.bodySmall))
                          : const SizedBox.shrink();
                    }
                  })
              : const SizedBox.shrink();
        });
  });
}
