import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../../motion_themes/mth_app/app_strings.dart';
import 'edit_reusable.dart';

// allows user to change the subcategory names, it's main category assignment
// and whether to archive a subcategory
class TrackEditingPage extends StatelessWidget {
  const TrackEditingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.editPageAppBarTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: SingleChildScrollView(
          child: Consumer2<AssignerMainProvider, UserUidProvider>(
            builder: (context, assigner, user, child) {
              final assignedItems = assigner.assignerItems;
              final currentUser = user.userUid;

              return Column(
                children: [
                  // what the edit page is (an explanation)
                  const InfoToTheUser(
                    sectionInformation: AppString.editPageDescription),

                  // all the items in the to_assign table
                  // for a particular user
                  ListView.builder(
                      // Disable scrolling in the ListView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignedItems.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, index) {
                        // Get the item at the current index
                        final item = assignedItems[index];

                        // Check if the current user is the owner of the item
                        return assignedItems[index].currentLoggedInUser ==
                                currentUser
                            ? ListTile(
                                // Display the index (starting from 1) as a leading number
                                leading: Text((index + 1).toString()),
                                title: Text(
                                  item.subcategoryName,
                                  style: AppTextStyle.trailingTextLTStyle(),),
                                subtitle: Text(
                                  item.mainCategoryName, 
                                  style: AppTextStyle.subtitleLTStyle(),),
                                trailing: TrailingEditButtons(
                                  // Pass item details to the TrailingEditButtons widget
                                  itemIndexDateCreated: item.dateCreated,
                                  itemIndexIsActive: item.isActive,
                                  itemIndexCurrentUser:
                                      item.currentLoggedInUser,
                                  itemIndexSubcategoryName:
                                      item.subcategoryName,
                                  itemIndexId: item.id!,
                                  itemIndexMainCategoryName:
                                      item.mainCategoryName,
                                  itemIndexIsArchive: item.isArchive,
                                ),
                              )
                            // If the current user is not the owner, hide the item
                            : const SizedBox.shrink();
                      })

                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
