import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../motion_themes/mth_styling/app_color.dart';

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
  final Set<int> _deletingBlockIds = {};
  bool _hasChangedTrackedTime = false;

  // Text editing controllers for hours, minutes, and seconds input fields
  TextEditingController hourController = TextEditingController();
  TextEditingController minuteController = TextEditingController();
  TextEditingController secondController = TextEditingController();

  Future<void> _resetDailyXpTargetCelebration(Subcategories block) async {
    if (block.currentLoggedInUser.isEmpty || block.date.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final celebrationKey =
        'daily_xp_target_celebration_v4_${block.currentLoggedInUser}-${block.date}';
    await prefs.remove(celebrationKey);
    logger.i(
      'XP TARGET CELEBRATION DIRECT: reset shown state after deleting a tracked block for ${block.date}.',
    );
  }

  @override
  void dispose() {
    // Dispose of the text editing controllers to prevent memory leaks
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();

    super.dispose();
  }

  // time component
  Widget _titleAndTextFieldBuilder(
      {required String title,
      required TextEditingController textEditingController}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final inputColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // time component titles
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 4),

            // text field for each time component
            TextFormField(
              controller: textEditingController,
              keyboardType: TextInputType.number,
              maxLength: 2,
              buildCounter: (BuildContext context,
                      {int? currentLength,
                      int? maxLength,
                      bool? isFocused}) =>
                  null,
              textAlign: TextAlign.center,
              cursorColor: AppColor.blueMainColor,
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 24),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "00",
                hintStyle: AppTextStyle.manualHintTextStyle(fontsize: 24),
              ),
              validator: (value) {
                // check whether the field is empty
                if (value == null || value.isEmpty) {
                  return "??";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeEntryBlock() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColor.blueMainColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.subcategoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // time component text fields displayed
          Row(
            children: [
              // hour time component
              _titleAndTextFieldBuilder(
                  title: "Hours", textEditingController: hourController),

              const SizedBox(width: 8),

              // minute time component
              _titleAndTextFieldBuilder(
                  title: "Minutes", textEditingController: minuteController),

              const SizedBox(width: 8),

              // seconds time component
              _titleAndTextFieldBuilder(
                  title: "Seconds", textEditingController: secondController)
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeDialogActions({
    required VoidCallback onCancel,
    required VoidCallback onAdd,
    required bool isBusy,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.16) : Colors.black12;
    final cancelTextColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: cancelTextColor,
              minimumSize: const Size(0, 42),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppString.trackCancelTextButton,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.w700,
                color: cancelTextColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isBusy ? null : onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.blueMainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppString.trackAddTextButton,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _todaysBlocksHeader({
    required int blockCount,
    required double totalMinutes,
  }) {
    final convertedTotal = convertMinutesToTime(totalMinutes);

    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.event_note_outlined,
            color: AppColor.blueMainColor,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppString.blockTitle,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 15,
                  fontweight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "$blockCount ${blockCount == 1 ? "block" : "blocks"} | $convertedTotal",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trackedBlockTile({
    required int index,
    required String convertedTimeRecorded,
    required VoidCallback onDelete,
    required bool isDeleting,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final tileColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.025);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11,
                  fontweight: FontWeight.w800,
                  color: AppColor.blueMainColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              convertedTimeRecorded,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 15,
                fontweight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: isDeleting ? null : onDelete,
            visualDensity: VisualDensity.compact,
            icon: isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _todaysBlocksPanel({
    required List<Subcategories> blocks,
    required SubcategoryTrackerDatabaseProvider subs,
  }) {
    final xpProvider = context.read<ExperiencePointTableProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final totalMinutes = blocks.fold<double>(
        0.0, (previousValue, item) => previousValue + item.timeSpent);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _todaysBlocksHeader(
            blockCount: blocks.length,
            totalMinutes: totalMinutes,
          ),
          if (blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                "No time blocks added yet",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            )
          else
            ...blocks.asMap().entries.map((entry) {
              final block = entry.value;
              final convertedTimeRecorded =
                  convertMinutesToTime(block.timeSpent);

              return _trackedBlockTile(
                index: entry.key,
                convertedTimeRecorded: convertedTimeRecorded,
                isDeleting:
                    block.id != null && _deletingBlockIds.contains(block.id),
                onDelete: () async {
                  final blockId = block.id;
                  if (blockId == null || _deletingBlockIds.contains(blockId)) {
                    return;
                  }

                  setState(() => _deletingBlockIds.add(blockId));
                  try {
                    await subs.deleteSubcategoryEntry(
                      blockId,
                      deletedSubcategory: block,
                    );
                    _hasChangedTrackedTime = true;
                    await _resetDailyXpTargetCelebration(block);
                    xpProvider.refreshExperiencePointViews();
                  } finally {
                    if (mounted) {
                      setState(() => _deletingBlockIds.remove(blockId));
                    }
                  }
                },
              );
            }),
        ],
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
          var isAddingBlock = false;
          var subTrackerProvider =
              context.read<SubcategoryTrackerDatabaseProvider>();

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialogConst(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
                heightFactor: 0.28,
                alertDialogTitle: AppString.manualAddBlock,
                alertDialogContent: Form(
                  key: _timeFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _timeEntryBlock(),

                      const SizedBox(height: 16),

                      // cancel and add button
                      Consumer4<
                          CurrentDateProvider,
                          UserUidProvider,
                          MainCategoryTrackerProvider,
                          ExperiencePointTableProvider>(
                        builder: (context, date, uid, mainCat, xp, child) {
                          return _timeDialogActions(
                            onCancel: () {
                              // exits the alart dialog and resets the text
                              // contoller content
                              navigationKey.currentState!.pop();

                              hourController.text = "";
                              minuteController.text = "";
                              secondController.text = "";
                            },
                            onAdd: () async {
                              if (isAddingBlock) {
                                return;
                              }

                              final currentUser = uid.userUid;
                              if (currentUser == null) {
                                snackBarMessage(context,
                                    errorMessage:
                                        AppString.firebaseSomethingWentWrong,
                                    requiresColor: true);
                                return;
                              }

                              // adds the necessary data to the subcategory
                              // table if validation passes
                              if (_timeFormKey.currentState!.validate()) {
                                _timeFormKey.currentState!.save();
                                setDialogState(() => isAddingBlock = true);
                                var shouldCloseDialog = false;

                                // checks whether the text the user passes into the
                                // text fields are indeed values and not strings
                                try {
                                  if (hourController.text.contains('.') ||
                                      minuteController.text.contains('.') ||
                                      secondController.text.contains('.') ||
                                      hourController.text.contains('-') ||
                                      minuteController.text.contains('-') ||
                                      secondController.text.contains('-')) {
                                    // if either texts contains "." or "-" then
                                    // the error message below will pop up
                                    snackBarMessage(context,
                                        errorMessage:
                                            AppString.manualInvalidValueError,
                                        requiresColor: true);

                                    logger.e("Invald use of a dot");
                                  }
                                  // checks whether the values entered fall within
                                  // a specific range, if not then an error message
                                  // will be displayed
                                  else if (int.parse(hourController.text) >
                                          25 ||
                                      int.parse(minuteController.text) > 59 ||
                                      int.parse(secondController.text) > 59) {
                                    // snack bar that alerts the user when the
                                    // entries are out of range
                                    snackBarMessage(context,
                                        errorMessage:
                                            AppString.manualRangeValueError,
                                        requiresColor: true);
                                    logger.i("Failed Validation");
                                  } else {
                                    logger.i("Passed Validation");

                                    // Check if the date and currentLoggedInUser
                                    // exist in the main category table
                                    final mainCategoryExists1 =
                                        await mainCategoryExists(
                                            date.currentDate, currentUser);

                                    final experiencePointsExists2 =
                                        await experiencePointsExists(
                                            date.currentDate, currentUser);

                                    logger.i(mainCategoryExists1);

                                    if (!experiencePointsExists2) {
                                      logger.i(
                                          "a new row is being added into the experience_point table");
                                      // Insert date and currentLoggedInUser into
                                      //the experience_point table
                                      final experiencePointInsert =
                                          ExperiencePoints(
                                        date: date.currentDate,
                                        currentLoggedInUser: currentUser,
                                      );

                                      await xp.insertIntoExperiencePoint(
                                          experiencePointInsert);
                                      logger.i("a new row has been inserted");
                                    }

                                    if (!mainCategoryExists1) {
                                      logger.i("Main Category is being added");
                                      logger.i(date.currentDate);
                                      logger.i(currentUser);
                                      // Insert date and currentLoggedInUser into
                                      //the main category table
                                      final mainCategory = MainCategory(
                                        date: date.currentDate,
                                        currentLoggedInUser: currentUser,
                                      );

                                      await mainCat
                                          .insertIntoMainCategoryTable(
                                              mainCategory);
                                      logger.i("a new row has been inserted");
                                    }

                                    final subcategory = Subcategories(
                                        date: date.currentDate,
                                        mainCategoryName:
                                            widget.mainCategoryName,
                                        subcategoryName: widget.subcategoryName,
                                        currentLoggedInUser: currentUser,
                                        // timeAdder functions converts all the time components to minutes
                                        timeSpent: timeAdder(
                                            h: hourController.text,
                                            m: minuteController.text,
                                            s: secondController.text));

                                    await subTrackerProvider
                                        .insertIntoSubcategoryTable(
                                            subcategory);
                                    _hasChangedTrackedTime = true;
                                    xp.refreshExperiencePointViews();
                                    shouldCloseDialog = true;

                                    hourController.text = "";
                                    minuteController.text = "";
                                    secondController.text = "";
                                  }
                                } finally {
                                  if (!shouldCloseDialog && context.mounted) {
                                    setDialogState(
                                        () => isAddingBlock = false);
                                  }
                                }

                                if (shouldCloseDialog) {
                                  navigationKey.currentState!.pop();
                                }
                              }
                            },
                            isBusy: isAddingBlock,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChangedTrackedTime);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChangedTrackedTime),
          ),
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
            final currentUser = user.userUid;
            if (currentUser == null) {
              return userLoadingIndicator();
            }

            // Call retrieveCurrentDateSubcategories
            // to fetch subcategories for the current date
            subs.retrieveCurrentDateSubcategories(
                date.currentDate, currentUser, widget.subcategoryName);

            // Access the fetched subcategories from the provider
            List<Subcategories> subsTrackedOnCurrentDay =
                subs.currentDateSubcategories;

            return Container(
              margin: const EdgeInsets.only(top: 10),
              child: _todaysBlocksPanel(
                blocks: subsTrackedOnCurrentDay,
                subs: subs,
              ),
            );
          }),
        ),
      ),
    );
  }
}
