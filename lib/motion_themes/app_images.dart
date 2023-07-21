import 'package:flutter/material.dart';

Image getAssetImage(String imageName) {
  const String imagesFileLocation = "assets/images/motion_icons/";
  return Image.asset("$imagesFileLocation$imageName");
}

class AppImages {
  // sign in page images
  static Image formlessShapeImage = getAssetImage("sign_in_graphics.png");
  static Image welcomeToMotionImage = getAssetImage("welcome_to_motion.png");
  static Image devicesImage = getAssetImage("devices.png");

  // sign up page images
  static Image signUpImage = getAssetImage("sign_up_graphics.png");
}
