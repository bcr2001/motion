import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppImages {
  // sign-in page images
  static final Image formlessShapeImage = getAssetImage("sign_in_graphics.png");
  static final Image welcomeToMotionImage =
      getAssetImage("welcome_to_motion.png");
  static SvgPicture devicesImage = getSvgAsset("devices.svg");

  // sign-up page images
  static final signUpImage = getSvgAsset("sign_up_graphics1.svg");
  static final signUpGraphics = getSvgAsset("sign_up_graphics.svg");
  static final signUpPfpDefaultImage = getAssetImage("default_pfp.png");
}

// png images
Image getAssetImage(String imageName) {
  const String imagesFileLocation = "assets/images/motion_icons/";
  return Image.asset("$imagesFileLocation$imageName");
}

// svg images
SvgPicture getSvgAsset(String svgName) {
  const String svgFileLocation = "assets/images/motion_icons/";

  return SvgPicture.asset("$svgFileLocation$svgName");
}
