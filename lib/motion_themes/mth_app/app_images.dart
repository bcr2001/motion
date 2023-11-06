import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppImages {
  // sign-in page images
  static final welcomeToMotionImage = getSvgAsset("sign_in_graphics.svg");

  // sign-up page images
  static final signUpImage = getSvgAsset("sign_up_graphics1.svg");
  static final signUpGraphics = getSvgAsset("sign_up_graphics.svg");
  static final signUpPfpDefaultImage = getAssetImage("default_pfp.png");

  // track list empty svg
  static final trackListEmpty = getSvgAsset("trackInfoSVG.svg");

  // default pfp
  static final defaultPfp = getAssetImage("motion_pfp.jpg");

  // google icon
  static final continueWithGoogleImage = getAssetImage("google_1.png", 30, 30);

  // no data available yet
  static final noDataAvailableYet = getAssetImage("question.png", 140,140);

  // no data available yet
  static final noTrackListAvailable = getAssetImage("trackInfo.png", 200,200);
}

// png images
Image getAssetImage(String imageName, [double? height, double? width]) {
  const String imagesFileLocation = "assets/images/motion_icons/";
  return Image.asset(
    "$imagesFileLocation$imageName",
    height: height,
    width: width,
  );
}

// svg images
SvgPicture getSvgAsset(String svgName) {
  const String svgFileLocation = "assets/images/motion_icons/";

  return SvgPicture.asset("$svgFileLocation$svgName");
}