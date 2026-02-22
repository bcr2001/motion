import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:provider/provider.dart';

class TrackedSubcategories extends StatelessWidget {
  const TrackedSubcategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, AssignerMainProvider>(
        builder: (context, user, assign, child) {
      final String currentUser = user.userUid!;

      // if the result from the isTableEmptyOrNotBeingTracked()
      // function is True then the an instruction screen will be shown
      // otherwise the normal tracking window will be displayed once the user addes a subcategory to be tracked
      return FutureBuilder(
          future: assign.retrieveIsTableEmptyOrNotBeingTracked(
              currentUser: currentUser),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the data is loading, a shimmer effect is shown
              return const ShimmerWidget.rectangular(
                height: 200,
                width: 200,
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final snapshotData = snapshot.data;

              final String queryResultBool = snapshotData![0]["AllAreZero"];

              if (queryResultBool == "True") {
                return AppImages.trackListEmpty;
              } else {
                return CardBuilder(
                    timeAccountedAndOthers: timeAccountedCurrentDateXP(),
                    itemsToBeDisplayed: const SubcategoryAndCurrentDayTotals());
              }
            }
          });
    });
  }
}
