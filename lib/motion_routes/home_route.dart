import 'package:flutter/material.dart';
import 'package:motion/motion_providers/date_data_pvd/current_month_provider.dart';
import 'package:motion/motion_providers/firestore_pvd/firestore_provider.dart';
import 'package:motion/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_providers/web_api_pvd/zen_quotes_provider.dart';
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
        expandedHeight: 200,
        flexibleSpace: Consumer<CurrentMonthProvider>(
          builder: (context, month, child) {
            return FlexibleSpaceBar(
              title: Text(
                month.currentMonthName,
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(top: 18),
              background: _buildProfileBackground(),
            );
          },
        ));
  }

  // sliverapp bar background
  Widget _buildProfileBackground() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Consumer<FirestoreProvider>(
          builder: (context, storeInfo, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // user profile picture
                CircleAvatar(
                    radius: 60,
                    backgroundImage: storeInfo.userPfpUrl != null
                        ? NetworkImage(storeInfo.userPfpUrl!)
                        : const AssetImage(
                                "assets/images/motion_icons/default_pfp.png")
                            as ImageProvider),

                // UserName
                Text(
                  storeInfo.userName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                )
              ],
            );
          },
        ));
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
          SliverList(delegate: SliverChildListDelegate([quoteOfTheDay()]))
        ],
      ),
    );
  }
}
