import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:shimmer/shimmer.dart';

// this class creates an add and a cancel text button
// the add text button interracts with the database
// the cancel text button navigates off an alert dialog
class CancelAddTextButtons extends StatelessWidget {
  final String firstButtonName;
  final String secondButtonName;
  final VoidCallback onPressedFirst;
  final VoidCallback onPressedSecond;

  const CancelAddTextButtons(
      {super.key,
      required this.onPressedFirst,
      required this.onPressedSecond,
      required this.firstButtonName,
      required this.secondButtonName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel Button
        TextButton(
          onPressed: onPressedFirst,
          child: Text(
            firstButtonName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),

        // Add button
        TextButton(
          onPressed: onPressedSecond,
          child: Text(
            secondButtonName,
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
  final Widget cardListView;

  const CardConstructor(
      {super.key, required this.cardTitle, required this.cardListView});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // card title
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              cardTitle,
              style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12, color: Colors.blueGrey),
            ),
          ),

          // title and content divider
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(
              thickness: 1.2,
              color: Theme.of(context).dividerTheme.color,
            ),
          ),

          // listView widget
          cardListView
        ],
      ),
    );
  }
}

// List view builder
class TrackListViewBuiler extends StatelessWidget {
  final int? itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;

  const TrackListViewBuiler(
      {super.key, this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: itemBuilder);
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

// SHIMMER WIDGETs
// list tile shimmer widget
Widget buildShimmerProgress() => const ListTile(
      title: ShimmerWidget.rectangular(
        height: 20,
        width: 18,
      ),
      trailing: ShimmerWidget.rectangular(width: 25, height: 16),
    );

Widget buildShimmerProgressAll() => const ListTile(
      title: ShimmerWidget.rectangular(width: 5, height: 20),
      subtitle: ShimmerWidget.rectangular(width: 5, height: 10),
      trailing: ShimmerWidget.rectangular(width: 20, height: 10),
    );

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerWidget.rectangular(
      {super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[300]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey,
      ),
    );
  }
}
