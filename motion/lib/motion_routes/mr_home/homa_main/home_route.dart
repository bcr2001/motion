import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/home_windows/tracking_window.dart';
import 'package:motion/motion_routes/mr_home/home_windows/summary_window.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import '../home_reusable/back_home.dart';
import '../home_reusable/front_home.dart';
import '../home_windows/efficieny_window.dart';
import '../home_windows/total_acc_unacc.dart';



// home route
class MotionHomeRoute extends StatelessWidget {
  const MotionHomeRoute({super.key});

  // home sliverapp bar
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      elevation: 0,
      backgroundColor: currentSelectedThemeMode(context) ==
              ThemeModeSettingsN1.darkMode
          ? Colors.black
          : currentSelectedThemeMode(context) == ThemeModeSettingsN1.lightMode
              ? Colors.white
              : null,
      actions: const [MotionActionButtons()],
      pinned: true,
      centerTitle: false,
      title: // current month
          Row(
            children: [
              // Current Month
              Consumer<CurrentMonthProvider>(
                      builder: (context, month, child) {
              return Text(
                month.currentMonthName,
                style: AppTextStyle.subSectionTextStyle(fontsize: 17),
              );
                      },
                    ),

              // Users streak
              Consumer2<UserUidProvider, MainCategoryTrackerProvider>(
                  builder: (context, user, streak, child) {
                    final String? currentUser = user.userUid;

                    return FutureBuilder<int>(
                      future: streak.retrievedUserStreak(currentUser: currentUser ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const ShimmerWidget.rectangular(
                          width: 5, height: 5); // Show a loading indicator while fetching data
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}'); // Handle error state
                        } else if (!snapshot.hasData) {
                          return const Text('0'); // Handle null data
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              // Streak fire image
                              AppImages.streakFire,
                          
                              // Streak retrieved from the database
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Text(
                                  '${snapshot.data}', // Display the streak count
                                  style: AppTextStyle.subSectionTextStyle(fontsize: 17),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                )
            ],
          ),
    );
  }

  // quote of the day
  Widget quoteOfTheDay() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 20),
        child: Consumer<ZenQuoteProvider>(
          builder: (context, zenQuoteValue, child) {
            return Text(
              zenQuoteValue.todaysQuote,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(fontsize: 13, fontweight: FontWeight.normal),
            );
          },
        ));
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              // SECTION ONE: Life Completed 
              // Displays a life progress bar based on a user's birthdate.
              const LifeCompleted(),


              // SECTION TWO: QUOTE OF THE DAY
              // Fetches a random quote from the zenQuotes API.
              quoteOfTheDay(),

              // SECTION THREE: EFFICENCY SCORE AND NUMBER OF DAYS
              // Displays the user's total efficiency score and the 
              // total days recorded in the main_category table.
              const EfficiencyAndNumberOfDays(
                  efficiencyScore: EfficienyScoreWindow(
                    getEntireScore: false,
                  ),
                  numberOfDays: NumberOfDaysMainCategory(
                    getAllDays: false,
                  )),

              // SECTION THREE: ACCOUNTED AND UNACCOUNTED TOTALS
              //  total accounted time and
              //  total unaccounted time
              const TotalAccountedAndUnaccounted(
                getEntireTotal: false,
              ),

              // SECTION FOUR: TRACKING WINDOW
              sectionTitle(titleName: AppString.trackingWindowTitle),
              const TrackedSubcategories(),

              // SECTION FIVE: SUMMARY WINDOW
              sectionTitle(titleName: AppString.summaryTitle),
              const InfoToTheUser(
                  sectionInformation: AppString.infoAboutSummaryWindow2),
              const SummaryWindow()
            ])),
          )
        ],
      ),
    );
  }
}
