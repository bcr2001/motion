import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_routes/mr_track/track_reusable/front_track.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
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

  final List<String> _mainCategories = const [
    AppString.educationMainCategory,
    AppString.workMainCategory,
    AppString.skillMainCategory,
    AppString.entertainmentMainCategory,
    AppString.selfDevelopmentMainCategory,
    AppString.sleepMainCategory,
  ];

  @override
  void dispose() {
    // Dispose of the subcategoryController to release any resources.
    subcategoryController.dispose();

    // Call the dispose method of the superclass to perform any additional cleanup.
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
          isArchive: item.isArchive),
    );
  }

  Color _categoryColor(String categoryName) {
    if (categoryName == AppString.educationMainCategory) {
      return AppColor.educationPieChartColor;
    }
    if (categoryName == AppString.workMainCategory) {
      return AppColor.workPieChartColor;
    }
    if (categoryName == AppString.skillMainCategory) {
      return AppColor.skillsPieChartColor;
    }
    if (categoryName == AppString.entertainmentMainCategory) {
      return AppColor.entertainmentPieChartColor;
    }
    if (categoryName == AppString.selfDevelopmentMainCategory) {
      return AppColor.selfDevelopmentPieChartColor;
    }
    return AppColor.sleepPieChartColor;
  }

  IconData _categoryIcon(String categoryName) {
    if (categoryName == AppString.educationMainCategory) {
      return Icons.school_outlined;
    }
    if (categoryName == AppString.workMainCategory) {
      return Icons.work_outline;
    }
    if (categoryName == AppString.skillMainCategory) {
      return Icons.psychology_outlined;
    }
    if (categoryName == AppString.entertainmentMainCategory) {
      return Icons.movie_filter_outlined;
    }
    if (categoryName == AppString.selfDevelopmentMainCategory) {
      return Icons.self_improvement_outlined;
    }
    return Icons.bedtime_outlined;
  }

  List<Assigner> _itemsForCategory({
    required List<Assigner> items,
    required String? user,
    required String categoryName,
  }) {
    return items
        .where((item) =>
            item.currentLoggedInUser == user &&
            item.mainCategoryName == categoryName &&
            item.isArchive == 0)
        .toList();
  }

  Widget _subcategoryTile(Assigner item) {
    final isActive = item.isActive == 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final tileColor = isActive
        ? AppColor.blueMainColor.withValues(alpha: isDarkMode ? 0.12 : 0.08)
        : Colors.transparent;
    final statusColor = isActive ? AppColor.blueMainColor : Colors.blueGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.subcategoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 14,
                fontweight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            height: 28,
            constraints: const BoxConstraints(minWidth: 62),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: TextButton(
              onPressed: () async => _handleItemPressed(context, item),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: statusColor,
              ),
              child: Text(
                isActive ? "Active" : "Off",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11,
                  fontweight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection({
    required String categoryName,
    required List<Assigner> categoryItems,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _categoryColor(categoryName);
    final activeCount =
        categoryItems.where((item) => item.isActive == 1).length;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _categoryIcon(categoryName),
                  color: categoryColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 15,
                    fontweight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$activeCount/${categoryItems.length}",
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categoryItems.isEmpty)
            Text(
              "No subcategories yet",
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            )
          else
            ...categoryItems.map(_subcategoryTile),
        ],
      ),
    );
  }

  Widget _newSubcategoryHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final helperTextColor = isDarkMode ? Colors.white60 : Colors.blueGrey;

    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_task_outlined,
            color: AppColor.blueMainColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Assign a subcategory to the main category it belongs to.",
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12,
              fontweight: FontWeight.normal,
              color: helperTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogFieldPanel({
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

  Widget _subcategoryNameField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return TextFormField(
      controller: subcategoryController,
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
        hintText: AppString.trackTextFormFieldHintText,
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

  Widget _trackDialogActions({
    required VoidCallback onCancel,
    required VoidCallback onAdd,
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
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.blueMainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
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
            heightFactor: 0.324,
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            alertDialogTitle: AppString.newAlertDialogTitle,
            alertDialogContent: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _newSubcategoryHeader(),

                  const SizedBox(height: 16),

                  // main category drop down button
                  _dialogFieldPanel(
                    child: const MyDropdownButton(
                      isUpdate: false,
                      usePanelStyle: true,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // subcategory name text field
                  _subcategoryNameField(),

                  const SizedBox(height: 18),

                  // Cancel and Add Text Buttons
                  _trackDialogActions(
                    onCancel: () {
                      navigationKey.currentState!.pop();
                      mainCategoryProvider.changeSelectedValue(null);
                    },
                    onAdd: () {
                      if (_formKey.currentState!.validate()) {
                        if (mainCategoryProvider.selectedValue == null) {
                          snackBarMessage(context,
                              errorMessage:
                                  AppString.trackMainCategoryNotSelectedError);
                        } else {
                          _formKey.currentState!.save();

                          // Trim white spaces from the subcategory name
                          String trimmedSubcategoryName =
                              subcategoryController.text.trim();

                          Provider.of<AssignerMainProvider>(context,
                                  listen: false)
                              .insertIntoAssignerDb(Assigner(
                            currentLoggedInUser: userUidProvider.userUid == null
                                ? AppString.unknown
                                : userUidProvider.userUid!,
                            subcategoryName: trimmedSubcategoryName,
                            mainCategoryName:
                                mainCategoryProvider.selectedValue!,
                            dateCreated: date.currentDate,
                          ));
                          snackBarMessage(context,
                              errorMessage:
                                  "${subcategoryController.text} added to the ${mainCategoryProvider.selectedValue} Category");

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTrackAlertDialog(context),
        backgroundColor: AppColor.blueMainColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Text(
          AppString.addItem,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 13,
            fontweight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),

      body: Consumer2<AssignerMainProvider, UserUidProvider>(
        builder: (context, assignedList, userUiD, child) {
          final items = assignedList.assignerItems;
          final user = userUiD.userUid;

          if (user == null) {
            return userLoadingIndicator();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 92),
            children: _mainCategories.map((categoryName) {
              return _categorySection(
                categoryName: categoryName,
                categoryItems: _itemsForCategory(
                  items: items,
                  user: user,
                  categoryName: categoryName,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
