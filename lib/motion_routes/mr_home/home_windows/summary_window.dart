import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';

class SummaryWindow extends StatelessWidget {
  final bool isSubcatgory;

  const SummaryWindow({super.key, required this.isSubcatgory});

  @override
  Widget build(BuildContext context) {
    return CardBuilder(timeAccountedAndOthers:totalMonthTimeSpent() , itemsToBeDisplayed: isSubcatgory ?const SubcategoryMonthTotalsAndAverages(isSubcategory: true): const SubcategoryMonthTotalsAndAverages(isSubcategory: false) );
  }
}
