import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_reusable/sub_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:provider/provider.dart';

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
    final provider = context.read<AssignerMainProvider>();
    await provider.updateAssignedItems(
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
        : const Icon(Icons.check_box_outlined);

    print("current active state $activeStatus");

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer3<UserUidProvider, DropDownTrackProvider,
            CurrentDataProvider>(
          builder: (context, userUid, mainCategory, date, child) {
            // Save references to the providers
            final userUidProvider = userUid;
            final mainCategoryProvider = mainCategory;

            return AlertDialog(
              title: const Text(AppString.alertDialogTitle),
              content: SizedBox(
                height: screenHeight * 0.25,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const MyDropdownButton(),

                      TextFormFieldBuilder(
                          fieldTextEditingController: subcategoryController,
                          fieldHintText: AppString.trackTextFormFieldHintText,
                          fieldValidator: FormValidator.subcategoryValidator
                          ),

                      // Cancel and Add Text Buttons
                      CancelAddTextButtons(
                        onPressedCancel: () =>
                            navigationKey.currentState!.pop(),
                        onPressedAdd: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            Provider.of<AssignerMainProvider>(context,
                                    listen: false)
                                .insertIntoAssignerDb(Assigner(
                              currentLoggedInUser:
                                  userUidProvider.userUid == null
                                      ? "unknown"
                                      : userUidProvider.userUid!,
                              subcategoryName: subcategoryController.text,
                              mainCategoryName:
                                  mainCategoryProvider.selectedValue!,
                              dateCreated: date.currentData,
                            ));
                            navigationKey.currentState!.pop();
                            subcategoryController.text = "";
                            mainCategoryProvider.changeSelectedValue(null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.motionRouteTitle),
      ),
      // displays the alert dialog to add ne subcategories
      floatingActionButton: floatingActionButton(
        context,
        onPressed: () => _showTrackAlertDialog(context), label: AppString.addItem, 
        icon: Icons.add), 

      body: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 85),
          child: Consumer2<AssignerMainProvider, UserUidProvider>(
            builder: (context, assignedList, userUiD, child) {
              var items = assignedList.assignerItems;
              var user = userUiD.userUid;

              return ListView(
                children: [
                  // user ui
                  Consumer<UserUidProvider>(
                    builder: (context, user, child) {
                      return Text("Current User: ${user.userUid}");
                    },
                  ),

                  // education category
                  CardConstructor(
                    cardTitle: AppString.educationMainCategory, cardListView: ListView.builder(
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
                    cardTitle: AppString.skillMainCategory, cardListView: ListView.builder(
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
                    cardTitle: AppString.entertainmentMainCategory, cardListView: ListView.builder(
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
                    cardTitle:  AppString.pgMainCategory, 
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
                    cardTitle:  AppString.sleepMainCategory, 
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

class MyDropdownButton extends StatefulWidget {
  const MyDropdownButton({super.key});

  @override
  State<MyDropdownButton> createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {
  List<String> listItems = [
    "Education",
    "Skills",
    "Entertainment",
    "Personal Growth",
    "Sleep"
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<DropDownTrackProvider>(
      builder: (context, selectedValue, child) {
        return DropdownButton(
          isExpanded: true,
          elevation: 0,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 28,
          value: selectedValue.selectedValue,
          hint: const Text(AppString.trackDropDownHintText),
          items: listItems.map((String value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              Provider.of<DropDownTrackProvider>(context, listen: false)
                  .changeSelectedValue(newValue);
            }
          },
        );
      },
    );
  }
}
