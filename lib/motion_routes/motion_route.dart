import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sqlite/main_and_sub.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner.dart';
import 'package:motion/motion_core/motion_providers/track_pcd/track.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
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

  // card constructor
  Widget _cardConstructor(context,
      {required cardTitle, required ListView cardListView}) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
              child: Text(
                cardTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Divider(
                thickness: 1.5,
                color: Colors.black,
              ),
            ),
            cardListView
          ],
        ),
      ),
    );
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
        icon: iconSelected
      ),
    );
  }

  // alert dialog to create new subcategory
  void _showAlertDialog(BuildContext context) {
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
                          fieldValidator: FormValidator.subcategoryValidator),

                      // Buttons that use saved provider references
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              navigationKey.currentState!.pop();
                            },
                            child: Text(
                              AppString.trackCancelTextButton,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
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
                              }
                              navigationKey.currentState!.pop();
                              subcategoryController.text = "";
                              mainCategoryProvider.changeSelectedValue(null);
                            },
                            child: Text(
                              AppString.trackAddTextButton,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAlertDialog(context);
        },
        label: Text(
          AppString.addItem,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        icon: Icon(
          Icons.add,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
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
                  _cardConstructor(context,
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
                  _cardConstructor(context,
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
                  _cardConstructor(context,
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
                  _cardConstructor(context,
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
                  _cardConstructor(context,
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
                          })),
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
