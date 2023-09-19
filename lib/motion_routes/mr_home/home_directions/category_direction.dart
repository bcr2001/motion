import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';

class MainAndSubView extends StatefulWidget {
  final Widget subcategoryView;
  final Widget mainCategoryView;

  const MainAndSubView({super.key, required this.subcategoryView,required this.mainCategoryView});

  @override
  State<MainAndSubView> createState() => _MainAndSubViewState();
}

class _MainAndSubViewState extends State<MainAndSubView> {
  // state of the view
  // default view is the subcategory view
  bool isSubcategory = true;

  // elevated button constructor
  Widget _viewButton(
      {required String buttonName, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(right: 5, top: 5, bottom: 5),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(elevation: 0),
          onPressed: onPressed,
          child: Text(buttonName)),
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
                buttonName: "Subcategory",
                onPressed: () {
                  setState(() {
                    isSubcategory = true;
                  });
                }),

            // main category view button
            _viewButton(
                buttonName: "Main Category",
                onPressed: () {
                  setState(() {
                    isSubcategory = false;
                  });
                }),
          ],
        ),


        
        // views that is being toggled between
        isSubcategory ? widget.subcategoryView : widget.mainCategoryView
      ],
    );
  }
}
