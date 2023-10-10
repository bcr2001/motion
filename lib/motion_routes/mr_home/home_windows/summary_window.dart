import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';


// Where the summary for the month is displayed
// button toggles (Subcategory and Category)
// total time accounted for the current month 
class SummaryWindow extends StatelessWidget {
  final bool isSubcatgory;

  const SummaryWindow({super.key, required this.isSubcatgory});

  @override
  Widget build(BuildContext context) {
    return CardBuilder(
      itemsToBeDisplayed: isSubcatgory
          ? const SubcategoryMonthTotalsAndAverages(isSubcategory: true)
          : const SubcategoryMonthTotalsAndAverages(isSubcategory: false),
      timeAccountedAndOthers: null,
      sizedBoxHeight: 0.37,
    );
  }
}
