import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../../motion_themes/mth_app/app_strings.dart';
import 'edit_reusable.dart';

// allows user to change the subcategory names, it's main category assignment
// and whether to archive a subcategory
class TrackEditingPage extends StatelessWidget {
  const TrackEditingPage({super.key});

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

  Widget _editHeader({
    required int totalCount,
    required int archivedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$totalCount subcategories",
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 13,
                fontweight: FontWeight.w700,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Text(
            "$archivedCount archived",
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editItemCard(BuildContext context, Assigner item) {
    final categoryColor = _categoryColor(item.mainCategoryName);
    final isArchived = item.isArchive == 1;
    final isActive = item.isActive == 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final cardColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isArchived ? Colors.blueGrey.withValues(alpha: 0.06) : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 58,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subcategoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 14,
                      fontweight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.mainCategoryName} | ${isActive ? "Active" : "Off"}${isArchived ? " | Archived" : ""}",
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
          ),
          TrailingEditButtons(
            itemIndexDateCreated: item.dateCreated,
            itemIndexIsActive: item.isActive,
            itemIndexCurrentUser: item.currentLoggedInUser,
            itemIndexSubcategoryName: item.subcategoryName,
            itemIndexId: item.id,
            itemIndexMainCategoryName: item.mainCategoryName,
            itemIndexIsArchive: item.isArchive,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.editPageAppBarTitle),
      ),
      body: Consumer2<AssignerMainProvider, UserUidProvider>(
        builder: (context, assigner, user, child) {
          final currentUser = user.userUid;

          if (currentUser == null) {
            return userLoadingIndicator();
          }

          final assignedItems = assigner.assignerItems
              .where((item) => item.currentLoggedInUser == currentUser)
              .toList();
          final archivedCount =
              assignedItems.where((item) => item.isArchive == 1).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              _editHeader(
                totalCount: assignedItems.length,
                archivedCount: archivedCount,
              ),
              ...assignedItems.map((item) => _editItemCard(context, item)),
            ],
          );
        },
      ),
    );
  }
}
