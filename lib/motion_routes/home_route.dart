import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_provider.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_core/motion_providers/web_api_pvd/zen_quotes_provider.dart';
import 'package:motion/motion_reusable/sub_reuseable.dart';
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
          Text(AppString.homeSubcategoryTitle, style: Theme.of(context).textTheme.bodyMedium,),

          // card that holds subcategories that are active
          SizedBox(
              height: screenHeight * 0.35,
              child: Card(child: Consumer4<
                  AssignerMainProvider,
                  SubcategoryTrackerDatabaseProvider,
                  CurrentDataProvider,
                  UserUidProvider>(
                builder: (context, active, sub, date, user, child) {
                  var activeItems = active.assignerItems;

                  // generates list tiles of categories where
                  // isActive = 1
                  // else is returns an empty widget
                  return ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeItems.length,
                      itemBuilder: (BuildContext context, index) {
                        return activeItems[index].isActive == 1
                            ? FutureBuilder<double>(
                                future: sub.retrieveTotalTimeSpent(
                                    date.currentData,
                                    user.userUid!,
                                    activeItems[index].subcategoryName),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    // Return a loading indicator while waiting for the data
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    // Handle any errors here
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    // Data is available, use it to build the ListTile
                                    final totalTimeSpentSub =
                                        snapshot.data ?? 0.0;
                                    
                                    // convert total
                                    final convertedTotalTimeSpent =
                                        convertMinutesToTime(totalTimeSpentSub);


                                    return ListTile(
                                      title: Text(
                                          activeItems[index].subcategoryName),
                                      trailing:
                                          Text(convertedTotalTimeSpent, style: Theme.of(context).textTheme.bodySmall,),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ManualTimeRecordingRoute(
                                              subcategoryName:
                                                  activeItems[index]
                                                      .subcategoryName,
                                              mainCategoryName:
                                                  activeItems[index]
                                                      .mainCategoryName,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              )
                            : const SizedBox.shrink();
                      });
                },
              )))
        ],
      ),
    );
  }
}
