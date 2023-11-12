import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// annual gallery builder
class AnnualGallaryBuilder extends StatelessWidget {
  final String accountedTotalHours;
  final String accountedTotalDays;
  final String unaccountedTotalHours;
  final String unaccountedTotalDays;
  final String gallaryYear;
  final VoidCallback onTap;

  const AnnualGallaryBuilder(
      {super.key,
      required this.accountedTotalHours,
      required this.unaccountedTotalHours,
      required this.gallaryYear,
      required this.onTap,
      required this.accountedTotalDays,
      required this.unaccountedTotalDays});

  Text _dataValueText(String dataValue, bool isDays) {
    return isDays
        ? Text(
            "$dataValue days",
            style: AppTextStyle.overviewDataValueTextStyle(),
          )
        : Text(
            "$dataValue hrs",
            style: AppTextStyle.overviewDataValueTextStyle(),
          );
  }

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
              // ACCOUNTED
              Text(
                AppString.accountedTitle,
                style: AppTextStyle.accountedAndUnaccountedGallaryStyle(),
              ),

              // total time accounted for the year in days
              _dataValueText(accountedTotalDays, true),
              // total time accounted for the year in hours
              _dataValueText(accountedTotalHours, false),

              // DIVIDER
              // divider
              const Divider(
                thickness: 1.5,
              ),

              // UNACCOUNTED
              Text(AppString.unAccountedTitle,
                  style: AppTextStyle.accountedAndUnaccountedGallaryStyle()),

              // total time unaccounted for the entire year
              _dataValueText(unaccountedTotalDays, true),
              _dataValueText(unaccountedTotalHours, false),

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
            ],
          ),
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
                color: lineChartIconColor,),
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
