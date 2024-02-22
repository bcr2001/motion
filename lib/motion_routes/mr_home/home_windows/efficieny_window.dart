import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';

/// Displays the user's efficiency score using `ExperiencePointTableProvider`.
/// Uses `FutureBuilder` to asynchronously fetch the score and handles loading
/// and error states.
/// On successful data retrieval, it shows the calculated efficiency score.

// Get's the efficiency score of the selected year
class EfficienyScoreSelectedYear extends StatelessWidget {
  final String selectedYear;

  const EfficienyScoreSelectedYear({super.key, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperiencePointTableProvider, UserUidProvider>(
        builder: (context, xp, user, child) {
      // currently logged in user uid
      final String currentUserUid = user.userUid!;

      return FutureBuilder(
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

              return specialSectionTitleSelectedYear(mainTitleName: efficientResults.toString());
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
        mainTitleName: score,),
  );
}
