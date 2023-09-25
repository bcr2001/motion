import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/dropDown_pvd/drop_down_pvd.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';

// the dropdown menu that appears when a user
// wants to select a main category to assign to
// a particular subcategory
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
    return Padding(
      padding: const EdgeInsets.only(left:20, right: 20),
      child: Consumer<DropDownTrackProvider>(
        builder: (context, selectedValue, child) {
          return DropdownButton(
            underline: const Padding(
              padding:  EdgeInsets.only(top: 3.0),
              child:  Divider(),
            ),
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
      ),
    );
  }
}