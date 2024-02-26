import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../../../motion_themes/mth_styling/app_color.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';

/// Displays the user's efficiency score using `ExperiencePointTableProvider`.
/// Uses `FutureBuilder` to asynchronously fetch the score and handles loading
/// and error states.
/// On successful data retrieval, it shows the calculated efficiency score.

/// Get's the efficiency score for the selected date on the report
/// page heat map section
class EfficienyScoreSelectedDay extends StatelessWidget {
  final String selectedDay;

  const EfficienyScoreSelectedDay({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperiencePointTableProvider, UserUidProvider>(
        builder: (context, xp, user, child) {
      // currently logged in user uid
      final String userUID = user.userUid!;

      return FutureBuilder(
          future: xp.retrieveDailyExperiencePoints(
              currentUser: userUID, selectedDate: selectedDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 50, height: 30);
            } else if (snapshot.hasError) {
              return const Text("N/A");
            } else {
              final resultSnapShot = snapshot.data!;
              final String resultString = resultSnapShot.toString();

              logger.i("xp earned = $resultSnapShot");

              return Text(
                "$resultString XP",
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            }
          });
    });
  }
}

// Get's the xp earned for the current day being tracked
class XPForTheCurrentDay extends StatelessWidget {
  const XPForTheCurrentDay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, CurrentDateProvider,
        UserUidProvider>(builder: (context, xp, date, user, child) {
      // current date
      final today = date.currentDate;

      // currently logged in user uid
      final currentUserUid = user.userUid!;

      return FutureBuilder(
          future: xp.retrieveDailyExperiencePoints(
              currentUser: currentUserUid, selectedDate: today),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 120, height: 40);
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final totalXPEarned = snapshot.data ?? 0;

              return Text(
                " $totalXPEarned XP\nEarned",
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppColor.tileBackgroundColor),
              );
            }
          });
    });
  }
}

// Get's the efficiency score of the selected year or month
class EfficienyScoreSelectedYearOrMont extends StatelessWidget {
  final String selectedYear;
  final bool getSelectedYearEfs;

  const EfficienyScoreSelectedYearOrMont(
      {super.key,
      required this.selectedYear,
      required this.getSelectedYearEfs});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        FirstAndLastDay>(builder: (context, xp, user, fal, child) {
      // currently logged in user uid
      final String currentUserUid = user.userUid!;

      // the first and last day of the current month
      String firstDayOfMonth = fal.firstDay;
      String lastDayOfMonth = fal.lastDay;

      return getSelectedYearEfs
          ? FutureBuilder(
              future: xp.retrieveYearExperiencePointsEfficiencyScore(
                  currentUser: currentUserUid, currentYear: selectedYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  final efficientResults = resultSnapShot / 100;

                  logger.i(
                      "Total Efficiency Score for $selectedYear: $resultSnapShot");

                  return specialSectionTitleSelectedYear(
                      mainTitleName: efficientResults.toString());
                }
              })
          : FutureBuilder(
              future: xp.retrieveMonthlyEfficiencyScore(
                  currentUser: currentUserUid,
                  firstDayOfMonth: firstDayOfMonth,
                  lastDayOfMonth: lastDayOfMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  final efficientResults = resultSnapShot / 100;

                  logger.i(
                      "Total Efficiency Score for $selectedYear: $resultSnapShot");

                  return specialSectionTitleSelectedYear(
                      mainTitleName: efficientResults.toString());
                }
              });
    });
  }
}

// Gets the entire efficieny score or the efficiency score of the
// current year
class EfficienyScoreWindow extends StatelessWidget {
  final bool getEntireScore;
  const EfficienyScoreWindow({super.key, required this.getEntireScore});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider>(builder: ((context, xp, user, year, child) {
      final String currentUser = user.userUid!;
      final String currentYear = year.currentYear;

      return getEntireScore
          ? FutureBuilder(
              future: xp.retrieveExperiencePointsEfficiencyScore(
                  currentUser: currentUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  final efficientResults = resultSnapShot / 100;

                  logger.i("Total Efficiency Score: $resultSnapShot");

                  return efficiencySection(
                      score: "$efficientResults", getEntire: false);
                }
              })
          : FutureBuilder(
              future: xp.retrieveYearExperiencePointsEfficiencyScore(
                  currentUser: currentUser, currentYear: currentYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(width: 50, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final resultSnapShot = snapshot.data ?? 0.0;

                  final efficientResults = resultSnapShot / 100;

                  logger.i("Total Efficiency Score: $resultSnapShot");

                  return efficiencySection(
                      score: "$efficientResults", getEntire: true);
                }
              });
    }));
  }
}

// database calculated efficiency score and title
Widget efficiencySection({required String score, required bool getEntire}) {
  return Container(
    margin: const EdgeInsets.only(left: 10),
    alignment: Alignment.topLeft,
    child: specialSectionTitleEFS(
      getEntire: getEntire,
      mainTitleName: score,
    ),
  );
}

/// A widget that builds and displays the most or least productive day.
/// It uses a FutureBuilder to asynchronously fetch data about the productive day.
/// - `productiveMessage`: A string to display the type of productive day (most or least).
/// - `future`: The future that fetches the productive day data.
/// This widget handles different states like loading, error, and data display.
/// It shows a shimmer effect while loading and displays the productive day once data is fetched.
class ProductiveDayBuilder extends StatelessWidget {
  final String productiveMessage;
  final Future<dynamic>? future;

  const ProductiveDayBuilder(
      {super.key, required this.productiveMessage, this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerWidget.rectangular(width: 100, height: 30);
          } else if (snapshot.hasError) {
            return const Text("N/A");
          } else {
            final resultSnapShot = snapshot.data;

            // (most/least) productive date
            final String date = resultSnapShot[0]["date"];

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "$productiveMessage .............................................. $date",
                style: AppTextStyle.tileElementTextStyle(),
              ),
            );
          }
        });
  }
}

/// A widget that determines and builds either the most or least productive day.
/// It uses Consumer3 to listen to changes from ExperiencePointTableProvider,
///  UserUidProvider, and FirstAndLastDay.
/// - `getMostProductiveDay`: A boolean to decide if fetching the most
///  productive day (`true`) or the least (`false`).
/// Depending on `getMostProductiveDay`, it fetches and displays the relevant
///  productive day using `ProductiveDayBuilder`. It provides the necessary
///  parameters like the user's UID and the first and last day of the current
///  month to the `ProductiveDayBuilder`.
class MostAndLeastProductiveDayBuilder extends StatelessWidget {
  final bool getMostProductiveDay;

  const MostAndLeastProductiveDayBuilder(
      {super.key, required this.getMostProductiveDay});

  @override
  Widget build(BuildContext context) {
    return getMostProductiveDay
        ? Consumer3<ExperiencePointTableProvider, UserUidProvider,
            FirstAndLastDay>(builder: (context, xp, user, firstAndLast, child) {
            // currently logged in user uid
            final String currentUserUid = user.userUid!;

            // first and last day of the current month
            final String firstDayOfMonth = firstAndLast.firstDay;
            final String lastDayOfMonth = firstAndLast.lastDay;

            return ProductiveDayBuilder(
              productiveMessage: AppString.mostProductiveDay,
              future: xp.retrieveMostAndLeastProductiveDays(
                  currentUser: currentUserUid,
                  firstDay: firstDayOfMonth,
                  lastDay: lastDayOfMonth,
                  getMostProductiveDay: true),
            );
          })
        : Consumer3<ExperiencePointTableProvider, UserUidProvider,
            FirstAndLastDay>(builder: (context, xp, user, firstAndLast, child) {
            // currently logged in user uid
            final String currentUserUid = user.userUid!;

            // first and last day of the current month
            final String firstDayOfMonth = firstAndLast.firstDay;
            final String lastDayOfMonth = firstAndLast.lastDay;

            return ProductiveDayBuilder(
              productiveMessage: AppString.leastProductiveDay,
              future: xp.retrieveMostAndLeastProductiveDays(
                  currentUser: currentUserUid,
                  firstDay: firstDayOfMonth,
                  lastDay: lastDayOfMonth,
                  getMostProductiveDay: false),
            );
          });
  }
}
