import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_month_provider_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pcd.dart';
import 'package:motion/motion_routes/mr_home/ru_home.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SubcategoryWeeklySummary extends StatefulWidget {
  const SubcategoryWeeklySummary({super.key});

  @override
  State<SubcategoryWeeklySummary> createState() =>
      _SubcategoryWeeklySummaryState();
}

class _SubcategoryWeeklySummaryState extends State<SubcategoryWeeklySummary> {
  final _pageController = PageController();
  double initialPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        initialPage = _pageController.page!;
      });
    });
  }

  // page view child builder
  Widget _weekBuilder(
      {required String weekTitle, required Widget weekContent}) {
    return Column(
      children: [
        // week title
        Consumer<CurrentMonthProvider>(builder: (context, month, child) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0, right: 20.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Text("${month.currentMonthName}: $weekTitle"),
            ),
          );
        }),

        // week content
        weekContent
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 15, top: 5),
      child: Column(children: [
        // weekly summary
        Consumer2<CurrentYearProvider, CurrentMonthProvider>(
            builder: (context, year, month, child) {

          String yearFormat = "${year.currentYear}";

          String monthFormat = month.currentMonthNumber < 10
              ? "0${month.currentMonthNumber}"
              : "${year.currentYear}";

          return Card(
              child: SizedBox(
            height: screenHeight * 0.40,
            child: PageView(
              controller: _pageController,
              onPageChanged: (value) {
                setState(() {
                  initialPage = value.toDouble();
                });
              },
              children: [
                // week 1
                _weekBuilder(
                    weekTitle: AppString.weekOne,
                    weekContent: SizedBox(
                      height: screenHeight * 0.35, // Set the desired height
                      child: weeklySummaryView(
                        startingDate:
                            "$yearFormat-$monthFormat-01",
                        endingDate: "$yearFormat-$monthFormat-07",
                      ),
                    )),

                // week 2
                _weekBuilder(
                    weekTitle: AppString.weekTwo,
                    weekContent: SizedBox(
                      height: screenHeight * 0.35, // Set the desired height
                      child: weeklySummaryView(
                        startingDate: "$yearFormat-$monthFormat-08",
                        endingDate: "$yearFormat-$monthFormat-14",
                      ),
                    )),

                // Week 3
                const Text("Week 3"),

                // Week 4
                const Text("Week 4"),
              ],
            ),
          ));
        }),

        // smooth page indicator
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 4,
            effect: WormEffect(
                dotColor: dialogGreyColor,
                activeDotColor: blueMainColor,
                dotHeight: 9.0, // Height of inactive dots
                dotWidth: 9.0),
          ),
        )
      ]),
    );
  }
}
