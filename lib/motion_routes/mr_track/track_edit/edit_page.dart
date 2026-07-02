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
class TrackEditingPage extends StatefulWidget {
  const TrackEditingPage({super.key});

  @override
  State<TrackEditingPage> createState() => _TrackEditingPageState();
}

class _TrackEditingPageState extends State<TrackEditingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  bool _matchesSearch(Assigner item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    return item.subcategoryName.toLowerCase().contains(query) ||
        item.mainCategoryName.toLowerCase().contains(query);
  }

  Widget _searchField(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final fillColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final hintColor = isDarkMode ? Colors.white60 : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _searchController,
        cursorColor: AppColor.blueMainColor,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 13,
          fontweight: FontWeight.normal,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColor.blueMainColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: hintColor,
                    size: 19,
                  ),
                ),
          hintText: 'Search subcategories',
          hintStyle: AppTextStyle.subSectionTextStyle(
            fontsize: 13,
            fontweight: FontWeight.normal,
            color: hintColor,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColor.blueMainColor, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _editHeader({
    required int totalCount,
    required int archivedCount,
    required int visibleCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _searchQuery.trim().isEmpty
                  ? "$totalCount subcategories"
                  : "$visibleCount of $totalCount subcategories",
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

  Widget _emptySearchState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 56),
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColor.blueMainColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No matching subcategories',
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 14,
              fontweight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try a different subcategory or main category name.',
            textAlign: TextAlign.center,
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
            itemIndexIsStreakActive: item.isStreakActive,
            itemIndexStreakType: item.streakType,
            itemIndexStreakTargetMinutes: item.streakTargetMinutes,
            itemIndexStreakStartDate: item.streakStartDate,
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
          final visibleItems = assignedItems.where(_matchesSearch).toList();
          final archivedCount =
              assignedItems.where((item) => item.isArchive == 1).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              _searchField(context),
              _editHeader(
                totalCount: assignedItems.length,
                archivedCount: archivedCount,
                visibleCount: visibleItems.length,
              ),
              if (visibleItems.isEmpty)
                _emptySearchState()
              else ...[
                ...visibleItems.map((item) => _editItemCard(context, item)),
              ],
            ],
          );
        },
      ),
    );
  }
}
