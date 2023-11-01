import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../home_reusable/front_home.dart';

// accounted and unaccounted total for the entire main_category table
// second section of the home page
class TotalAccountedAndUnaccounted extends StatelessWidget {
  const TotalAccountedAndUnaccounted({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
      builder: (context, user, main, child) {
        final currentUser = user.userUid;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Accounted total
            entireTimeAccountedAndUnaccounted(
                future: main.retrieveEntireTotalMainCategoryTable(
                    currentUser!, false),
                resultName: AppString.accountedTitle,
                dayStyle: AppTextStyle.resultTitleStyleHome(false),
                hoursStyle: AppTextStyle.accountRegularAndUnaccountTextStyle()),

            // Unaccounted total
            entireTimeAccountedAndUnaccounted(
                future: main.retrieveEntireTotalMainCategoryTable(
                    currentUser, true),
                resultName: AppString.unAccountedTitle,
                dayStyle: AppTextStyle.resultTitleStyleHome(true),
                hoursStyle: AppTextStyle.accountRegularAndUnaccountTextStyle())
          ],
        );
      },
    );
  }
}
