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
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/shared_pvd/share.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';
import '../home_windows/efficieny_window.dart';

//Displays a life progress bar based on a user's birthdate.
class LifeCompleted extends StatelessWidget {
  const LifeCompleted({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidget = MediaQuery.of(context).size.width;

    return Consumer2<CurrentYearProvider, UserUidProvider>(
        builder: (context, year, user, child) {
      // current year
      final currentYear = year.currentYear;

      // user uid
      final currentUser = user.userUid;

      final dateOfBirthStorage = DateOfBirthStorage();

      return FutureBuilder<DateTime?>(
        future: currentUser != null ? dateOfBirthStorage.getDateOfBirth(currentUser) : Future.value(null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerWidget.rectangular(width: 50, height: 30);
          } else if (snapshot.hasError) {
            return const Text("N/A");
          } else {
            // date
            final date = snapshot.data;

            if (date == null) {
              return const SizedBox();
            } else {
              // year born
              final yearBorn = int.parse(date.year.toString());

              // age
              final currentAge = int.parse(currentYear) - yearBorn;

              // (current age/ life expectance age) = life_completed
              final double lifeCompleted = currentAge / 72.6;

              final String lifeCompletedPercent =
                  (lifeCompleted * 100).toStringAsFixed(2);

              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Row(
                  children: [
                    // progress indicator
                    LinearPercentIndicator(
                      animation: true,
                      center: Text(
                        "$lifeCompletedPercent%",
                        style: AppTextStyle.subSectionTextStyle(fontsize: 11),
                      ),
                      width: screenWidget * 0.5,
                      lineHeight: 20,
                      barRadius: const Radius.circular(20),
                      percent: lifeCompleted,
                      progressColor: AppColor.accountedColor,
                      backgroundColor: Colors.grey.withAlpha(200),
                    ),

                    // life
                    Text(
                      AppString.lifeTitle,
                      style: AppTextStyle.subSectionTextStyle(fontsize: 12.5),
                    )
                  ],
                ),
              );
            }
          }
        },
      );
    });
  }
}

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

  // displayes the number of days and the percent of the year completed
  Widget _numberOfDaysAndPercentCompleted(
      {required String numberOfDays, required String percentCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          // percent completed
          Text(
            "$percentCompleted%",
            style: AppTextStyle.resultTitleStyle(false),
            textAlign: TextAlign.right,
          ),

          // number of days
          Text(
            "Day: $numberOfDays/365",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          // completed
          Text(
            "Completed",
            style: AppTextStyle.resultTitleStyle(false),
            textAlign: TextAlign.left,
          )
        ],
      ),
    );
  }

  // A helper method that creates a FutureBuilder to fetch and display the data.
  // It shows a loading indicator while waiting, an error message in case of
  // an error, and the total number of days when data is available.
  Widget _futureData({Future<dynamic>? future, required bool percent}) {
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

          // percent of days completed
          final percentCompleted = (totalNumberOfDays / 365) * 100;
          final percentCompletedFormatted2 =
              double.parse(percentCompleted.toStringAsFixed(2)).toString();

          return percent
              ? _numberOfDaysAndPercentCompleted(
                  numberOfDays: totalNumberOfDays.toString(),
                  percentCompleted: percentCompletedFormatted2)
              : Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    "Day: $totalNumberOfDays",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
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
        final String? userUid = user.userUid;

        // ✂️ Changed: check for null UID before proceeding
        if (userUid == null) {
          // show placeholder until UID is available
          return const ShimmerWidget.rectangular(width: 50, height: 30);
        }
        final currentYear = year.currentYear; // Current year

        // Decide which future to use based on the value of getAllDays
        // and call _futureData to build the UI accordingly
        return getAllDays
            ? _futureData(
                future: main.retrievedNumberOfDays(currentUser: userUid!),
                percent: false)
            : _futureData(
                future: main.retrievedNumberOfDays(
                    currentUser: userUid,
                    currentYear: currentYear,
                    getAllDays: false),
                percent: true);
      },
    );
  }
}

// Arranges the efficiency score and number of days in a horizontal layout with spacing.
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
Widget timeAccountedCurrentDateXP() {
  return Consumer3<SubcategoryTrackerDatabaseProvider, CurrentDateProvider,
      UserUidProvider>(
    builder: (context, sub, date, user, child) {
      String formattedDate = date.getFormattedDate();

      final String? currentUser = user.userUid;
      // ✂️ add null-check guard for currentUser
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 120, height: 40);
      }


      return Padding(
        padding:
            const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // current (today's) date
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 15),
              child: Text(
                formattedDate,
                style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12, color: Colors.blueGrey),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Accounted
                FutureBuilder<double>(
                  future: sub.retrieveTotalTimeSpentAllSubs(
                    date.currentDate,
                    currentUser,
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
                        "$convertedAllTotalTimeSpent\n   Accounted",
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: AppColor.tileBackgroundColor),
                      );
                    }
                  },
                ),

                // total XP earned (today)
                const XPForTheCurrentDay()
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

    final String? currentUser = user.userUid;
      if (currentUser == null) {
        return const ShimmerWidget.rectangular(width: 120, height: 40);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
      child: FutureBuilder<double>(
          future: sub.retrieveMonthTotalTimeSpent(
              currentUser, dayPvd.firstDay, dayPvd.lastDay),
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

         final String? currentUser = user.userUid;
        if (currentUser == null) {
          // show placeholder while UID loads
          return buildShimmerProgress();
        }

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
                            currentUser &&
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
                                style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 14,
                                    fontweight: FontWeight.normal),
                              ),
                              subtitle: Text(
                                activeItems[index].mainCategoryName,
                                style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 12, color: Colors.blueGrey),
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

      final String? currentUser = user.userUid;
        // ✂️ Changed: check for null UID before using
        if (currentUser == null) {
          return const ShimmerWidget.rectangular(width: 100, height: 30);
      }
   
      return widget.isSubcategory
          ? ScrollingListBuilder(
              future: sub.retrieveMonthTotalAndAverage(
                  currentUser, day.firstDay, day.lastDay, true),
              columnName: "subcategoryName")
          : ScrollingListBuilder(
              future: sub.retrieveMonthTotalAndAverage(
                  currentUser, day.firstDay, day.lastDay, false),
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
              style: AppTextStyle.subSectionTextStyle(fontsize: 15, fontweight: FontWeight.normal),
            ))
          ],
        ),
      ),
    );
  }
}
