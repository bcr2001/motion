import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_routes/mr_home/category_direction.dart';
import 'package:motion/motion_routes/mr_home/tw_ui.dart';
import 'package:motion/motion_screens/manual_tracking.dart';
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
      backgroundColor:
          currentSelectedThemeMode(context) == ThemeModeSettings.darkMode
              ? Colors.black
              : Colors.white,
      actions: const [MotionActionButtons()],
      floating: true,
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

              // Tracking Window view
              MainAndSubView(
                  viewTitle: "Tracking Window",
                  subcategoryView: TrackedSubcategories1(),
                  mainCategoryView:
                      const Text("Main Category under construction"))
              
            ]))
          ],
        ),
      ),
    );
  }
}
