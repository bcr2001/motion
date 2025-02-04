// continue with google and or widgets
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

class ContinueWithGoogleOr extends StatelessWidget {
  final VoidCallback onPressed;

  const ContinueWithGoogleOr({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // continue with google
            Container(
              margin: const EdgeInsets.symmetric(vertical: 25),
              height: 45,
              decoration: BoxDecoration(
                color: AppColor.blueMainColor,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  width: 1.5
                )
                
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // google image
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AppImages.continueWithGoogleImage,
                  ),
                  
                  const Padding(
                    padding:  EdgeInsets.only(left: 45),
                    child: Text(AppString.continueWithGoogle, 
                    style: TextStyle(fontWeight: FontWeight.w600),),
                  )
      
                  // or
                ],
              ),
            ),
      
            const Text(AppString.or, style: TextStyle(fontWeight: FontWeight.w600),)
          ],
        ),
      ),
    );
  }
}
