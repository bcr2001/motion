import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_provider.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner.dart';
import 'package:motion/motion_core/motion_providers/track_pcd/track.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
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
    return SizedBox(
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

  // alert dialog to create new subcategory
  void _showAlertDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(AppString.alertDialogTitle),
            content: SizedBox(
              height: screenHeight * 0.25,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // drop down menu to select main category
                    const MyDropdownButton(),


                    // text field to type subcategory name
                    TextFormFieldBuilder(
                        fieldKeyboardType: TextInputType.text,
                        fieldTextEditingController: subcategoryController,
                        fieldHintText: AppString.trackTextFormFieldHintText,
                        fieldValidator: FormValidator.subcategoryValidator),

                    // cancel and add buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // cancel
                        TextButton(
                            onPressed: () {
                              navigationKey.currentState!.pop();
                            },
                            child: Text(
                              AppString.trackCancelTextButton,
                              style: Theme.of(context).textTheme.bodyMedium,
                            )),

                        // add
                        TextButton(
                            onPressed: () {},
                            child: Text(
                              AppString.trackAddTextButton,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ))
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
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
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Consumer<AssignerProvider>(
            builder: (context, assignedList, child) {
              return ListView(
                children: [
                  // Education Category
                  _cardConstructor(context,
                      cardTitle: AppString.educationMainCategory,
                      cardListView: ListView.builder(
                          itemCount: assignedList.assignedItems.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, index) {
                            var assigned = assignedList.assignedItems[index];
                            return assigned.mainCategoryName == "Education"
                                ? ListTile(
                                    title: Text(assigned.subcategoryName),
                                  )
                                : const SizedBox.shrink();
                          })),
                ],
              );
            },
          ),
        ));
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
    return Consumer<TrackProvider>(
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
              Provider.of<TrackProvider>(context, listen: false)
                  .changeSelectedValue(newValue);
            }
          },
        );
      },
    );
  }
}
