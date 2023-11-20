import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String gallaryYear;
  final VoidCallback onTap;

  const AnnualGallaryBuilder(
      {super.key, required this.gallaryYear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // the year of the gallary summary
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                gallaryYear,
                style: const TextStyle(
                  color: AppColor.blueMainColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // DIVIDER
            // divider
            const SizedBox(
              width: 100,
              child: Divider(
                thickness: 1.5,
                color: AppColor.blueMainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// yearly accounted and unaccounted totals
class YearTotalsAccountedUnaccountedBuilder extends StatelessWidget {
  final String accountedDays;
  final String accountedHours;
  final String unaccountedDays;
  final String unaccountedHours;

  const YearTotalsAccountedUnaccountedBuilder(
      {super.key,
      required this.accountedDays,
      required this.accountedHours,
      required this.unaccountedDays,
      required this.unaccountedHours});

  // function that builds out the accounted and unaccounted
  // sections
  Widget _onePieceData(
      {required String sectionName,
      required String sectionDays,
      required String sectionHours,
      required TextStyle sectionDataValueStyle,
      required Color lineChartIconColor}) {
    return SizedBox(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // section title
          Text(
            sectionName,
            style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),
          ),

          // days

          Row(
            children: [
              Icon(
                Icons.line_axis_rounded,
                size: 30,
                color: lineChartIconColor,
              ),
              Column(
                children: [
                  Text(
                    "$sectionDays days",
                    style: sectionDataValueStyle,
                  ),

                  // hours
                  Text(
                    "$sectionHours hours",
                    style: sectionDataValueStyle,
                  ),
                ],
              ),
            ],
          ),

          // section divider
          const SizedBox(
            width: 100,
            child: Divider(
              thickness: 2,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // accounted with data
          _onePieceData(
              sectionName: AppString.totalAccountedTitle,
              sectionDays: accountedDays,
              sectionHours: accountedHours,
              sectionDataValueStyle: AppTextStyle.pieChartTextStyling(),
              lineChartIconColor: Colors.green),

          // unaccounted with data
          _onePieceData(
              sectionName: AppString.totalUnaccountedTitle,
              sectionDays: unaccountedDays,
              sectionHours: unaccountedHours,
              sectionDataValueStyle: AppTextStyle.pieChartTextStyling(),
              lineChartIconColor: Colors.red),
        ],
      ),
    );
  }
}


  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: 10,
          color: const Color(0xFFA9A9A9),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: const Color(0xFF909090),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: const Color(0xFFCFCFCF),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: const Color(0xFF909090),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: const Color(0xFFA9A9A9),
        ),
      ],
    );
  }