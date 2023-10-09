import 'package:flutter/material.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';

// title builder
Widget sectionTitle({required String titleName}) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 10),
    child: Text(
      titleName,
      style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600),
    ),
  );
}

// builds the ListView.builder() of either
// main or subcategory with a scollbar
class ScrollingListBuilder extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String columnName;

  const ScrollingListBuilder(
      {super.key, required this.future, required this.columnName});

  @override
  State<ScrollingListBuilder> createState() => _ScrollingListBuilderState();
}

class _ScrollingListBuilderState extends State<ScrollingListBuilder> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.future,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildShimmerProgress(); // While data is loading
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // If there's an error
          } else {
            // Data is available, you can access it using snapshot.data
            final monthTotalsAndAverage = snapshot.data;

            return Scrollbar(
                controller: _scrollController,
                radius: const Radius.circular(10.0),
                trackVisibility: true,
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    controller: _scrollController,
                    itemCount: monthTotalsAndAverage!.length,
                    itemBuilder: (BuildContext context, index) {
                      final item = monthTotalsAndAverage[index];

                      final convertedTotal =
                          convertMinutesToTime(item["total"]);

                      final convertedAverage =
                          convertMinutesToHoursOnly(item["average"]);

                      return ListTile(
                        title: Text(item[widget.columnName]),
                        trailing: Text(convertedTotal),
                        subtitle: Text(convertedAverage),
                      );
                    }));
          }
        });
  }
}

// builds the cards that are displayed in the home
//  page for both tracking and summary windows
class CardBuilder extends StatelessWidget {
  final Widget? timeAccountedAndOthers;
  final Widget itemsToBeDisplayed;
  final double sizedBoxHeight;

  const CardBuilder(
      {super.key,
      required this.timeAccountedAndOthers,
      required this.itemsToBeDisplayed, this.sizedBoxHeight = 0.25});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 25.0),
      height: screenHeight * 0.40,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // time accounted
            timeAccountedAndOthers ?? const SizedBox.shrink(),

            // database results
            SizedBox(
              height: screenHeight * sizedBoxHeight,
              child: itemsToBeDisplayed,
            )
          ],
        ),
      ),
    );
  }
}
