import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_routes/mr_track/track_reusable/front_track.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';
import '../../../motion_core/mc_sql_table/assign_table.dart';
import '../../../motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
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
  final int itemIndexIsStreakActive;
  final String itemIndexStreakType;
  final double itemIndexStreakTargetMinutes;
  final String itemIndexStreakStartDate;

  const TrailingEditButtons(
      {super.key,
      required this.itemIndexId,
      required this.itemIndexSubcategoryName,
      required this.itemIndexMainCategoryName,
      required this.itemIndexCurrentUser,
      required this.itemIndexDateCreated,
      required this.itemIndexIsActive,
      required this.itemIndexIsArchive,
      required this.itemIndexIsStreakActive,
      required this.itemIndexStreakType,
      required this.itemIndexStreakTargetMinutes,
      required this.itemIndexStreakStartDate});

  @override
  State<TrailingEditButtons> createState() => _TrailingEditButtonsState();
}

class _TrailingEditButtonsState extends State<TrailingEditButtons> {
  Widget _dialogFieldPanel({
    required BuildContext context,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final itemColor = color ?? Theme.of(context).iconTheme.color;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: itemColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 13,
              fontweight: FontWeight.normal,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleArchive() {
    final archiveItem = context.read<AssignerMainProvider>();

    archiveItem.updateAssignedItems(Assigner(
        id: widget.itemIndexId,
        currentLoggedInUser: widget.itemIndexCurrentUser,
        subcategoryName: widget.itemIndexSubcategoryName,
        mainCategoryName: widget.itemIndexMainCategoryName,
        dateCreated: widget.itemIndexDateCreated,
        isActive: widget.itemIndexIsActive,
        isArchive: widget.itemIndexIsArchive == 0 ? 1 : 0,
        isStreakActive: widget.itemIndexIsStreakActive,
        streakType: widget.itemIndexStreakType,
        streakTargetMinutes: widget.itemIndexStreakTargetMinutes,
        streakStartDate: widget.itemIndexStreakStartDate));
  }

  Widget _editNameField({
    required BuildContext context,
    required ValueChanged<String> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return TextFormField(
      initialValue: widget.itemIndexSubcategoryName,
      onChanged: onChanged,
      cursorColor: AppColor.blueMainColor,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldColor,
        prefixIcon: const Icon(
          Icons.label_outline,
          color: AppColor.blueMainColor,
          size: 20,
        ),
        hintText: widget.itemIndexSubcategoryName,
        hintStyle: AppTextStyle.subSectionTextStyle(
          fontsize: 13,
          fontweight: FontWeight.normal,
          color: Colors.blueGrey,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColor.blueMainColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: FormValidator.subcategoryValidator,
    );
  }

  Widget _dialogActions({
    required BuildContext context,
    required String confirmLabel,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color confirmColor = AppColor.blueMainColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.16) : Colors.black12;
    final cancelTextColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: cancelTextColor,
              minimumSize: const Size(0, 44),
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
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmLabel,
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

  // this alert dialog is rendered when the user
  // clicks on the edit icon button in the trailing
  // part of the list tile
  void _showUpdateAlertDialog(context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final editFormKey = GlobalKey<FormState>();
    var editedSubcategoryName = widget.itemIndexSubcategoryName;

    // Show the update alert dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialogConst(
          heightFactor: 0.33,
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          alertDialogTitle:
              "Update ${widget.itemIndexSubcategoryName}", // Set the title of the dialog
          alertDialogContent: Form(
            key: editFormKey, // Form with a GlobalKey for validation
            child: Consumer<DropDownTrackProvider>(
              builder: (context, maincat, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Move it to a category and rename it if needed.",
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 12,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Update drop-down
                    _dialogFieldPanel(
                      context: dialogContext,
                      child: MyDropdownButton(
                        isUpdate: true,
                        mainCategoryName: widget.itemIndexMainCategoryName,
                        usePanelStyle: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subcategory name text field
                    _editNameField(
                      context: dialogContext,
                      onChanged: (value) {
                        editedSubcategoryName = value;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Cancel and update buttons
                    _dialogActions(
                      context: dialogContext,
                      confirmLabel: AppString.editPageUpdateButtonName,
                      onCancel: () {
                        // Close the dialog.
                        FocusScope.of(dialogContext).unfocus();
                        Navigator.of(dialogContext).pop();
                      },
                      onConfirm: () {
                        var updateItem =
                            dialogContext.read<AssignerMainProvider>();

                        if (editFormKey.currentState!.validate()) {
                          if (maincat.selectedValue == null) {
                            // Show a snackbar if no value is selected
                            snackBarMessage(context,
                                requiresColor: true,
                                errorMessage: AppString.editPageUpdateError);
                          } else {
                            // Trim white spaces from the subcategory name
                            String trimmedSubcategoryName =
                                editedSubcategoryName.trim();

                            // Update the assigned item and close the dialog
                            updateItem.updateAssignedItems(Assigner(
                              id: widget.itemIndexId,
                              currentLoggedInUser: widget.itemIndexCurrentUser,
                              subcategoryName: trimmedSubcategoryName,
                              mainCategoryName: maincat.selectedValue!,
                              dateCreated: widget.itemIndexDateCreated,
                              isActive: widget.itemIndexIsActive,
                              isArchive: widget.itemIndexIsArchive,
                              isStreakActive: widget.itemIndexIsStreakActive,
                              streakType: widget.itemIndexStreakType,
                              streakTargetMinutes:
                                  widget.itemIndexStreakTargetMinutes,
                              streakStartDate: widget.itemIndexStreakStartDate,
                            ));

                            FocusScope.of(dialogContext).unfocus();
                            Navigator.of(dialogContext).pop();
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
    ).whenComplete(() {
      if (!mounted) return;
      context.read<DropDownTrackProvider>().changeSelectedValue(null);
    });
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
          heightFactor: 0.18,
          screenHeight: screenHeight,
          screenWidth: screenWidth * 0.75,
          alertDialogTitle:
              "${AppString.deleteTitle} ${widget.itemIndexSubcategoryName}", // Set the title of the dialog
          alertDialogContent: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alert dialog message
              Text(
                "Are you sure you want to delete ${widget.itemIndexSubcategoryName}?",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 14,
                  fontweight: FontWeight.normal,
                ),
              ),

              const SizedBox(height: 18),

              // Buttons
              _dialogActions(
                context: context,
                confirmLabel: AppString.deleteTitle,
                confirmColor: Colors.redAccent,
                onCancel: () {
                  // Close the dialog
                  navigationKey.currentState!.pop();
                },
                onConfirm: () {
                  // Delete the assigned item and close the dialog
                  final deleteItem = context.read<AssignerMainProvider>();
                  deleteItem.deleteAssignedItems(id);

                  snackBarMessage(context,
                      errorMessage: "$subcategoryName has been deleted");

                  navigationKey.currentState!.pop();
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      tooltip: "More",
      color: Theme.of(context).popupMenuTheme.color,
      onSelected: (value) {
        if (value == "edit") {
          _showUpdateAlertDialog(context);
        } else if (value == "archive") {
          _toggleArchive();
        } else if (value == "delete") {
          _showDeleteAlertDialog(context,
              id: widget.itemIndexId,
              subcategoryName: widget.itemIndexSubcategoryName);
        }
      },
      itemBuilder: (context) {
        return [
          _menuItem(
            value: "edit",
            icon: Icons.edit_outlined,
            label: AppString.editPageAppBarTitle,
            color: AppColor.blueMainColor,
          ),
          _menuItem(
            value: "archive",
            icon: widget.itemIndexIsArchive == 0
                ? Icons.archive_outlined
                : Icons.unarchive_outlined,
            label: widget.itemIndexIsArchive == 0 ? "Archive" : "Unarchive",
            color: Colors.blueGrey,
          ),
          _menuItem(
            value: "delete",
            icon: Icons.delete_outline,
            label: AppString.deleteTitle,
            color: Colors.redAccent,
          ),
        ];
      },
    );
  }
}
