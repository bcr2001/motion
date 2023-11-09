import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String accountedTotal;
  final String unaccountedTotal;
  final String educationTotal;
  final String entertainmentTotal;
  final String skillTotal;
  final String personalGrowthTotal;
  final String sleepTotal;

  const AnnualGallaryBuilder(
      {super.key,
      required this.accountedTotal,
      required this.unaccountedTotal,
      required this.educationTotal,
      required this.entertainmentTotal,
      required this.skillTotal,
      required this.personalGrowthTotal,
      required this.sleepTotal});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.50,
      height: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // total time accounted for the year
              Text(
                "${AppString.accountedTitle}: $accountedTotal",
                style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),
              ),

              // total time unaccounted for the entire year
              Text("${AppString.unAccountedTitle}: $unaccountedTotal",
                  style: AppTextStyle.accountedAndUnaccountedGallaryStyle()),

              // divider
              const Divider(
                thickness: 1.5,
              ),

              // a listview of the main categories
              // with there respective totals

              // the year of the gallary summary
              Align(
                alignment: Alignment.bottomLeft,
                child: Text("2021", style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),))
            ],
          ),
        ),
      ),
    );
  }
}
