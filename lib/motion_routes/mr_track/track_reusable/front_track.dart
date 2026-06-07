import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:provider/provider.dart';

import '../track_edit/edit_page.dart';

// the dropdown menu that appears when a user
// wants to select a main category to assign to
// a particular subcategory
class MyDropdownButton extends StatefulWidget {
  final bool? isUpdate;
  final String? mainCategoryName;
  final bool usePanelStyle;

  const MyDropdownButton({
    super.key,
    this.isUpdate,
    this.mainCategoryName,
    this.usePanelStyle = false,
  });

  @override
  State<MyDropdownButton> createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {
  List<String> listItems = [
    AppString.educationMainCategory,
    AppString.workMainCategory,
    AppString.skillMainCategory,
    AppString.entertainmentMainCategory,
    AppString.selfDevelopmentMainCategory,
    AppString.sleepMainCategory,
  ];

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

  Widget _dropdownMenuItem(String categoryName) {
    final categoryColor = _categoryColor(categoryName);

    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            _categoryIcon(categoryName),
            color: categoryColor,
            size: 17,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.usePanelStyle
          ? EdgeInsets.zero
          : const EdgeInsets.only(left: 20, right: 20),
      child: Consumer<DropDownTrackProvider>(
        builder: (context, selectedValue, child) {
          final dropdown = DropdownButton(
            underline: widget.usePanelStyle
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.only(top: 3.0),
                    child: Divider(),
                  ),
            isExpanded: true,
            elevation: 0,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 24,
            value: selectedValue.selectedValue,
            hint: widget.isUpdate!
                ? Text(widget.mainCategoryName!)
                : const Text(AppString.trackDropDownHintText),
            selectedItemBuilder: widget.usePanelStyle
                ? (context) {
                    return listItems.map((String value) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList();
                  }
                : null,
            items: listItems.map((String value) {
              return DropdownMenuItem(
                value: value,
                child: widget.usePanelStyle
                    ? _dropdownMenuItem(value)
                    : Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                Provider.of<DropDownTrackProvider>(context, listen: false)
                    .changeSelectedValue(newValue);
              }
            },
          );

          if (!widget.usePanelStyle) {
            return dropdown;
          }

          return DropdownButtonHideUnderline(
            child: dropdown,
          );
        },
      ),
    );
  }
}

// popup menu button
class TrackEditPopUpMenu extends StatelessWidget {
  const TrackEditPopUpMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      color: Theme.of(context).popupMenuTheme.color,
      onSelected: (String value) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => const TrackEditingPage()));
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
              value: "edit", child: Text(AppString.editPageAppBarTitle))
        ];
      },
    );
  }
}
