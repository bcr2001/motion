import 'package:flutter/material.dart';

class MainAndSubView extends StatefulWidget {
  final String viewTitle;
  final Widget subcategoryView;
  final Widget mainCategoryView;

  const MainAndSubView({super.key, required this.viewTitle, required this.subcategoryView,required this.mainCategoryView});

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
        // view title
        Text(widget.viewTitle,
            style:
                const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w600)),

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
