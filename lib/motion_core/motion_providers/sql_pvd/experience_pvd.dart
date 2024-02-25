import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../mc_sql_table/experience_table.dart';

// EXPERIENCE POINT TABLE
// handles database operations for the experience_points table
class ExperiencePointTableProvider extends ChangeNotifier {
  /// Inserts an ExperiencePoints object into the database.
  ///
  /// This function delegates the insertion operation to the `insertExperiencePoint` method
  /// of the `trackDbInstance`. It's designed to abstract the database insertion logic and
  /// provide a clean interface for inserting ExperiencePoints data.
  ///
  /// Param:
  ///   - `experience`: The ExperiencePoints object to be inserted into the database.
  Future<void> insertIntoExperiencePoint(ExperiencePoints experience) async {
    await trackDbInstance.insertExperiencePoint(experience);
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
        currentUser: currentUser);
  }

  /// (year)
  Future<double> retrieveYearExperiencePointsEfficiencyScore(
      {required String currentUser, required String currentYear}) async {
    return await trackDbInstance.entireYearExperiencePointsEfficiencyScore(
        currentUser: currentUser, currentYear: currentYear);
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
        currentUser: currentUser,
        firstDayOfMonth: firstDayOfMonth,
        lastDayOfMonth: lastDayOfMonth);
  }

  // gets the daily experience points earned
  Future<int> retrieveDailyExperiencePoints(
      {required currentUser, required String selectedDate}) async {
    return await trackDbInstance.dailyExperiencePoints(
        currentUser: currentUser, selectedDate: selectedDate);
  }
}
