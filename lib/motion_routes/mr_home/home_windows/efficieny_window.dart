import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../../motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';


/// Displays the user's efficiency score using `ExperiencePointTableProvider`.
/// Uses `FutureBuilder` to asynchronously fetch the score and handles loading and error states.
/// On successful data retrieval, it shows the calculated efficiency score.
class EfficienyScoreWindow extends StatelessWidget {
  const EfficienyScoreWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperiencePointTableProvider, UserUidProvider>(
        builder: ((context, xp, user, child) {
      final String currentUser = user.userUid!;

      return FutureBuilder(
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

              return efficiencySection(score: "$efficientResults");
            }
          });
    }));
  }
}


// database calculated efficiency score and title
Widget efficiencySection({required String score}) {
  return Container(
    alignment: Alignment.topRight,
    child: Column(
      children: [
        // efficienty score
        Text(
          score,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),

        // efficiency score title
        Text(
          AppString.efficiencyScoreTitle,
          style: AppTextStyle.tileElementTextStyle(),
        )
      ],
    ),
  );
}
