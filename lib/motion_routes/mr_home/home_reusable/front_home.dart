import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_routes/manual_tracking.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';

// total all time accounted for and unaccounted for
Widget entireTimeAccountedAndUnaccounted(
    {required Future<dynamic> future,
    required String resultName,
    required TextStyle dayStyle,
    required TextStyle hoursStyle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // table result (accounted/ unaccounted)
        FutureBuilder(
            future: future,
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

// returns the number of days in the main_category table
Widget numberOfDaysMainCategory() {
  // main enables access to the SQL query to get the number of days
  // user provider allows us to get the currently logged in user
  return Consumer2<MainCategoryTrackerProvider, UserUidProvider>(
      builder: (context, main, user, child) {
    // firebase user uid
    final userUid = user.userUid;

    return FutureBuilder(
        future: main.retrievedNumberOfDays(userUid!),
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // shimmer effect is displayed while the data is being loaded
            return const ShimmerWidget.rectangular(width: 20, height: 20);
          } else if (snapshot.hasError) {
            // if the result has an error the error message is shown
            return Text('Error: ${snapshot.error}');
          } else {
            // the reult from the database
            // if empty the default value is 0
            final totalNumberOfDays = snapshot.data ?? 0;


            // a text widget to display it on the screen
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "Day: $totalNumberOfDays",
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            );
          }
        });
  });
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
                    date.currentDate,
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
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: AppColor.tileBackgroundColor),
                      );
                    }
                  },
                ),
                // current date
                Text(
                  formattedDate,
                  style: AppTextStyle.specialSectionTitleTextStyle(),
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

// total time spent for the month in all subcategories
Widget totalMonthTimeSpent() {
  return Consumer4<SubcategoryTrackerDatabaseProvider, UserUidProvider,
          FirstAndLastDay, CurrentMonthProvider>(
      builder: (context, sub, user, dayPvd, month, child) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
      child: FutureBuilder<double>(
          future: sub.retrieveMonthTotalTimeSpent(
              user.userUid!, dayPvd.firstDay, dayPvd.lastDay),
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

  @override
  Widget build(BuildContext context) {
    return // subcategory + total time spent
        Consumer4<AssignerMainProvider, SubcategoryTrackerDatabaseProvider,
            CurrentDateProvider, UserUidProvider>(
      builder: (context, active, sub, date, user, child) {
        var activeItems = active.assignerItems;

        // generates list tiles of categories where
        // isActive = 1
        // else returns an empty widget
        return Scrollbar(
          radius: const Radius.circular(10.0),
          trackVisibility: true,
          controller: _scrollController,
          child: ListView.builder(
              padding: EdgeInsets.zero,
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: activeItems.length,
              itemBuilder: (BuildContext context, index) {
                return (activeItems[index].isActive == 1 &&
                        activeItems[index].currentLoggedInUser ==
                            user.userUid &&
                        activeItems[index].isArchive == 0)
                    ? FutureBuilder<double>(
                        future: sub.retrieveTotalTimeSpentSubSpecific(
                            date.currentDate,
                            user.userUid!,
                            activeItems[index].subcategoryName),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Return a loading indicator while waiting for the data
                            return buildShimmerProgress();
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
                              title: Text(
                                activeItems[index].subcategoryName,
                                style: AppTextStyle.leadingTextLTStyle(),
                              ),
                              subtitle: Text(
                                activeItems[index].mainCategoryName,
                                style:
                                    AppTextStyle.specialSectionTitleTextStyle(),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ManualTimeRecordingRoute(
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
              }),
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
      return widget.isSubcategory
          ? ScrollingListBuilder(
              future: sub.retrieveMonthTotalAndAverage(
                  user.userUid!, day.firstDay, day.lastDay, true),
              columnName: "subcategoryName")
          : ScrollingListBuilder(
              future: sub.retrieveMonthTotalAndAverage(
                  user.userUid!, day.firstDay, day.lastDay, false),
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
              style: AppTextStyle.infoTextStyle(),
            ))
          ],
        ),
      ),
    );
  }
}
