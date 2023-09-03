import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';

// this class creates an add and a cancel text button
// the add text button interracts with the database
// the cancel text button navigates off an alert dialog
class CancelAddTextButtons extends StatelessWidget {
  final VoidCallback onPressedCancel;
  final VoidCallback onPressedAdd;

  const CancelAddTextButtons(
      {super.key, required this.onPressedCancel, required this.onPressedAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel Button
        TextButton(
          onPressed: onPressedCancel,
          child: Text(
            AppString.trackCancelTextButton,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        
        // Add button
        TextButton(
          onPressed: onPressedAdd,
          child: Text(
            AppString.trackAddTextButton,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}



// time measurement adder
// double timeAdder({required String h, required String m, required String s}){

// }