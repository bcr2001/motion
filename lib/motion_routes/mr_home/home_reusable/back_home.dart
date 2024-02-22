import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

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

// special title used to display efficiency score for
// the selected year
Widget specialSectionTitleSelectedYear({required String mainTitleName}){
  return Container(
    margin: const EdgeInsets.only(left: 10),
    child: Padding(
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // main title
          Text(
            mainTitleName,
            style: AppTextStyle.sectionTitleTextStyleEF2(),
          ),

          // efs titel
           Padding(
            padding: const EdgeInsets.only(bottom: 10.0, left: 5.0),
            child: Text(
              AppString.efficiencyScoreTitle,
              style: AppTextStyle.specialSectionTitleTextStyle(),
            ),
          ),


        ],
      ),
    ),
  );

}

// special title used to display efficiency scores for 
// the  current year and the overrall total efs
Widget specialSectionTitleEFS(
    {required String mainTitleName, required bool getEntire}) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
    child: Row(
      children: [
        // main title
        Text(
          mainTitleName,
          style: AppTextStyle.sectionTitleTextStyleEF2(),
        ),

        // elevated title name
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, left: 5.0),
              child: Text(
                AppString.efficiencyScoreTitle,
                style: AppTextStyle.specialSectionTitleTextStyle(),
              ),
            ),

            // year
            getEntire? Consumer<CurrentYearProvider>(
              builder: (BuildContext context, year, child) {
                final currentYear = year.currentYear;
                
                return Padding(
                  padding: const EdgeInsets.only(left:2.0),
                  child: Text(
                    currentYear,
                    style: AppTextStyle.specialSectionTitleTextStyle(),
                  ),
                );
              },
            ): Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Text(AppString.entireTitle, style: AppTextStyle.specialSectionTitleTextStyle(),),
            )
          ],
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
                    shrinkWrap: true,
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
                                style: AppTextStyle.leadingStatsTextLTStyle(),
                              ),
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
                                // Main Category Name
                                leading: Text(
                                  item[widget.columnName],
                                  style: AppTextStyle.leadingTextLTStyle(),
                                ),
                                // total hours spent on a particular main
                                // main category during a specific month
                                title: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppColor.tileBackgroundColor,
                                  ),
                                  child: Center(
                                    child: Text(convertedTotal,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyle
                                            .tileElementTextStyle()),
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

  const CardBuilder(
      {super.key,
      required this.timeAccountedAndOthers,
      required this.itemsToBeDisplayed});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 2, right: 2),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // time accounted
            timeAccountedAndOthers ?? const SizedBox.shrink(),

            // database results
            Container(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.38),
              child: itemsToBeDisplayed,
            )
          ],
        ),
      ),
    );
  }
}
