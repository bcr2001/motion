import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_analytics/analytics_models.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/streak_status.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';

import 'current_user_guard.dart';
import 'tracking_data_revisions.dart';

// MAIN CATEGORY TABLE
//handles database operations for the main_category table
class MainCategoryTrackerProvider extends ChangeNotifier {
  MainCategoryTrackerProvider({
    TrackingDataRevisions? revisions,
    TrackerDatabaseHelper? databaseHelper,
  })  : trackDbInstance = databaseHelper ?? TrackerDatabaseHelper(),
        _revisions = revisions ?? TrackingDataRevisions() {
    _lastRevision = _revisions.mainCategoryRevision;
    _revisions.addListener(_handleRevisionChange);
  }

  final TrackingDataRevisions _revisions;
  final TrackerDatabaseHelper trackDbInstance;
  late int _lastRevision;

  int get refreshKey => _revisions.mainCategoryRevision;

  void _handleRevisionChange() {
    final revision = _revisions.mainCategoryRevision;
    if (revision == _lastRevision) return;

    _lastRevision = revision;
    notifyListeners();
  }

  // insert data into the main_category table
  Future<void> insertIntoMainCategoryTable(MainCategory mainCategory) async {
    await trackDbInstance.insertMainCategory(
      requireMainCategoryUser(mainCategory),
    );

    _revisions.markMainCategoryChanged();
  }

  // update existing data in the main category table
  Future<void> updateExistingMainCategory(MainCategory mainCategory) async {
    await trackDbInstance.updateMainCategory(
      requireMainCategoryUser(mainCategory),
    );

    _revisions.markMainCategoryChanged();
  }

  // retrieve the main category name, total for a specific day,
  // and xp earned
  Future<List<Map<String, dynamic>>> retrieveMCTotalAndXPEarned(
      {required String currentUser, required String targetDate}) async {
    return await trackDbInstance.getMCTotalAndXPEarned(
        currentUser: requireCurrentUser(currentUser), targetDate: targetDate);
  }

  // Retrieve the entire total from the main category table.
  Future<double> retrieveEntireTotalMainCategoryTable(
      String currentUser, bool isUnaccounted) async {
    double theEntireTotal =
        await trackDbInstance.getEntireTotalMainCategoryTable(
            requireCurrentUser(currentUser), isUnaccounted);

    return theEntireTotal;
  }

  // Retrieve the entire total from the main category table.
  // for the current year
  Future<double> retrieveGetEntireYearTotalMainCategoryTable(
      String currentUser, bool isUnaccounted, String currentYear) async {
    double theEntireYearTotal =
        await trackDbInstance.getEntireYearTotalMainCategoryTable(
            requireCurrentUser(currentUser), isUnaccounted, currentYear);

    return theEntireYearTotal;
  }

  // retrieve the current month entire acounted and unaccounted totals
  Future<double> retrieveEntireMonthlyTotalMainCategoryTable(
    String currentUser,
    String firstDay,
    String lastDay,
    bool isUnaccounted,
  ) async {
    double entireMonthTotal =
        await trackDbInstance.getEntireMonthlyTotalMainCategoryTable(
            requireCurrentUser(currentUser), firstDay, lastDay, isUnaccounted);

    return entireMonthTotal;
  }

  // retrieve just the unaccounted total for the month
  Future<double> accountedMonthTotal(String currentUser, String firstDay,
      String lastDay, bool isUnaccounted) async {
    return await trackDbInstance.getEntireMonthlyTotalMainCategoryTable(
        requireCurrentUser(currentUser), firstDay, lastDay, isUnaccounted);
  }

  // get a table for both accounted and unaccounted values
  Future<List<Map<String, dynamic>>> retrieveMonthAccountUnaccountTable(
      String currentUser, firstDay, lastDay) async {
    return await trackDbInstance.getMonthAccountUnaccountTable(
        requireCurrentUser(currentUser), firstDay, lastDay);
  }

  // retrieve the total number of days in the main_category table
  Future<int> retrievedNumberOfDays(
      {required String currentUser,
      String currentYear = "",
      bool getAllDays = true}) async {
    int numberOfDays = await trackDbInstance.getNumberOfDays(
        currentUser: requireCurrentUser(currentUser),
        currentYear: currentYear,
        getAllDays: getAllDays);

    return numberOfDays;
  }

  // retrieves the users streak
  Future<int> retrievedUserStreak({required String currentUser}) async {
    int streak = await trackDbInstance.getUserStreak(
        currentUser: requireCurrentUser(currentUser));

    return streak;
  }

  Future<SubcategoryStreakStatus> retrieveSubcategoryStreakStatus({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
  }) async {
    return await trackDbInstance.getSubcategoryStreakStatus(
      currentUser: requireCurrentUser(currentUser),
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
      streakType: streakType,
      targetMinutes: targetMinutes,
      startDate: startDate,
      currentDate: currentDate,
    );
  }

  Future<String?> retrieveFirstTrackedDateForSubcategory({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
  }) async {
    return await trackDbInstance.getFirstTrackedDateForSubcategory(
      currentUser: requireCurrentUser(currentUser),
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
    );
  }

  Future<List<SubcategoryStreakHistoryPoint>> retrieveSubcategoryStreakHistory({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
    required SubcategoryStreakHistoryRange range,
  }) async {
    return await trackDbInstance.getSubcategoryStreakHistory(
      currentUser: requireCurrentUser(currentUser),
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
      streakType: streakType,
      targetMinutes: targetMinutes,
      startDate: startDate,
      currentDate: currentDate,
      range: range,
    );
  }

  Future<List<SubcategoryBestStreakRun>> retrieveSubcategoryBestStreakRuns({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
    int limit = 9,
  }) async {
    return await trackDbInstance.getSubcategoryBestStreakRuns(
      currentUser: requireCurrentUser(currentUser),
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
      streakType: streakType,
      targetMinutes: targetMinutes,
      startDate: startDate,
      currentDate: currentDate,
      limit: limit,
    );
  }

  Future<List<SubcategoryStreakDay>> retrieveSubcategoryStreakDays({
    required String currentUser,
    required String subcategoryName,
    required String mainCategoryName,
    required SubcategoryStreakType streakType,
    required double targetMinutes,
    required String startDate,
    required String currentDate,
  }) async {
    return await trackDbInstance.getSubcategoryStreakDays(
      currentUser: requireCurrentUser(currentUser),
      subcategoryName: subcategoryName,
      mainCategoryName: mainCategoryName,
      streakType: streakType,
      targetMinutes: targetMinutes,
      startDate: startDate,
      currentDate: currentDate,
    );
  }

  // retrieve the most tracked and least tracked main category
  Future<List<Map<String, dynamic>>> retrieveMostAndLeastTrackedMainCategory(
      {required String firstDay,
      required String lastDay,
      required String currentUser,
      required bool isMost}) async {
    List<Map<String, dynamic>> result =
        await trackDbInstance.getMostAndLeastTrackedMainCategory(
            firstDay: firstDay,
            lastDay: lastDay,
            currentUser: requireCurrentUser(currentUser),
            isMost: isMost);

    return result;
  }

  // retrieve the total time time spent for
  // the main categorys during a specified period of time
  Future<List<Map<String, dynamic>>> retrieveMainTotalTimeSpentSpecificDates(
      {required String currentUser,
      required String firstDay,
      required String lastDay}) async {
    List<Map<String, dynamic>> resultMT =
        await trackDbInstance.getMainTotalTimeSpentSpecificDates(
            currentUser: requireCurrentUser(currentUser),
            firstDay: firstDay,
            lastDay: lastDay);

    return resultMT;
  }

  Future<Map<String, dynamic>> retrieveMonthlyReportSnapshot({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    return await trackDbInstance.getMonthlyReportSnapshot(
      currentUser: requireCurrentUser(currentUser),
      firstDay: firstDay,
      lastDay: lastDay,
    );
  }

  Future<List<Map<String, dynamic>>> retrieveMonthlyDailyXpTrend({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    return await trackDbInstance.getMonthlyDailyXpTrend(
      currentUser: requireCurrentUser(currentUser),
      firstDay: firstDay,
      lastDay: lastDay,
    );
  }

  Future<List<Map<String, dynamic>>> retrieveTopSubcategoriesForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
    int limit = 5,
  }) async {
    return await trackDbInstance.getTopSubcategoriesForPeriod(
      currentUser: requireCurrentUser(currentUser),
      firstDay: firstDay,
      lastDay: lastDay,
      limit: limit,
    );
  }

  Future<ReportSnapshot> retrieveReportSnapshot({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    final row = await retrieveMonthlyReportSnapshot(
      currentUser: currentUser,
      firstDay: firstDay,
      lastDay: lastDay,
    );
    return ReportSnapshot.fromMap(row);
  }

  Future<List<DailyXpPoint>> retrieveDailyXpTrendPoints({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    final rows = await retrieveMonthlyDailyXpTrend(
      currentUser: currentUser,
      firstDay: firstDay,
      lastDay: lastDay,
    );
    return rows.map(DailyXpPoint.fromMap).toList(growable: false);
  }

  Future<List<CategoryTimeTotal>> retrieveCategoryTimeTotalsForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
  }) async {
    final rows = await retrieveMainTotalTimeSpentSpecificDates(
      currentUser: currentUser,
      firstDay: firstDay,
      lastDay: lastDay,
    );
    return rows.map(CategoryTimeTotal.fromMap).toList(growable: false);
  }

  Future<List<SubcategoryTimeTotal>> retrieveTopSubcategoryTotalsForPeriod({
    required String currentUser,
    required String firstDay,
    required String lastDay,
    int limit = 5,
  }) async {
    final rows = await retrieveTopSubcategoriesForPeriod(
      currentUser: currentUser,
      firstDay: firstDay,
      lastDay: lastDay,
      limit: limit,
    );
    return rows.map(SubcategoryTimeTotal.fromMap).toList(growable: false);
  }

  // accounted time and unaccounted time for everyday
  // for a particular week
  Future<List<Map<String, dynamic>>> retrieveAWeekOfAccountedAndAccountedData(
      {required String currentUser,
      required String firstDatePeriod,
      required String lastDatePeriod}) async {
    return await trackDbInstance.getAWeekOfAccountedAndAccountedData(
        currentUser: requireCurrentUser(currentUser),
        firstDatePeriod: firstDatePeriod,
        lastDatePeriod: lastDatePeriod);
  }

  // get the accounted and unaccounted totals broken down by year
  Future<List<Map<String, dynamic>>>
      retrieveAccountedAndUnaccountedBrokenByYears(
          {required String currentUser}) async {
    return await trackDbInstance.getAccountedAndUnaccountedBrokenByYears(
        currentUser: requireCurrentUser(currentUser));
  }

  // get the accounted and unaccounted totals broken down by month
  Future<List<Map<String, dynamic>>>
      retrieveMonthDistibutionOfAccountedUnaccounted(
          {required String currentUser, required String year}) async {
    return await trackDbInstance.getMonthDistibutionOfAccountedUnaccounted(
        currentUser: requireCurrentUser(currentUser), year: year);
  }

  // get yearly totals for all the main categories
  Future<List<Map<String, dynamic>>> retrieveYearlyTotalsForAllMainCatgories(
      {required String currentUser, required String year}) async {
    return await trackDbInstance.getYearlyTotalsForAllMainCatgories(
        currentUser: requireCurrentUser(currentUser), year: year);
  }

  // get the totals for the 5 main categories
  Future<List<Map<String, dynamic>>> retrieveAllMainCategoryTotals(
      {required String currentUser}) async {
    return await trackDbInstance.getAllMainCategoryTotals(
        currentUser: requireCurrentUser(currentUser));
  }

  // get the entire total time spent for the main category
  Future<List<Map<String, dynamic>>> retrieveEntireMainTotalTimeSpent(
      {required String currentUser}) async {
    return await trackDbInstance.getEntireMainTotalTimeSpent(
        currentUser: requireCurrentUser(currentUser));
  }

  // get the daily intensity scores
  Future<List<Map<String, dynamic>>> retrieveDailyAccountedAndIntensities(
      {required String currentUser,
      String year = "",
      bool getEntireIntensity = true}) async {
    return await trackDbInstance.getDailyAccountedAndIntensities(
        currentUser: requireCurrentUser(currentUser),
        year: year,
        getEntireIntensity: getEntireIntensity);
  }

  @override
  void dispose() {
    _revisions.removeListener(_handleRevisionChange);
    super.dispose();
  }
}

// SUBCATEGORY TABLE
// handles database operation for the subcategory table
class SubcategoryTrackerDatabaseProvider extends ChangeNotifier {
  SubcategoryTrackerDatabaseProvider({
    TrackingDataRevisions? revisions,
    TrackerDatabaseHelper? databaseHelper,
  })  : trackDbInstance = databaseHelper ?? TrackerDatabaseHelper(),
        _revisions = revisions ?? TrackingDataRevisions() {
    _lastRevision = _revisions.subcategoryRevision;
    _revisions.addListener(_handleRevisionChange);
  }

  final TrackingDataRevisions _revisions;
  final TrackerDatabaseHelper trackDbInstance;
  late int _lastRevision;

  int get refreshKey => _revisions.subcategoryRevision;

  void _handleRevisionChange() {
    final revision = _revisions.subcategoryRevision;
    if (revision == _lastRevision) return;

    _lastRevision = revision;
    notifyListeners();
  }

  int refreshKeyForSubcategory({
    required String currentUser,
    required String mainCategoryName,
    required String subcategoryName,
  }) {
    return _revisions.revisionForSubcategory(
      currentUser: currentUser,
      mainCategoryName: mainCategoryName,
      subcategoryName: subcategoryName,
    );
  }

  int refreshKeyForDate({
    required String currentUser,
    required String date,
  }) {
    return _revisions.revisionForDate(
      currentUser: currentUser,
      date: date,
    );
  }

  void refreshAllTrackingData() {
    _revisions.markAllTrackingDataChanged();
  }

  // get subcategories tracked on the current date
  Future<List<Subcategories>> retrieveCurrentDateSubcategories(
      String currentDate, String currentUser, String subcategoryName) async {
    return trackDbInstance.getCurrentDateSubcategory(
      currentDate,
      requireCurrentUser(currentUser),
      subcategoryName,
    );
  }

  Future<List<Subcategories>> retrieveSubcategoryEntriesForDate({
    required String date,
    required String currentUser,
  }) async {
    return trackDbInstance.getSubcategoryEntriesForDate(
      date: date,
      currentUser: requireCurrentUser(currentUser),
    );
  }

  // retrieve the entire totals of subcategories
  Future<List<Map<String, dynamic>>> retrieveAllSubcategoryTotals(
      {required currentUser}) async {
    return await trackDbInstance.getAllSubcategoryTotals(
        currentUser: requireCurrentUser(currentUser));
  }

  Future<Map<int, String>> retrieveAwardEarnedDates({
    required String currentUser,
    required List<int> requiredHours,
  }) async {
    return await trackDbInstance.getAwardEarnedDates(
      currentUser: requireCurrentUser(currentUser),
      requiredHours: requiredHours,
    );
  }

  // retrive the total and average for each subcategory for a specific month
  Future<List<Map<String, dynamic>>> retrieveMonthTotalAndAverage(
      String currentUser,
      String startingDate,
      String endingDate,
      bool isSubcategory) async {
    return await trackDbInstance.getMonthTotalAndAverage(
        requireCurrentUser(currentUser),
        startingDate,
        endingDate,
        isSubcategory);
  }

  // get the entire month total for all subcategories
  Future<double> retrieveMonthTotalTimeSpent(
      String currentUser, String startingDate, String endingDate) async {
    return await trackDbInstance.getMonthTotalTimeSpent(
        requireCurrentUser(currentUser), startingDate, endingDate);
  }

  // gets the total time spent for all subcategories (current date)
  Future<double> retrieveTotalTimeSpentAllSubs(
      String currentDate, String currentUser) async {
    return await trackDbInstance.getTotalTimeForCurrentDate(
        currentDate, requireCurrentUser(currentUser));
  }

  Future<Map<String, double>> retrieveSubcategoryTotalsForDate(
      String currentDate, String currentUser) async {
    return await trackDbInstance.getSubcategoryTotalsForDate(
      currentDate: currentDate,
      currentUser: requireCurrentUser(currentUser),
    );
  }

  // get the total time spent for a specific subcategory
  Future<double> retrieveTotalTimeSpentSubSpecific(
      String currentDate, String currentUser, String subcategoryName) async {
    return await trackDbInstance.getTotalTimeSpentPerSubcategory(
        currentDate, requireCurrentUser(currentUser), subcategoryName);
  }

  // get the least and most tracked subcategory
  Future<List<Map<String, dynamic>>> retrieveMostAndLeastTrackedSubcategory(
      {required String firstDay,
      required String lastDay,
      required String currentUser,
      required bool isMost}) async {
    return await trackDbInstance.getMostAndLeastTrackedSubcategory(
        firstDay: firstDay,
        lastDay: lastDay,
        currentUser: requireCurrentUser(currentUser),
        isMost: isMost);
  }

  // get the subcategory totals for a specific date
  Future<List<Map<String, dynamic>>> retrieveSubcategoryTotalsForSpecificDate(
      {required String selectedDate, required String currentUser}) async {
    return await trackDbInstance.getSubcategoryTotalsForSpecificDate(
        selectedDate: selectedDate,
        currentUser: requireCurrentUser(currentUser));
  }

  // inserting data into the subcategory table
  Future<int> insertIntoSubcategoryTable(Subcategories subcategories) async {
    final guardedSubcategory = requireSubcategoryUser(subcategories);
    final insertedId =
        await trackDbInstance.insertSubcategory(guardedSubcategory);
    guardedSubcategory.id = insertedId;

    _revisions.markSubcategoryChanged(guardedSubcategory);
    return insertedId;
  }

  Future<List<Subcategories>> completeActivityTimer({
    required String currentUser,
    required List<Subcategories> entries,
  }) async {
    final guardedEntries = entries.map(requireSubcategoryUser).toList();
    final insertedIds = await trackDbInstance.completeActiveTimerSession(
      currentUser: requireCurrentUser(currentUser),
      entries: guardedEntries,
    );

    for (var index = 0; index < guardedEntries.length; index++) {
      guardedEntries[index].id = insertedIds[index];
      _revisions.markSubcategoryChanged(guardedEntries[index]);
    }
    return guardedEntries;
  }

  // update data in the subcategory table
  Future<void> updateSubcategoryTable(Subcategories subcategories) async {
    final guardedSubcategory = requireSubcategoryUser(subcategories);
    await trackDbInstance.updateSubcategory(guardedSubcategory);

    _revisions.markSubcategoryChanged(guardedSubcategory);
  }

  // delete an already added subcategory
  Future<void> deleteSubcategoryEntry(
    int id, {
    Subcategories? deletedSubcategory,
  }) async {
    await trackDbInstance.deleteSubcategory(id);

    if (deletedSubcategory != null) {
      _revisions.markSubcategoryChanged(deletedSubcategory);
    }
  }

  @override
  void dispose() {
    _revisions.removeListener(_handleRevisionChange);
    super.dispose();
  }
}
