import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

import '../../../motion_themes/mth_app/app_strings.dart';
import '../home_reusable/front_home.dart';

class MainAndSubView extends StatefulWidget {
  final Widget subcategoryView;
  final Widget mainCategoryView;

  const MainAndSubView(
      {super.key,
      required this.subcategoryView,
      required this.mainCategoryView});

  @override
  State<MainAndSubView> createState() => _MainAndSubViewState();
}

class _MainAndSubViewState extends State<MainAndSubView> {
  // state of the view
  // default view is the subcategory view
  bool isSubcategory = true;

  Color viewButtonColor = AppColor.blueMainColor;


  // Elevated button constructor
  Widget _viewButton({
    required String buttonName,
    required VoidCallback onPressed,
    required bool isActive, // Add isActive parameter
  }) {
    // Define active and inactive button colors
    const activeColor = AppColor.blueMainColor; // Change to your active color
    const inactiveColor = AppColor.lightModeContentWidget; // Change to your inactive color

    return Padding(
      padding: const EdgeInsets.only(right: 5, top: 5, bottom: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? activeColor : inactiveColor,
        ),
        onPressed: onPressed,
        child: Text(buttonName, style: TextStyle(
          color: 
        currentSelectedThemeMode(context) == ThemeModeSettings.darkMode
            ? Colors.black
            : Colors.black
        ),),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // subcategory view button
            _viewButton(
                buttonName: AppString.subcategoryViewButtonName,
                onPressed: () {
                  setState(() {
                    isSubcategory = true;
                  });
                },
                isActive: isSubcategory),

            // main category view button
            _viewButton(
                buttonName: AppString.mainCategoryViewButtonName,
                onPressed: () {
                  setState(() {
                    isSubcategory = false;
                  },);
                },isActive: !isSubcategory
                ),
          ],
        ),

        // total time accounted
        totalMonthTimeSpent(),

        // views that is being toggled between
        isSubcategory ? widget.subcategoryView : widget.mainCategoryView
      ],
    );
  }
}
