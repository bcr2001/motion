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

// card widget plus a ListView.Builder() to display SQLite database table content
class CardConstructor extends StatelessWidget {
  final String cardTitle;
  final ListView cardListView;

  const CardConstructor(
      {super.key, required this.cardTitle, required this.cardListView});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // card title
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
              child: Text(
                cardTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),

            // title and content divider
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Divider(
                thickness: 1.5,
                color: Colors.black,
              ),
            ),

            // listView widget
            cardListView
          ],
        ),
      ),
    );
  }
}

// floating action button
FloatingActionButton floatingActionButton(context,
    {required VoidCallback onPressed,
    required String label,
    required IconData icon}) {
  return FloatingActionButton.extended(
    onPressed: onPressed,
    label: Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    icon: Icon(
      icon,
      color: Theme.of(context).iconTheme.color,
    ),
  );
}

// time measurement adder
double timeAdder({required String h, required String m, required String s}) {
  double hours = double.parse(h) * 60;
  double minutes = double.parse(m);
  double seconds = double.parse(s) / 60;

  double addedTimeComponents = hours + minutes + seconds;

  return addedTimeComponents;
}
