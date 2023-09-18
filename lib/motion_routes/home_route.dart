import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'package:motion/motion_routes/mr_home/category_direction.dart';
import 'package:motion/motion_routes/mr_home/ru_home.dart';
import 'package:motion/motion_routes/mr_home/summary.dart';
import 'package:motion/motion_routes/mr_home/tracking_window.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';

// home route
class MotionHomeRoute extends StatelessWidget {
  const MotionHomeRoute({super.key});

  // home sliverapp bar
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      elevation: 0,
      backgroundColor:
          currentSelectedThemeMode(context) == ThemeModeSettings.darkMode
              ? Colors.black
              : Colors.white,
      actions: const [MotionActionButtons()],
      pinned: true,
      floating: true,
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Consumer<ZenQuoteProvider>(
          builder: (context, zenQuoteValue, child) {
            return Text(
              zenQuoteValue.todaysQuote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            );
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverList(
                delegate: SliverChildListDelegate([
              // quote from the zenQuotes API
              quoteOfTheDay(),
              
              // Tracking Window
              cardTitle(titleName: AppString.trackingWindowTitle),
              const TrackedSubcategories(),

              //Weekly Summary
              cardTitle(titleName: AppString.summaryTitle),
              const MainAndSubView(
                  subcategoryView: SummaryWindow(),
                  mainCategoryView:
                      Text("Main Category under construction"))
              
            ]))
          ],
        ),
      ),
    );
  }
}
