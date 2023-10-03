import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_track/track_reusable/front_track.dart';
import 'package:provider/provider.dart';

import '../../../motion_core/mc_sql_table/assign_table.dart';
import '../../../motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import '../../../motion_reusable/db_re/sub_ui.dart';
import '../../../motion_reusable/mu_reusable/user_reusable.dart';
import '../../../motion_reusable/mu_reusable/user_validator.dart';
import '../../../motion_themes/mth_app/app_strings.dart';

// edit page trailing buttons for delete and update
class TrailingEditButtons extends StatefulWidget {
  final int itemIndexId;
  final String itemIndexSubcategoryName;
  final String itemIndexMainCategoryName;
  final String itemIndexCurrentUser;
  final String itemIndexDateCreated;
  final int itemIndexIsActive;

  const TrailingEditButtons(
      {super.key,
      required this.itemIndexId,
      required this.itemIndexSubcategoryName,
      required this.itemIndexMainCategoryName,
      required this.itemIndexCurrentUser,
      required this.itemIndexDateCreated,
      required this.itemIndexIsActive});

  @override
  State<TrailingEditButtons> createState() => _TrailingEditButtonsState();
}

class _TrailingEditButtonsState extends State<TrailingEditButtons> {
  // edit subcategory controller
  final TextEditingController _editTextController = TextEditingController();

  final _editFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    _editTextController.dispose();
  }

  // icon button builder
  IconButton _buildIcon(
      {required VoidCallback onPressed, required Icon iconImage}) {
    return IconButton(iconSize: 20, onPressed: onPressed, icon: iconImage);
  }

  void _showUpdateAlertDialog(context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialogConst(
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              alertDialogTitle: "Update ${widget.itemIndexSubcategoryName}",
              alertDialogContent: Form(
                key: _editFormKey,
                child: Consumer<DropDownTrackProvider>(
                    builder: (context, maincat, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // divider
                      const Divider(),

                      // update drop down
                      MyDropdownButton(
                        isUpdate: true,
                        mainCategoryName: widget.itemIndexMainCategoryName,
                      ),

                      // subcategory name text field
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: TextFormFieldBuilder(
                            fieldTextEditingController: _editTextController,
                            fieldHintText: widget.itemIndexSubcategoryName,
                            fieldValidator: FormValidator.subcategoryValidator),
                      ),

                      // cancel and update buttons
                      CancelAddTextButtons(
                        firstButtonName: AppString.trackCancelTextButton,
                        secondButtonName: AppString.editPageUpdateButtonName,
                        onPressedFirst: () {
                          navigationKey.currentState!.pop();

                          maincat.changeSelectedValue(null);
                        },
                        onPressedSecond: () {
                          var updateItem = context.read<AssignerMainProvider>();

                          if (_editFormKey.currentState!.validate()) {
                            if (maincat.selectedValue == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Please select a value from the drop-down."),
                                ),
                              );
                            } else {
                              updateItem.updateAssignedItems(Assigner(
                                  id: widget.itemIndexId,
                                  currentLoggedInUser:
                                      widget.itemIndexCurrentUser,
                                  subcategoryName: _editTextController.text,
                                  mainCategoryName: maincat.selectedValue!,
                                  dateCreated: widget.itemIndexDateCreated,
                                  isActive: widget.itemIndexIsActive));

                              navigationKey.currentState!.pop();
                              maincat.changeSelectedValue(null);
                            }
                          }
                        },
                      )
                    ],
                  );
                }),
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    final deleteItem = context.read<AssignerMainProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // edit icon
        _buildIcon(
            onPressed: () => _showUpdateAlertDialog(context),
            iconImage: const Icon(Icons.edit)),

        // delete icon
        _buildIcon(
            onPressed: () => deleteItem.deleteAssignedItems(widget.itemIndexId),
            iconImage: const Icon(Icons.delete_outline))
      ],
    );
  }
}
