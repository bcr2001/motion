import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/ru_home.dart';
import 'package:motion/motion_screens/manual_tracking.dart';
import 'package:provider/provider.dart';

class TrackedSubcategories extends StatelessWidget {
  const TrackedSubcategories({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: screenHeight * 0.35,
      child: Card(
        child: Column(
          children: [
            // Time accounted and current date
            timeAccountedAndCurrentDate(),

            Container(
              height: screenHeight*0.2,
              child: subcategoryAndCurrentDayTotals())
          ],
        ),
      ),
    );
  }
}
