import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_time_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

// this returns the page where users can add data into the database tables
class ManualTimeRecordingRoute extends StatefulWidget {
  // main and subcategory names from the home page
  final String subcategoryName;
  final String mainCategoryName;

  const ManualTimeRecordingRoute(
      {super.key,
      required this.subcategoryName,
      required this.mainCategoryName});

  @override
  State<ManualTimeRecordingRoute> createState() =>
      _ManualTimeRecordingRouteState();
}

class _ManualTimeRecordingRouteState extends State<ManualTimeRecordingRoute> {
  final _timeFormKey = GlobalKey<FormState>();

  // hours: minutes: seconds text editing contollers
  TextEditingController hourController = TextEditingController();
  TextEditingController minuteController = TextEditingController();
  TextEditingController secondController = TextEditingController();

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();

    super.dispose();
  }

  // time component
  Widget _titleAndTextFieldBuilder(
      {required String title,
      required TextEditingController textEditingController}) {
    return Flexible(
      child: Column(
        children: [
          // time component titles
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          // text field for each time component
          SizedBox(
            width: 60,
            child: TextFormFieldBuilder(
              maxCharacterLen: 2,
              border: InputBorder.none,
              fieldTextEditingController: textEditingController,
              fieldHintText: "00",
              fieldKeyboardType: TextInputType.number,
              hintTextStyle: TextEditingStyling.manualHintTextStyle(),
              fieldValidator: (value) {
                // check whether the field is empty
                if (value == null || value.isEmpty) {
                  return "??";
                }
                return null;
              },
            ),
          )
        ],
      ),
    );
  }

  // seperator
  Widget _seperate() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Text(
        ":",
        style: TextEditingStyling.manualHintTextStyle(),
      ),
    );
  }

  // alert dialog that is displayed when the add icon is clicked
  void _showTimeAlertDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          var subTrackerProvider =
              context.read<SubcategoryTrackerDatabaseProvider>();

          return AlertDialogConst(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            alertDialogTitle: AppString.manualAddBlock,
            alertDialogContent: Form(
              key: _timeFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // time component text fields displayed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // hour time component
                      _titleAndTextFieldBuilder(
                          title: "Hours",
                          textEditingController: hourController),

                      _seperate(),

                      // minute time component
                      _titleAndTextFieldBuilder(
                          title: "Minutes",
                          textEditingController: minuteController),

                      _seperate(),

                      // seconds time component
                      _titleAndTextFieldBuilder(
                          title: "Seconds",
                          textEditingController: secondController)
                    ],
                  ),

                  // cancel and add button
                  Consumer4<CurrentDateProvider, UserUidProvider,
                      CurrentTimeProvider, MainCategoryTrackerProvider>(
                    builder: (context, date, uid, time, mainCat, child) {
                      return CancelAddTextButtons(
                        firstButtonName: AppString.trackCancelTextButton,
                        secondButtonName: AppString.trackAddTextButton,
                        onPressedFirst: () {
                          // exits the alart dialog and resets the text
                          // contoller content
                          navigationKey.currentState!.pop();

                          hourController.text = "";
                          minuteController.text = "";
                          secondController.text = "";
                        },
                        onPressedSecond: () async {
                          // adds the necessary data to the subcategory
                          // table if validation passes
                          if (_timeFormKey.currentState!.validate()) {
                            _timeFormKey.currentState!.save();
                            if (int.parse(hourController.text) > 25 ||
                                int.parse(minuteController.text) > 59 ||
                                int.parse(secondController.text) > 59) {
                              errorSnack(context,
                                  errorMessage:
                                      "Invalid entry: keep entries within range!!");
                              logger.i("Failed Validation");
                            } else {
                              logger.i("Passed Validation");

                              // Check if the date and currentLoggedInUser
                              // exist in the main category table
                              final mainCategoryExists1 =
                                  await mainCategoryExists(
                                      date.currentDate, uid.userUid!);

                              logger.i(mainCategoryExists1);

                              if (!mainCategoryExists1) {
                                logger.i("Main Category is being added");
                                logger.i(date.currentDate);
                                logger.i("${uid.userUid}");
                                // Insert date and currentLoggedInUser into
                                //the main category table
                                final mainCategory = MainCategory(
                                  date: date.currentDate,
                                  currentLoggedInUser: uid.userUid!,
                                );

                                await mainCat
                                    .insertIntoMainCategoryTable(mainCategory);
                                logger.i("a new row has been inserted");
                              }

                              final subcategory = Subcategories(
                                  date: date.currentDate,
                                  mainCategoryName: widget.mainCategoryName,
                                  subcategoryName: widget.subcategoryName,
                                  currentLoggedInUser: uid.userUid!,
                                  // timeAdder functions converts all the time components to minutes
                                  timeSpent: timeAdder(
                                      h: hourController.text,
                                      m: minuteController.text,
                                      s: secondController.text),
                                  timeRecorded: time.formattedTime);

                              subTrackerProvider
                                  .insertIntoSubcategoryTable(subcategory);
                              navigationKey.currentState!.pop();

                              hourController.text = "";
                              minuteController.text = "";
                              secondController.text = "";
                            }
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // the selected subcategory displayed as app bar title
          title: Text(widget.subcategoryName),
          centerTitle: true,
          actions: [
            // alert dialog to record time
            IconButton(
                onPressed: () => _showTimeAlertDialog(context),
                icon: const Icon(Icons.add))
          ],
        ),
        body: SingleChildScrollView(
          child: Consumer3<
              SubcategoryTrackerDatabaseProvider,
              CurrentDateProvider,
              UserUidProvider>(builder: (context, subs, date, user, child) {
            // Call retrieveCurrentDateSubcategories
            // to fetch subcategories for the current date
            subs.retrieveCurrentDateSubcategories(
                date.currentDate, user.userUid!, widget.subcategoryName);

            // Access the fetched subcategories from the provider
            List<Subcategories> subsTrackedOnCurrentDay =
                subs.currentDateSubcategories;

            return Container(
              margin: const EdgeInsets.only(top: 200),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // todays blocks title
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        AppString.blockTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 19),
                      ),
                    ),

                    // this list view generates all the time tracked
                    // for a subcategory for a particular day
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: subsTrackedOnCurrentDay.length,
                        itemBuilder: (BuildContext context, index) {
                          final convertedTimeRecorded = convertMinutesToTime(
                              subsTrackedOnCurrentDay[index].timeSpent);

                          return ListTile(
                            subtitle: Text(
                                "${AppString.timeCreated} ${subsTrackedOnCurrentDay[index].timeRecorded}",
                                style: const TextStyle(
                                  fontSize: 13,
                                )),
                            title: Text(convertedTimeRecorded),
                            trailing:
                                // deletes entry in the subcategory table
                                IconButton(
                              onPressed: () {
                                subs.deleteSubcategoryEntry(
                                    subsTrackedOnCurrentDay[index].id!);
                              },
                              icon: const Icon(Icons.delete_outlined),
                            ),
                          );
                        })
                  ]),
            );
          }),
        ));
  }
}
