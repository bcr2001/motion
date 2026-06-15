enum SubcategoryStreakType {
  anyTime,
  targetTime,
}

class SubcategoryStreakTypeValues {
  static const String anyTime = 'any_time';
  static const String targetTime = 'target_time';

  static SubcategoryStreakType fromStoredValue(String value) {
    return value == targetTime
        ? SubcategoryStreakType.targetTime
        : SubcategoryStreakType.anyTime;
  }

  static String toStoredValue(SubcategoryStreakType type) {
    return type == SubcategoryStreakType.targetTime ? targetTime : anyTime;
  }
}

enum SubcategoryStreakTodayStatus {
  metToday,
  atRisk,
  missed,
}

enum SubcategoryStreakHistoryRange {
  week,
  month,
  year,
}

class SubcategoryStreakHistoryRangeValues {
  static const String week = 'Week';
  static const String month = 'Month';
  static const String year = 'Year';
}

class SubcategoryStreakStatus {
  final String subcategoryName;
  final String mainCategoryName;
  final SubcategoryStreakType streakType;
  final double targetMinutes;
  final String startDate;
  final int currentStreak;
  final int bestStreak;
  final String currentStreakStartDate;
  final String bestStreakStartDate;
  final String bestStreakEndDate;
  final int metDays;
  final int totalDays;
  final double todayMinutes;
  final SubcategoryStreakTodayStatus todayStatus;

  const SubcategoryStreakStatus({
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.streakType,
    required this.targetMinutes,
    required this.startDate,
    required this.currentStreak,
    required this.bestStreak,
    required this.currentStreakStartDate,
    required this.bestStreakStartDate,
    required this.bestStreakEndDate,
    required this.metDays,
    required this.totalDays,
    required this.todayMinutes,
    required this.todayStatus,
  });
}

class SubcategoryStreakHistoryPoint {
  final String label;
  final int bestStreak;

  const SubcategoryStreakHistoryPoint({
    required this.label,
    required this.bestStreak,
  });
}

class SubcategoryStreakDay {
  final String date;
  final bool metTarget;
  final double minutesTracked;

  const SubcategoryStreakDay({
    required this.date,
    required this.metTarget,
    required this.minutesTracked,
  });
}

class SubcategoryBestStreakRun {
  final String startDate;
  final String endDate;
  final int streakLength;

  const SubcategoryBestStreakRun({
    required this.startDate,
    required this.endDate,
    required this.streakLength,
  });
}
