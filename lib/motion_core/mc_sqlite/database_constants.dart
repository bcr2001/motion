class MotionDbTables {
  static const String mainCategory = 'main_category';
  static const String subcategory = 'subcategory';
  static const String experiencePoints = 'experience_points';
  static const String assigner = 'to_assign';
  static const String activeTimerSession = 'active_timer_session';
  static const String goals = 'goals';
  static const String goalCheckIns = 'goal_check_ins';
  static const String goalPausePeriods = 'goal_pause_periods';
  static const String timelineCollections = 'timeline_collections';
}

class MotionDbColumns {
  static const String id = 'id';
  static const String date = 'date';
  static const String currentLoggedInUser = 'currentLoggedInUser';
  static const String mainCategoryName = 'mainCategoryName';
  static const String subcategoryName = 'subcategoryName';
  static const String timeSpent = 'timeSpent';
  static const String education = 'education';
  static const String work = 'work';
  static const String skills = 'skills';
  static const String entertainment = 'entertainment';
  static const String selfDevelopment = 'selfDevelopment';
  static const String sleep = 'sleep';
  static const String educationXp = 'educationXP';
  static const String workXp = 'workXP';
  static const String skillsXp = 'skillsXP';
  static const String selfDevelopmentXp = 'sdXP';
  static const String sleepXp = 'sleepXP';
  static const String accountabilityBonusXp = 'accountabilityBonusXP';
  static const String isActive = 'isActive';
  static const String isArchive = 'isArchive';
  static const String dateCreated = 'dateCreated';
  static const String isStreakActive = 'isStreakActive';
  static const String streakType = 'streakType';
  static const String streakTargetMinutes = 'streakTargetMinutes';
  static const String streakStartDate = 'streakStartDate';
  static const String timerStartedAtEpochMs = 'timerStartedAtEpochMs';
  static const String currentSegmentStartedAtEpochMs =
      'currentSegmentStartedAtEpochMs';
  static const String completedTimerSegments = 'completedTimerSegments';
  static const String timerStatus = 'timerStatus';
  static const String timerUpdatedAtEpochMs = 'timerUpdatedAtEpochMs';
  static const String nextTimerReminderAtSeconds = 'nextTimerReminderAtSeconds';
  static const String timerTargetSeconds = 'timerTargetSeconds';
  static const String timerTargetAlertTriggered = 'timerTargetAlertTriggered';
  static const String timerMode = 'timerMode';
  static const String pomodoroPhase = 'pomodoroPhase';
  static const String pomodoroFocusSeconds = 'pomodoroFocusSeconds';
  static const String pomodoroShortBreakSeconds = 'pomodoroShortBreakSeconds';
  static const String pomodoroLongBreakSeconds = 'pomodoroLongBreakSeconds';
  static const String pomodoroTotalRounds = 'pomodoroTotalRounds';
  static const String pomodoroCurrentRound = 'pomodoroCurrentRound';
  static const String pomodoroPhaseStartedAtEpochMs =
      'pomodoroPhaseStartedAtEpochMs';
  static const String pomodoroPhaseElapsedSeconds =
      'pomodoroPhaseElapsedSeconds';
  static const String goalId = 'goalId';
  static const String goalName = 'goalName';
  static const String goalDescription = 'goalDescription';
  static const String goalStartDate = 'goalStartDate';
  static const String goalCompletionDate = 'goalCompletionDate';
  static const String goalDeadlineDate = 'goalDeadlineDate';
  static const String goalStatus = 'goalStatus';
  static const String goalCreatedAtEpochMs = 'goalCreatedAtEpochMs';
  static const String goalUpdatedAtEpochMs = 'goalUpdatedAtEpochMs';
  static const String goalPauseStartDate = 'pauseStartDate';
  static const String goalPauseResumeDate = 'resumeDate';
  static const String goalPauseReason = 'pauseReason';
  static const String timelineEntryType = 'entryType';
  static const String timelineCollectionId = 'collectionId';
  static const String timelineCollectionName = 'collectionName';
  static const String timelineCollectionCreatedAtEpochMs =
      'collectionCreatedAtEpochMs';
  static const String timelineCollectionUpdatedAtEpochMs =
      'collectionUpdatedAtEpochMs';
}

class MotionCategories {
  static const String education = 'Education';
  static const String work = 'Work';
  static const String skills = 'Skills';
  static const String entertainment = 'Entertainment';
  static const String selfDevelopment = 'Self Development';
  static const String sleep = 'Sleep';
}
