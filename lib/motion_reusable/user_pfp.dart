import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motion/motion_providers/user_pfp_provider.dart';
import 'package:motion/motion_themes/app_strings.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'package:provider/provider.dart';
import 'reuseable.dart';
import 'package:image_picker/image_picker.dart';

// handles setting of the user profile picture
class UserPfp extends StatefulWidget {
  const UserPfp({super.key});

  @override
  State<UserPfp> createState() => _UserPfpState();
}

class _UserPfpState extends State<UserPfp> {
  // bottom modal sheet
  _profileModalSheetOptions(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 110,
            padding: const EdgeInsets.all(15.0),
            child: GestureDetector(
              onTap: () {
                Provider.of<UserPfpProvider>(context, listen: false)
                    .fetchUserPfpFromGallery();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // modal sheet title
                  const Padding(
                    padding:  EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child:  Text(AppString.userPfpModalProfile),
                  ),

                  // profile source (Gallary)
                  Row(
                    children: const [
                      // galley icon
                      Icon(Icons.add_photo_alternate_outlined),

                      // icon name
                      Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(AppString.userPfpModalGallery),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () {
      _profileModalSheetOptions(context);
    }, child: Consumer<UserPfpProvider>(
      builder: (context, imagePath, child) {
        return Stack(
          // pfp holder
          children: [
            CircleAvatar(
              backgroundImage: imagePath.imagePath == null
                  ? const AssetImage(
                      "assets/images/motion_icons/default_pfp.png")
                  : FileImage(File(imagePath.imagePath!.path)) as ImageProvider,
              radius: 70,
            ),

            // camera icon
            Positioned(
                bottom: 20,
                right: 5,
                child: Icon(
                  Icons.photo_camera,
                  color: blueMainColor,
                ))
          ],
        );
      },
    ));
  }
}
