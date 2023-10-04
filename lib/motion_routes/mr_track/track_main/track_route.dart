import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_routes/mr_track/track_reusable/front_track.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';

// this is the page where users create and
// assign subcategories to maincategories
// and also indicate whether they are tracking
// a particular subcategory in the home page
class MotionTrackRoute extends StatefulWidget {
  const MotionTrackRoute({super.key});

  @override
  State<MotionTrackRoute> createState() => _MotionTrackRouteState();
}

class _MotionTrackRouteState extends State<MotionTrackRoute> {
  // form key
  final _formKey = GlobalKey<FormState>();

  // subcategory text editting controller
  TextEditingController subcategoryController = TextEditingController();

  @override
  void dispose() {
    subcategoryController.dispose();
    super.dispose();
  }

  // Define a reusable function for onPressed
  Future<void> _handleItemPressed(BuildContext context, Assigner item) async {
    final updateItem = context.read<AssignerMainProvider>();

    await updateItem.updateAssignedItems(
      Assigner(
        id: item.id,
        currentLoggedInUser: item.currentLoggedInUser,
        subcategoryName: item.subcategoryName,
        mainCategoryName: item.mainCategoryName,
        dateCreated: item.dateCreated,
        isActive: item.isActive == 0 ? 1 : 0,
      ),
    );
  }

  // list tile
  // Usage of the _handleItemPressed function
  ListTile _listTileBuilder({
    required String tileTitle,
    required int activeStatus,
    required Assigner item, // Pass the Assigner item here
  }) {
    Icon iconSelected = activeStatus == 0
        ? const Icon(Icons.check_box_outline_blank_rounded)
        : const Icon(Icons.check_box_outlined, color: AppColor.blueMainColor,);

    return ListTile(
      title: Text(tileTitle),
      trailing: IconButton(
          onPressed: () async {
            await _handleItemPressed(context, item);
          },
          icon: iconSelected),
    );
  }

  // alert dialog to create new subcategory
  void _showTrackAlertDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer3<UserUidProvider, DropDownTrackProvider,
                CurrentDateProvider>(
            builder: (context, userUid, mainCategory, date, child) {
          // Save references to the providers
          final userUidProvider = userUid;
          final mainCategoryProvider = mainCategory;

          return AlertDialogConst(
            heightFactor: 0.30,
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            alertDialogTitle: AppString.newAlertDialogTitle,
            alertDialogContent: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // divider
                  const Divider(),

                  // main category drop down button
                  const MyDropdownButton(
                    isUpdate: false,
                  ),

                  // subcategory name text field
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    child: TextFormFieldBuilder(
                        fieldTextEditingController: subcategoryController,
                        fieldHintText: AppString.trackTextFormFieldHintText,
                        fieldValidator: FormValidator.subcategoryValidator),
                  ),

                  // Cancel and Add Text Buttons
                  CancelAddTextButtons(
                    firstButtonName: AppString.trackCancelTextButton,
                    secondButtonName: AppString.trackAddTextButton,
                    onPressedFirst: () {
                      navigationKey.currentState!.pop();
                      mainCategoryProvider.changeSelectedValue(null);
                    },
                    onPressedSecond: () {
                      if (_formKey.currentState!.validate()) {
                        if (mainCategoryProvider.selectedValue == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please select a value from the drop-down."),
                            ),
                          );
                        } else {
                          _formKey.currentState!.save();
                          Provider.of<AssignerMainProvider>(context,
                                  listen: false)
                              .insertIntoAssignerDb(Assigner(
                            currentLoggedInUser: userUidProvider.userUid == null
                                ? "unknown"
                                : userUidProvider.userUid!,
                            subcategoryName: subcategoryController.text,
                            mainCategoryName:
                                mainCategoryProvider.selectedValue!,
                            dateCreated: date.currentDate,
                          ));
                          navigationKey.currentState!.pop();
                          subcategoryController.text = "";
                          mainCategoryProvider.changeSelectedValue(null);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.motionRouteTitle),
        actions: const [
          // edit pop up button
          TrackEditPopUpMenu()
        ],
      ),

      // displays the alert dialog to add ne subcategories
      floatingActionButton: floatingActionButton(context,
          onPressed: () => _showTrackAlertDialog(context),
          label: AppString.addItem,
          icon: Icons.add),

      body: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 85),
          child: Consumer2<AssignerMainProvider, UserUidProvider>(
            builder: (context, assignedList, userUiD, child) {
              var items = assignedList.assignerItems;
              var user = userUiD.userUid;

              return ListView(
                children: [
                  // education category
                  CardConstructor(
                      cardTitle: AppString.educationMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, index) {
                            return items[index].currentLoggedInUser == user &&
                                    items[index].mainCategoryName == "Education"
                                ? _listTileBuilder(
                                    activeStatus: items[index].isActive,
                                    tileTitle: items[index].subcategoryName,
                                    item: items[index])
                                : const SizedBox.shrink();
                          })),

                  // // skills category
                  CardConstructor(
                      cardTitle: AppString.skillMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, index) {
                            return items[index].currentLoggedInUser == user &&
                                    items[index].mainCategoryName == "Skills"
                                ? _listTileBuilder(
                                    activeStatus: items[index].isActive,
                                    tileTitle: items[index].subcategoryName,
                                    item: items[index])
                                : const SizedBox.shrink();
                          })),

                  // entertainment category
                  CardConstructor(
                      cardTitle: AppString.entertainmentMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, index) {
                            return items[index].currentLoggedInUser == user &&
                                    items[index].mainCategoryName ==
                                        "Entertainment"
                                ? _listTileBuilder(
                                    activeStatus: items[index].isActive,
                                    tileTitle: items[index].subcategoryName,
                                    item: items[index])
                                : const SizedBox.shrink();
                          })),

                  // personal growth category
                  CardConstructor(
                      cardTitle: AppString.pgMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, index) {
                            return items[index].currentLoggedInUser == user &&
                                    items[index].mainCategoryName ==
                                        "Personal Growth"
                                ? _listTileBuilder(
                                    activeStatus: items[index].isActive,
                                    tileTitle: items[index].subcategoryName,
                                    item: items[index])
                                : const SizedBox.shrink();
                          })),

                  //sleep category
                  CardConstructor(
                      cardTitle: AppString.sleepMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, index) {
                            return items[index].currentLoggedInUser == user &&
                                    items[index].mainCategoryName == "Sleep"
                                ? _listTileBuilder(
                                    activeStatus: items[index].isActive,
                                    tileTitle: items[index].subcategoryName,
                                    item: items[index])
                                : const SizedBox.shrink();
                          }))
                ],
              );
            },
          )),
    );
  }
}
