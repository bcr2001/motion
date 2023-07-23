import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'reuseable.dart';
import 'package:image_picker/image_picker.dart';

class UserPfp extends StatefulWidget {
  XFile? imagePath;
  final ImagePicker picker;

   UserPfp({super.key, required this.imagePath, required this.picker});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Profile Picture"),

                // profile source (Gallary)
                Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          logger.i("getting from gallary");
                          final XFile? selectedImage = await widget.picker
                              .pickImage(source: ImageSource.gallery);
                          setState(() {
                            widget.imagePath = selectedImage;
                          });
                        },
                        icon: const Icon(Icons.photo)),
                    const Text("Gallary")
                  ],
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _profileModalSheetOptions(context);
      },
      child: Stack(
        // pfp holder
        children: [
          CircleAvatar(
            backgroundImage: widget.imagePath == null
                ? const AssetImage("assets/images/motion_icons/default_pfp.png")
                : FileImage(File(widget.imagePath!.path)) as ImageProvider,
            radius: 70,
          ),

          // camera icon
          Positioned(
              bottom: 20, right: 5, child: Icon(Icons.photo_camera, color: blueMainColor,))
        ],
      ),
    );
  }
}
