import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/main_and_sub.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_provider.dart';
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
              const TrackedSubcategories()
            ]))
          ],
        ),
      ),
    );
  }
}

// subcategories being tracked
class TrackedSubcategories extends StatelessWidget {
  const TrackedSubcategories({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // subcategory title
          const Text("Subcategory"),

          // card that holds subcategories that are active
          SizedBox(
              height: screenHeight * 0.35,
              child: Card(child: Consumer<AssignerMainProvider>(
                builder: (context, active, child) {
                  var activeItems = active.assignerItems;

                  // generates list tiles of categories where
                  // isActive = 1
                  // else is returns an empty widget
                  return ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeItems.length,
                      itemBuilder: (BuildContext context, index) {
                        return activeItems[index].isActive == 1
                            ? ListTile(
                              title: Text(activeItems[index].subcategoryName),
                            )
                            :const SizedBox.shrink();
                      });
                },
              )))
        ],
      ),
    );
  }
}
