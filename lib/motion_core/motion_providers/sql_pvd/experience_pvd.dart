import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';
import '../../mc_sql_table/experience_table.dart';
import 'current_user_guard.dart';
import 'tracking_data_revisions.dart';

// EXPERIENCE POINT TABLE
// handles database operations for the experience_points table
class ExperiencePointTableProvider extends ChangeNotifier {
  ExperiencePointTableProvider({
    TrackingDataRevisions? revisions,
    TrackerDatabaseHelper? databaseHelper,
  })  : trackDbInstance = databaseHelper ?? TrackerDatabaseHelper(),
        _revisions = revisions ?? TrackingDataRevisions() {
    _lastRevision = _revisions.experiencePointRevision;
    _revisions.addListener(_handleRevisionChange);
  }

  final TrackingDataRevisions _revisions;
  final TrackerDatabaseHelper trackDbInstance;
  late int _lastRevision;

  int get refreshKey => _revisions.experiencePointRevision;

  void _handleRevisionChange() {
    final revision = _revisions.experiencePointRevision;
    if (revision == _lastRevision) return;

    _lastRevision = revision;
    notifyListeners();
  }

  void refreshExperiencePointViews() {
    _revisions.markExperiencePointsChanged();
  }

  /// Inserts an ExperiencePoints object into the database.
  ///
  /// This function delegates the insertion operation to the `insertExperiencePoint` method
  /// of the `trackDbInstance`. It's designed to abstract the database insertion logic and
  /// provide a clean interface for inserting ExperiencePoints data.
  ///
  /// Param:
  ///   - `experience`: The ExperiencePoints object to be inserted into the database.
  Future<void> insertIntoExperiencePoint(ExperiencePoints experience) async {
    await trackDbInstance.insertExperiencePoint(
      requireExperienceUser(experience),
    );

    refreshExperiencePointViews();
  }

  /// Retrieves the average daily efficiency score for a specified user.
  /// This function acts as a wrapper around the database query to fetch the efficiency score,
  /// encapsulating the database logic and providing a clean interface for the UI components.
  ///
  /// Params:
  ///   - `currentUser`: The identifier (ID) of the user for whom the score is being retrieved.
  /// Returns a `Future<double>` representing the user's average efficiency score.
  /// (entire)
  Future<double> retrieveExperiencePointsEfficiencyScore(
      {required String currentUser}) async {
    return await trackDbInstance.entireExperiencePointsEfficiencyScore(
        currentUser: requireCurrentUser(currentUser));
  }

  /// (year)
  Future<double> retrieveYearExperiencePointsEfficiencyScore(
      {required String currentUser, required String currentYear}) async {
    return await trackDbInstance.entireYearExperiencePointsEfficiencyScore(
        currentUser: requireCurrentUser(currentUser), currentYear: currentYear);
  }

  /// Retrieves the average monthly efficiency score for a specified user within a given date range.
  /// This function wraps around the database query in `trackDbInstance` to calculate the efficiency score,
  /// streamlining the process of fetching this data for UI components or other business logic.
  ///
  /// Params:
  ///   - `currentUser`: The ID of the user for whom the score is being calculated.
  ///   - `firstDayOfMonth`: The starting date of the month for the calculation.
  ///   - `lastDayOfMonth`: The ending date of the month for the calculation.
  /// Returns a `Future<double>` representing the user's monthly average efficiency score.
  Future<double> retrieveMonthlyEfficiencyScore(
      {required String currentUser,
      required String firstDayOfMonth,
      required String lastDayOfMonth}) async {
    return await trackDbInstance.monthlyEfficiencyScore(
        currentUser: requireCurrentUser(currentUser),
        firstDayOfMonth: firstDayOfMonth,
        lastDayOfMonth: lastDayOfMonth);
  }

  // gets the daily experience points earned
  Future<int> retrieveDailyExperiencePoints(
      {required currentUser, required String selectedDate}) async {
    return await trackDbInstance.dailyExperiencePoints(
        currentUser: requireCurrentUser(currentUser),
        selectedDate: selectedDate);
  }

  Future<Map<String, int>> retrieveDailyExperiencePointBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    return await trackDbInstance.dailyExperiencePointBreakdown(
      currentUser: requireCurrentUser(currentUser),
      selectedDate: selectedDate,
    );
  }

  Future<Map<String, double>> retrieveDailyMainCategoryTimeBreakdown({
    required String currentUser,
    required String selectedDate,
  }) async {
    return await trackDbInstance.dailyMainCategoryTimeBreakdown(
      currentUser: requireCurrentUser(currentUser),
      selectedDate: selectedDate,
    );
  }

  // retrieves the most and least productive months
  // based on the experience points earned for a particular year
  Future<List<Map<String, dynamic>>> retrieveMostAndLeastProductiveMonths(
      {required bool getMostProductiveMonth,
      required String currentUser,
      required String year}) async {
    return await trackDbInstance.getMostAndLeastProductiveMonths(
        getMostProductiveMonth: getMostProductiveMonth,
        currentUser: requireCurrentUser(currentUser),
        year: year);
  }

  // retrieve the most and least productive days based on
  // experience points earned for a particular point
  Future<List<Map<String, dynamic>>> retrieveMostAndLeastProductiveDays(
      {required String currentUser,
      required String firstDay,
      required String lastDay,
      required bool getMostProductiveDay}) async {
    return await trackDbInstance.getMostAndLeastProductiveDays(
        currentUser: requireCurrentUser(currentUser),
        firstDay: firstDay,
        lastDay: lastDay,
        getMostProductiveDay: getMostProductiveDay);
  }

  // retreieves either the total XP for the current year
  // or the all time total XP
  Future<int> retrieveTotalXP(
      {required String currentUser,
      required bool isEntire,
      String? year}) async {
    return await trackDbInstance.getTotalXP(
        currentUser: requireCurrentUser(currentUser),
        isEntire: isEntire,
        year: year);
  }

  Future<int> retrieveYearExperiencePointDays({
    required String currentUser,
    required String year,
  }) async {
    return await trackDbInstance.getYearExperiencePointDays(
      currentUser: requireCurrentUser(currentUser),
      year: year,
    );
  }

  @override
  void dispose() {
    _revisions.removeListener(_handleRevisionChange);
    super.dispose();
  }
}
