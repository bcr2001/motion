import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppImages {
  // sign-in page images
  static final welcomeToMotionImage = getSvgAsset("sign_in_graphics.svg");

  // sign-up page images
  static final signUpImage = getSvgAsset("sign_up_graphics1.svg");
  static final signUpGraphics = getSvgAsset("sign_up_graphics.svg");
  static final signUpPfpDefaultImage = getImageAsset("default_pfp.png");

  // track list empty svg
  static final trackListEmpty = getSvgAsset("trackInfoSVG.svg");

  // report page no distribution data
  static final chartNoData = getSvgAsset("chartNotAvailable.svg");

  // no data available yet
  static final noDataAvailableYet = getSvgAsset("noData.svg");

  // image displayed when the maincategory table is completely
  // empty. This is mostly when the user first starts using the app
  static final noAnalysisGallary = getSvgAsset("analysisSVG.svg");

  // image displayed when the maincategory table is completely
  // empty. This is mostly when the user first starts using the app

  // default pfp
  static final defaultPfp = getImageAsset("motion_pfp.jpg");


  // default pfp
  static final streakFire = getImageAsset("fire.png",22,22);

  // google icon
  static final continueWithGoogleImage = getImageAsset("google_1.png", 30, 30);

  // no data available yet
  static final noTrackListAvailable = getImageAsset("trackInfo.png", 200, 200);

  // animated bar chart
  static final animatedBarChart = getImageAsset("ani_chart.gif", 30, 30);

  // 0-24 EFS badge (sloth)
  static final sloth = getImageAsset("sloth.png", 70, 70);

  // 25-49 EFS badge (Dolphine)
  static final dolphine = getImageAsset("dolphin.png", 70, 70);

  // 50-74 EFS badge (Eagle)
  static final eagle = getImageAsset("eagle.png", 70, 70);

  // 75-99 EFS badge (Dragon)
  static final dragon = getImageAsset("dragon.png", 70, 70);

  
}

// png images
Image getImageAsset(String imageName, [double? height, double? width]) {
  const String imagesFileLocation = "assets/images/motion_icons/";
  return Image.asset(
    "$imagesFileLocation$imageName",
    height: height,
    width: width,
  );
}
// png images
AssetImage getAssetImage(String imageName) {
  const String imagesFileLocation = "assets/images/motion_icons/";
  return AssetImage(
    "$imagesFileLocation$imageName",
  );
}

// svg images
SvgPicture getSvgAsset(String svgName) {
  const String svgFileLocation = "assets/images/motion_icons/";

  return SvgPicture.asset("$svgFileLocation$svgName");
}

//
class CircularSVGAvatar extends StatelessWidget {
  final String imageName;
  const CircularSVGAvatar({super.key, required this.imageName});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: getAssetImage(imageName),
    );
  }
}
