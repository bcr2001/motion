import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
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

// A widget that displays the total number of days accounted for in
// the main_category table. It can show the total number of days for either
// all time or for a specific year, based on the value of `getAllDays`.
class NumberOfDaysMainCategory extends StatelessWidget {
  final bool getAllDays;
  const NumberOfDaysMainCategory({super.key, required this.getAllDays});

  // A helper method that creates a FutureBuilder to fetch and display the data.
  // It shows a loading indicator while waiting, an error message in case of
  // an error, and the total number of days when data is available.
  Widget _futureData({Future<dynamic>? future}) {
    return FutureBuilder(
      future: future,
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display shimmer effect while the data is being loaded
          return const ShimmerWidget.rectangular(width: 20, height: 20);
        } else if (snapshot.hasError) {
          // Display an error message if there is an error
          return Text('Error: ${snapshot.error}');
        } else {
          // Extract and display the total number of days
          final totalNumberOfDays = snapshot.data ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              "Day: $totalNumberOfDays",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
        final userUid = user.userUid; // Firebase user UID
        final currentYear = year.currentYear; // Current year

        // Decide which future to use based on the value of getAllDays
        // and call _futureData to build the UI accordingly
        return getAllDays
            ? _futureData(
                future: main.retrievedNumberOfDays(currentUser: userUid!),
              )
            : _futureData(
                future: main.retrievedNumberOfDays(
                    currentUser: userUid!,
                    currentYear: currentYear,
                    getAllDays: false),
              );
      },
    );
  }
}

// efficiency score and number of days placement
// the efficiency score and number of days placed in a row 
// space between
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
                        "$convertedAllTotalTimeSpent\n  Accounted",
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
