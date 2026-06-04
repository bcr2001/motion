import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

class MotionXpPolicy {
  static const int maxDailyXp = 110;

  static int productiveXp(int totalMinutes, {required int dailyCap}) {
    if (totalMinutes <= 0) {
      return 0;
    }

    final earned = totalMinutes ~/ 15;
    return earned > dailyCap ? dailyCap : earned;
  }

  static int sleepXp(int totalMinutes) {
    if (totalMinutes < 300) {
      return 0;
    }
    if (totalMinutes < 360) {
      return 8;
    }
    if (totalMinutes < 420) {
      return 15;
    }
    if (totalMinutes <= 540) {
      return 25;
    }
    if (totalMinutes <= 600) {
      return 15;
    }

    return 5;
  }

  static int categoryXp(String mainCategoryName, int totalMinutes) {
    switch (mainCategoryName) {
      case MotionCategories.work:
        return productiveXp(totalMinutes, dailyCap: 25);
      case MotionCategories.education:
      case MotionCategories.skills:
      case MotionCategories.selfDevelopment:
        return productiveXp(totalMinutes, dailyCap: 20);
      case MotionCategories.sleep:
        return sleepXp(totalMinutes);
      case MotionCategories.entertainment:
      default:
        return 0;
    }
  }
}
