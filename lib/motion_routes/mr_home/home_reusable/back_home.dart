import 'package:flutter/material.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// title builder
Widget sectionTitle({required String titleName}) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 10, bottom: 15),
    child: Text(
      titleName,
      style: AppTextStyle.sectionTitleTextStyle(),
    ),
  );
}

// subtitle builder
Widget subSectionTitle2({required String titleName}) {
  return Padding(
    padding: const EdgeInsets.only(left: 25, top: 10, bottom: 10),
    child: Text(
      titleName,
      style: AppTextStyle.subSectionTitleTextStyle(),
    ),
  );
}

// special title
Widget specialSectionTitle(
    {required String mainTitleName, required String elevatedTitleName}) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
    child: Row(
      children: [
        // main title
        Text(
          mainTitleName,
          style: AppTextStyle.sectionTitleTextStyle(),
        ),

        // elevated title name
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 5.0),
          child: Text(
            elevatedTitleName,
            style: AppTextStyle.specialSectionTitleTextStyle(),
          ),
        )
      ],
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

                      return widget.columnName == "subcategoryName"
                          ? ListTile(
                              title: Text(
                                item[widget.columnName],
                                style: AppTextStyle.leadingTextLTStyle(),
                              ),
                              trailing: Text(
                                convertedTotal,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.leadingStatsTextLTStyle(),),
                              subtitle: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColor.tileBackgroundColor,
                                ),
                                child: Center(
                                  child: Text(
                                    convertedAverage,
                                    style: AppTextStyle.tileElementTextStyle(),
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                                leading: Text(
                                  item[widget.columnName],
                                  style: AppTextStyle.leadingTextLTStyle(),
                                ),
                                title: Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppColor.tileBackgroundColor,
                                  ),
                                  child: Center(
                                    child: Text(convertedTotal,
                                        textAlign: TextAlign.center,
                                        style:
                                            AppTextStyle.tileElementTextStyle()),
                                  ),
                                ),
                                trailing: Text(
                                  convertedAverage,
                                  style: AppTextStyle.leadingStatsTextLTStyle(),
                                ),
                              ),
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
      required this.itemsToBeDisplayed,
      this.sizedBoxHeight = 0.25});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
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
