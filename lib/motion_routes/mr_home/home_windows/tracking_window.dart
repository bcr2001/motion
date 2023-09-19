import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/front_home.dart';

class TrackedSubcategories extends StatelessWidget {
  const TrackedSubcategories({super.key});

  @override
  Widget build(BuildContext context) {

    return CardBuilder(
        timeAccountedAndOthers: timeAccountedAndCurrentDate(),
        itemsToBeDisplayed: const SubcategoryAndCurrentDayTotals());
  }
}
