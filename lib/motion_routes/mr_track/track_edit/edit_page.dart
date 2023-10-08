import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:provider/provider.dart';

import '../../../motion_themes/mth_app/app_strings.dart';
import 'edit_reusable.dart';

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
                  // what the edit page is
                  const Text(
                    AppString.editPageDescription,
                    style: TextStyle(fontSize: 15),
                  ),

                  // all the items in the to_assign table
                  // for a particular user
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignedItems.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, index) {
                        final item = assignedItems[index];

                        return assignedItems[index].currentLoggedInUser ==
                                currentUser
                            ? ListTile(
                                leading: Text((index+1).toString()),
                                title:
                                    Text(item.subcategoryName),
                                subtitle:
                                    Text(item.mainCategoryName),
                                trailing: TrailingEditButtons(
                                  itemIndexDateCreated: item.dateCreated,
                                  itemIndexIsActive: item.isActive,
                                  itemIndexCurrentUser: item.currentLoggedInUser,
                                  itemIndexSubcategoryName: item.subcategoryName,
                                  itemIndexId: item.id!,
                                  itemIndexMainCategoryName: item.mainCategoryName,
                                )
                            ): const SizedBox.shrink();
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
