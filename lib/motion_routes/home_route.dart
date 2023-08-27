import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_provider.dart';
import 'package:provider/provider.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:motion/motion_reusable/reuseable.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverList(
              delegate: SliverChildListDelegate([
            // quote from the zenQuotes API
            quoteOfTheDay(),
          ]))
        ],
      ),
    );
  }
}
