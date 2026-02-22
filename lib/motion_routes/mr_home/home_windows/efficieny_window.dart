import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_tips/badge_assignment.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
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
        final String? userUID = user.userUid;
        if (userUID == null) {
          // still loading SharedPreferences, or not signed in yet
          return const ShimmerWidget.rectangular(width: 50, height: 30);
        }

      return FutureBuilder(
          future: xp.retrieveDailyExperiencePoints(
              currentUser: userUID, selectedDate: selectedDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 50, height: 30);
            } else if (snapshot.hasError) {
              return const Text("N/A");
            } else {
              final resultSnapShot = snapshot.data ?? 0;
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
        final String? currentUserUid = user.userUid;
        if (currentUserUid == null) {
          // still loading or not signed in—show same shimmer
          return const ShimmerWidget.rectangular(width: 120, height: 40);
        }

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
                    color: AppColor.accountedColor),
              );
            }
          });
    });
  }
}

// Get's the efficiency score of the selected year or month
class EfficienyScoreSelectedYearOrMonth extends StatelessWidget {
  final String selectedYear;
  final bool getSelectedYearEfs;

  const EfficienyScoreSelectedYearOrMonth(
      {super.key,
      required this.selectedYear,
      required this.getSelectedYearEfs});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        FirstAndLastDay>(builder: (context, xp, user, fal, child) {

      // currently logged in user uid
        final String? currentUserUid = user.userUid;
      if (currentUserUid == null) {
        // still loading or not signed in—show placeholder
        return const ShimmerWidget.rectangular(width: 50, height: 30);
      }

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

// Returns the overall efficiency score or the efficiency score for the current year.
 class EfficienyScoreWindow extends StatelessWidget {
  final bool getEntireScore;
  const EfficienyScoreWindow({super.key, required this.getEntireScore});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider>(builder: ((context, xp, user, year, child) {

      final String? currentUser = user.userUid;
      if (currentUser == null) {
          // still loading or not signed in — show placeholder
          return const ShimmerWidget.rectangular(width: 50, height: 30);
      }

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
                      score: "$efficientResults", getEntire: true);
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

                  return CurrentYearEFSDisplay(
                      score: efficientResults, isEntire: false);
                }
              });
    }));
  }
}

// EFS Current Year Display
// Displays the current year EFS, and correnponding badge
class CurrentYearEFSDisplay extends StatelessWidget {
  final double score;
  final bool isEntire;

  const CurrentYearEFSDisplay(
      {super.key, required this.score, required this.isEntire});

  // efs and total XP strcuture
  Widget _efsAndTotalXp(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // efs score for the current year
        efficiencySection(score: "$score", getEntire: isEntire),

        // total XP for the current year
        Consumer3<ExperiencePointTableProvider, UserUidProvider,
            CurrentYearProvider>(builder: (context, xps, user, year, child) {
          // current user that's logged in
          final String? currentUser = user.userUid;
          if (currentUser == null) {
            // still loading or not signed in—show placeholder
            return const ShimmerWidget.rectangular(
                width: 100, height: 30);
          }

          final String currentYear = year.currentYear;

          return FutureBuilder(
              future: xps.retrieveTotalXP(
                  currentUser: currentUser,
                  isEntire: isEntire,
                  year: currentYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerWidget.rectangular(
                      width: 100, height: 30);
                } else if (snapshot.hasError) {
                  return const Text("N/A");
                } else {
                  final snapResults = snapshot.data ?? 0;

                  logger.i("Total XP for Current Year: $snapResults");

                  return Text(
                    "$snapResults XP",
                    style: AppTextStyle.accountedAndUnaccountedGallaryStyle(
                        fontsize: 22,
                        fontweight: FontWeight.w900),
                  );
                }
              });
        })
      ],
    );
  }

  // badge and name
  Widget _badgetAndName({required Image badge}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // badge
        badge,

        // name
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            AppString.badgeTitle,
            style: AppTextStyle.subSectionTextStyle(fontsize: 14),
          ),
        )
      ],
    );
  }

  // badge assignment depending on score
  Widget _getBadge(double score) {
    // the reason for converting the score is to get
    // the appropriate score categories to assign badges
    final double standardScore = score * 100;

    if (standardScore >= 0 && standardScore <= 24) {
      return _badgetAndName(badge: AppImages.sloth);
    } else if (standardScore >= 25 && standardScore <= 49) {
      return _badgetAndName(badge: AppImages.dolphine);
    } else if (standardScore >= 50 && standardScore <= 74) {
      return _badgetAndName(badge: AppImages.eagle);
    } else if (standardScore >= 75 && standardScore <= 99) {
      return _badgetAndName(badge: AppImages.dragon);
    } else if (standardScore == 100) {
      return const Text("Time Wizard");
    } else {
      return const Text("Error :()");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight*0.20,
      width: screenWidth*0.60,
      child: Card(
        elevation: 0,
        child: Center(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // efs and total XP for current year
                _efsAndTotalXp(context),
              
                // BADGE depending on score
                // When the badge is double tapped, it navigates to a page that displays 
                // the badge assignment criteria 
                GestureDetector(
                  onDoubleTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BadgeAssignment())
                      );
                  },
                  child: _getBadge(score),)
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// database calculated efficiency score and title
Widget efficiencySection({required String score, required bool getEntire}) {
  return Container(
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
  final String varableName;

  const ProductiveDayBuilder(
      {super.key,
      required this.productiveMessage,
      this.future,
      required this.varableName});

  Widget _productiveDisplay(
      {required String productiveMessage, required String date}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // productive message
        Text(
          productiveMessage,
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        ),

        // dots separator
        Text(
          " ....................................... ",
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        ),

        // date
        Text(
          date,
          style: AppTextStyle.subSectionTextStyle(
              fontsize: 12, color: Colors.blueGrey),
        )
      ],
    );
  }

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
            final resultSnapShot = snapshot.data ?? [];

            logger.i(resultSnapShot);

            // (most/least) productive date
            final String date = resultSnapShot[0][varableName];

            return Padding(
                padding: const EdgeInsets.all(10.0),
                child: _productiveDisplay(
                    productiveMessage: productiveMessage, date: date)
                // Text(
                //   "$productiveMessage ....................................... $date",
                //   style: AppTextStyle.alertDialogElevatedButtonTextStyle(),
                // ),
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
              varableName: 'date',
            );
          })
        : Consumer3<ExperiencePointTableProvider, UserUidProvider,
            FirstAndLastDay>(builder: (context, xp, user, firstAndLast, child) {
            // currently logged in user uid
            final String? currentUserUid = user.userUid;
            if (currentUserUid == null) {
              return const ShimmerWidget.rectangular(
                  width: 100, height: 30);
            }

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
              varableName: 'date',
            );
          });
  }
}

// Most and Least Productive Month Builder
class MostAndLeastProductiveMonthBuilder extends StatelessWidget {
  final bool getMostProductiveMonth;
  final String year;

  const MostAndLeastProductiveMonthBuilder(
      {super.key, required this.getMostProductiveMonth, required this.year});

  @override
  Widget build(BuildContext context) {
    return getMostProductiveMonth
        ? Consumer2<ExperiencePointTableProvider, UserUidProvider>(
            builder: (context, xp, user, child) {
            // currently logged in user uid
            final String currentUserUid = user.userUid!;

            return ProductiveDayBuilder(
              productiveMessage: AppString.mostProductiveMonth,
              future: xp.retrieveMostAndLeastProductiveMonths(
                  getMostProductiveMonth: getMostProductiveMonth,
                  currentUser: currentUserUid,
                  year: year),
              varableName: 'month',
            );
          })
        : Consumer2<ExperiencePointTableProvider, UserUidProvider>(
            builder: (context, xp, user, child) {
            // currently logged in user uid
             final String? currentUserUid = user.userUid;
            if (currentUserUid == null) {
                return const ShimmerWidget.rectangular(
                    width: 100, height: 30);
            }

            return ProductiveDayBuilder(
              productiveMessage: AppString.leastProductiveMonth,
              future: xp.retrieveMostAndLeastProductiveMonths(
                  getMostProductiveMonth: getMostProductiveMonth,
                  currentUser: currentUserUid,
                  year: year),
              varableName: 'month',
            );
          });
  }
}
