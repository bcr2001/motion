import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_routes/mr_stats/stats_front.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';

import '../../motion_themes/mth_styling/app_color.dart';

// Page that contains the subcategory totals
class SubTotalsPage extends StatelessWidget {
  const SubTotalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.subcategoryTotalsTitle),
        centerTitle: true,
      ),
      body: const SubTotalsList(),
    );
  }
}

class SubTotalsList extends StatelessWidget {
  const SubTotalsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubcategoryTrackerDatabaseProvider, UserUidProvider>(
        builder: (context, sub, user, child) {
      // current user uid
      final String userUid = user.userUid!;

      return FutureBuilder(
          future: sub.retrieveAllSubcategoryTotals(currentUser: userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // returned subcategory totals
              final allSubcategoryTotals = snapshot.data;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: allSubcategoryTotals!.length,
                    itemBuilder: (context, index) {
                      final subTotalItem = allSubcategoryTotals[index];

                      final convertedSubTotal =
                          convertMinutesToTime(subTotalItem["total"]);

                      final convertedSubAverage =
                          convertMinutesToHoursOnly(subTotalItem["average"]);

                      final convertedTotalDays =
                          (subTotalItem["total"] / 1440).toStringAsFixed(2);

                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: CategoryBuilder(
                            dividerWidth: null,
                            mainCategoryName: subTotalItem["subcategoryName"],
                            galleryInitials: (index + 1).toString(),
                            totalHours: convertedSubTotal,
                            totalDays: "$convertedTotalDays days",
                            average: convertedSubAverage),
                      );
                    }),
              );
            }
          });
    });
  }
}



// return ListView.builder(
              //     padding: EdgeInsets.zero,
              //     itemCount: allSubcategoryTotals!.length,
              //     itemBuilder: (BuildContext context, index) {
              //       final subTotalItem = allSubcategoryTotals[index];

              //       final convertedSubTotal =
              //           convertMinutesToTime(subTotalItem["total"]);

              //       final convertedSubAverage =
              //           convertMinutesToHoursOnly(subTotalItem["average"]);

              //       return ListTile(
              //         leading: Text((index + 1).toString()),
              //         title: Text(
              //           subTotalItem["subcategoryName"],
              //           style: AppTextStyle.leadingTextLTStyle(),
              //         ),
              //         trailing: Text(
              //           convertedSubTotal,
              //           textAlign: TextAlign.center,
              //           style: AppTextStyle.leadingStatsTextLTStyle(),
              //         ),
              //         subtitle: Container(
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(20),
              //             color: AppColor.tileBackgroundColor,
              //           ),
              //           child: Center(
              //             child: Text(
              //               convertedSubAverage,
              //               style: AppTextStyle.tileElementTextStyle(),
              //             ),
              //           ),
              //         ),
              //       );
              //     });