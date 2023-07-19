import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_providers/zen_quotes_provider.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:motion/motion_routes/route_action.dart';
import 'package:intl/intl.dart';
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
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          currentMonth(),
          style: TextStyle(
            fontSize: 18,
            color:
                currentSelectedThemeMode(context) == ThemeModeSettings.darkMode
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(top: 18),
        background: _buildProfileBackground(),
      ),
    );
  }

  // sliverapp bar background
  Widget _buildProfileBackground() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          // user profile picture
          CircleAvatar(
            radius: 60,
            backgroundImage:
                AssetImage("assets/images/motion_icons/motion_pfp.jpg"),
          ),
          // UserName
          Text(
            "智也tomoya_hx",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          )
        ],
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
          SliverList(delegate: SliverChildListDelegate([quoteOfTheDay()]))
        ],
      ),
    );
  }
}
