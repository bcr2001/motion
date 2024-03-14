import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'package:motion/motion_routes/mr_home/home_windows/tracking_window.dart';
import 'package:motion/motion_routes/mr_home/home_windows/summary_window.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
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
      backgroundColor:
          currentSelectedThemeMode(context) == ThemeModeSettingsN1.darkMode
              ? Colors.black
              : currentSelectedThemeMode(context) == ThemeModeSettingsN1.lightMode?
              Colors.white : null,
      actions: const [MotionActionButtons()],
      pinned: true,
      centerTitle: false,
      title: // current month
          Consumer<CurrentMonthProvider>(
        builder: (context, month, child) {
          return Text(
            month.currentMonthName,
            style: Theme.of(context).textTheme.headlineSmall,
          );
        },
      ),
    );
  }

  // quote of the day
  Widget quoteOfTheDay() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 3.8),
        child: Consumer<ZenQuoteProvider>(
          builder: (context, zenQuoteValue, child) {
            return Text(
              zenQuoteValue.todaysQuote,
              textAlign: TextAlign.center,
              style: AppTextStyle.quoteTextStyle(),
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

              // SECTION ONE: QUOTE OF THE DAY
              // quote from the zenQuotes API
              quoteOfTheDay(),

              // SECTION TWO: EFFICENCY SCORE
              // This section displays the users entire efficieny score
              // total number of days in the main_category table
              const EfficiencyAndNumberOfDays(
                efficiencyScore: EfficienyScoreWindow(getEntireScore: false,),
                numberOfDays: NumberOfDaysMainCategory(getAllDays: false,)),

              // SECTION THREE: ACCOUNTED AND UNACCOUNTED TOTALS
              //  total accounted time and
              //  total unaccounted time
              const TotalAccountedAndUnaccounted(getEntireTotal: false,),


              // SECTION FOUR: TRACKING WINDOW
              sectionTitle(titleName: AppString.trackingWindowTitle),
              const TrackedSubcategories(),



              // SECTION FIVE: SUMMARY WINDOW
              sectionTitle(titleName: 
              AppString.summaryTitle),
              const InfoToTheUser(
                sectionInformation: 
                AppString.infoAboutSummaryWindow2),
              const SummaryWindow()
            ])),
          )
        ],
      ),
    );
  }
}
