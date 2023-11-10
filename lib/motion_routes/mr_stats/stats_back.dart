import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String accountedTotal;
  final String unaccountedTotal;
  final String gallaryYear;
  final VoidCallback onTap;

  const AnnualGallaryBuilder(
      {super.key,
      required this.accountedTotal,
      required this.unaccountedTotal,
      required this.gallaryYear,
      required this.onTap});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(
                gallaryYear,
                style:const TextStyle(color: AppColor.blueMainColor,
                fontSize: 14,
                fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );
  }
}
