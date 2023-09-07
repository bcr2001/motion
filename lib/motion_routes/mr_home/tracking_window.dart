import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/ru_home.dart';

class TrackedSubcategories extends StatelessWidget {
  const TrackedSubcategories({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: screenHeight * 0.35,
      child: Card(
        child: Column(
          children: [
            // Time accounted and current date
            timeAccountedAndCurrentDate(),

            SizedBox(
              height: screenHeight*0.2,
              child: subcategoryAndCurrentDayTotals())
          ],
        ),
      ),
    );
  }
}
