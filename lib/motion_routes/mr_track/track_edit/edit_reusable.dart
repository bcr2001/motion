import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_track/track_reusable/front_track.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/mc_sql_table/assign_table.dart';
import '../../../motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import '../../../motion_reusable/db_re/sub_ui.dart';
import '../../../motion_reusable/mu_reusable/user_reusable.dart';
import '../../../motion_reusable/mu_reusable/user_validator.dart';
import '../../../motion_themes/mth_app/app_strings.dart';
import '../../../motion_themes/mth_styling/motion_text_styling.dart';

// edit page trailing buttons for delete and update
class TrailingEditButtons extends StatefulWidget {
  final int itemIndexId;
  final String itemIndexSubcategoryName;
  final String itemIndexMainCategoryName;
  final String itemIndexCurrentUser;
  final String itemIndexDateCreated;
  final int itemIndexIsArchive;
  final int itemIndexIsActive;

  const TrailingEditButtons(
      {super.key,
      required this.itemIndexId,
      required this.itemIndexSubcategoryName,
      required this.itemIndexMainCategoryName,
      required this.itemIndexCurrentUser,
      required this.itemIndexDateCreated,
      required this.itemIndexIsActive,
      required this.itemIndexIsArchive});

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
      {required VoidCallback onPressed,
      required Icon iconImage,
      bool isArchive = false,
      int archiveStatus = 0}) {
    Icon iconSelectedArchive = archiveStatus == 0
        ? const Icon(Icons.archive_outlined)
        : const Icon(
            Icons.archive_outlined,
            color: AppColor.blueMainColor,
          );

    return isArchive
        ? IconButton(
            iconSize: 18, onPressed: onPressed, icon: iconSelectedArchive)
        : IconButton(iconSize: 18, onPressed: onPressed, icon: iconImage);
  }

  // this alert dialog is rendered when the user
  // clicks on the edit icon button in the trailing
  // part of the list tile
  void _showUpdateAlertDialog(context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show the update alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialogConst(
          heightFactor: 0.28,
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          alertDialogTitle:
              "Update ${widget.itemIndexSubcategoryName}", // Set the title of the dialog
          alertDialogContent: Form(
            key: _editFormKey, // Form with a GlobalKey for validation
            child: Consumer<DropDownTrackProvider>(
              builder: (context, maincat, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Divider
                    const Divider(),

                    // Update drop-down
                    MyDropdownButton(
                      isUpdate: true,
                      mainCategoryName: widget.itemIndexMainCategoryName,
                    ),

                    // Subcategory name text field
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: TextFormFieldBuilder(
                        fieldTextEditingController: _editTextController,
                        fieldHintText: widget.itemIndexSubcategoryName,
                        fieldValidator: FormValidator.subcategoryValidator,
                      ),
                    ),

                    // Cancel and update buttons
                    CancelAddTextButtons(
                      firstButtonName: AppString.trackCancelTextButton,
                      secondButtonName: AppString.editPageUpdateButtonName,
                      onPressedFirst: () {
                        // Close the dialog and reset selected value
                        navigationKey.currentState!.pop();
                        maincat.changeSelectedValue(null);
                      },
                      onPressedSecond: () {
                        var updateItem = context.read<AssignerMainProvider>();

                        if (_editFormKey.currentState!.validate()) {
                          if (maincat.selectedValue == null) {
                            // Show a snackbar if no value is selected
                            snackBarMessage(context,
                                requiresColor: true,
                                errorMessage: AppString.editPageUpdateError);
                          } else {


                              // Trim white spaces from the subcategory name
                            String trimmedSubcategoryName =
                                _editTextController.text.trim();

                            // Update the assigned item and close the dialog
                            updateItem.updateAssignedItems(Assigner(
                              id: widget.itemIndexId,
                              currentLoggedInUser: widget.itemIndexCurrentUser,
                              subcategoryName: trimmedSubcategoryName,
                              mainCategoryName: maincat.selectedValue!,
                              dateCreated: widget.itemIndexDateCreated,
                              isActive: widget.itemIndexIsActive,
                            ));

                            navigationKey.currentState!.pop();
                            maincat.changeSelectedValue(null);
                          }
                        }
                      },
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // this alert dialog is a confirmation for whether the
  // user want to delete a subcategory when the delete
  // icon in the trailing part of the list tile is clicked
  void _showDeleteAlertDialog(context,
      {required id, required subcategoryName}) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show the delete alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialogConst(
          heightFactor: 0.15,
          screenHeight: screenHeight,
          screenWidth: screenWidth * 0.75,
          alertDialogTitle:
              "${AppString.deleteTitle} ${widget.itemIndexSubcategoryName}", // Set the title of the dialog
          alertDialogContent: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Divider
              const Divider(),

              // Alert dialog message
              Text(
                  "Are you sure you want to delete ${widget.itemIndexSubcategoryName}?",
                  style: AppTextStyle.subSectionTextStyle(fontsize: 15, fontweight: FontWeight.normal),),

              // Buttons
              CancelAddTextButtons(
                onPressedFirst: () {
                  // Close the dialog
                  navigationKey.currentState!.pop();
                },
                onPressedSecond: () {
                  // Delete the assigned item and close the dialog
                  final deleteItem = context.read<AssignerMainProvider>();
                  deleteItem.deleteAssignedItems(id);

                  snackBarMessage(
                    context, 
                    errorMessage: "$subcategoryName has been deleted");

                  navigationKey.currentState!.pop();
                },
                firstButtonName: AppString.cancelTitle,
                secondButtonName: AppString.deleteTitle,
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // edit icon
        _buildIcon(
            onPressed: () => _showUpdateAlertDialog(context),
            iconImage: const Icon(Icons.edit)),

        // archive icon

        _buildIcon(
            isArchive: true,
            archiveStatus: widget.itemIndexIsArchive,
            onPressed: () {

              final archiveItem = context.read<AssignerMainProvider>();

              archiveItem.updateAssignedItems(Assigner(
                  id: widget.itemIndexId,
                  currentLoggedInUser: widget.itemIndexCurrentUser,
                  subcategoryName: widget.itemIndexSubcategoryName,
                  mainCategoryName: widget.itemIndexMainCategoryName,
                  dateCreated: widget.itemIndexDateCreated,
                  isActive: widget.itemIndexIsActive,
                  isArchive: widget.itemIndexIsArchive == 0 ? 1 : 0));
            },
            iconImage: const Icon(Icons.archive_outlined)),

        // delete icon
        _buildIcon(
            onPressed: () {
              _showDeleteAlertDialog(context,
                  id: widget.itemIndexId,
                  subcategoryName: widget.itemIndexSubcategoryName);
            },
            iconImage: const Icon(Icons.delete_outline))
      ],
    );
  }
}
