import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/first_and_last_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';

import '../../motion_reusable/db_re/sub_ui.dart';
import '../../motion_reusable/general_reuseable.dart';

class AccountedUnaccountedReportPieChart extends StatelessWidget {
  const AccountedUnaccountedReportPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserUidProvider, FirstAndLastDay,
            MainCategoryTrackerProvider>(
        builder: (context, user, day, main, child) {
      return FutureBuilder(
          future: main.retrieveMonthAccountUnaccountTable(
              user.userUid!, day.firstDay, day.lastDay),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerWidget.rectangular(width: 100, height: 25);
            } else if (snapshot.hasError) {
              return const Text("Error 355 :(");
            } else {
              List<Map<String, dynamic>> totalAccountUnaccountedMap =
                  snapshot.data ?? [];

              double accounted =
                  (totalAccountUnaccountedMap[0]["Accounted"] / 60);
              double unAccounted =
                  (totalAccountUnaccountedMap[0]["Unaccounted"] / 60);

              double total = accounted + unAccounted;

              

              double accountedDouble =
                  double.parse(((accounted/total)*100).toStringAsFixed(1));
              double unAccountedDouble =
                  double.parse(((unAccounted/total)*100).toStringAsFixed(1));
              

              logger.i(unAccounted);

              return PieChartBuilder(sections: [
                PieChartSectionData(
                    title: "$accountedDouble%",
                    value: accountedDouble, color:AppColor.accountedColor),
                PieChartSectionData(
                  title: "$unAccountedDouble%",
                    value: unAccountedDouble, color: AppColor.unAccountedColor),
              ]);
            }
          });
    });
  }
}

class PieChartBuilder extends StatelessWidget {
  final List<PieChartSectionData>? sections;

  const PieChartBuilder({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,),
        
        ),
    );
  }
}
