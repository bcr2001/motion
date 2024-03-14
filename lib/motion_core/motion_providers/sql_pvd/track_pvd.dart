import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';

import '../../../main.dart';

// MAIN CATEGORY TABLE
//handles database operations for the main_category table
class MainCategoryTrackerProvider extends ChangeNotifier {
  // insert data into the main_category table
  Future<void> insertIntoMainCategoryTable(MainCategory mainCategory) async {
    await trackDbInstance.insertMainCategory(mainCategory);

    notifyListeners();
  }

  // update existing data in the main category table
  Future<void> updateExistingMainCategory(MainCategory mainCategory) async {
    await trackDbInstance.updateMainCategory(mainCategory);

    notifyListeners();
  }

  // retrieve the main category name, total for a specific day,
  // and xp earned
  Future<List<Map<String, dynamic>>> retrieveMCTotalAndXPEarned(
      {required String currentUser, required String targetDate}) async {
    return await trackDbInstance.getMCTotalAndXPEarned(
        currentUser: currentUser, targetDate: targetDate);
  }

  // Retrieve the entire total from the main category table.
  Future<double> retrieveEntireTotalMainCategoryTable(
      String currentUser, bool isUnaccounted) async {
    double theEntireTotal = await trackDbInstance
        .getEntireTotalMainCategoryTable(currentUser, isUnaccounted);

    return theEntireTotal;
  }

  // Retrieve the entire total from the main category table.
  // for the current year
  Future<double> retrieveGetEntireYearTotalMainCategoryTable(
      String currentUser, bool isUnaccounted, String currentYear) async {
    double theEntireYearTotal =
        await trackDbInstance.getEntireYearTotalMainCategoryTable(
            currentUser, isUnaccounted, currentYear);

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
            currentUser, firstDay, lastDay, isUnaccounted);

    return entireMonthTotal;
  }

  // retrieve just the unaccounted total for the month
  Future<double> accountedMonthTotal(String currentUser, String firstDay,
      String lastDay, bool isUnaccounted) async {
    return await trackDbInstance.getEntireMonthlyTotalMainCategoryTable(
        currentUser, firstDay, lastDay, isUnaccounted);
  }

  // get a table for both accounted and unaccounted values
  Future<List<Map<String, dynamic>>> retrieveMonthAccountUnaccountTable(
      String currentUser, firstDay, lastDay) async {
    return await trackDbInstance.getMonthAccountUnaccountTable(
        currentUser, firstDay, lastDay);
  }

  // retrieve the total number of days in the main_category table
  Future<int> retrievedNumberOfDays(
      {required String currentUser,
      String currentYear = "",
      bool getAllDays = true}) async {
    int numberOfDays = await trackDbInstance.getNumberOfDays(
        currentUser: currentUser,
        currentYear: currentYear,
        getAllDays: getAllDays);

    return numberOfDays;
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
            currentUser: currentUser,
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
            currentUser: currentUser, firstDay: firstDay, lastDay: lastDay);

    return resultMT;
  }

  // accounted time and unaccounted time for everyday
  // for a particular week
  Future<List<Map<String, dynamic>>> retrieveAWeekOfAccountedAndAccountedData(
      {required String currentUser,
      required String firstDatePeriod,
      required String lastDatePeriod}) async {
    return await trackDbInstance.getAWeekOfAccountedAndAccountedData(
        currentUser: currentUser,
        firstDatePeriod: firstDatePeriod,
        lastDatePeriod: lastDatePeriod);
  }

  // get the accounted and unaccounted totals broken down by year
  Future<List<Map<String, dynamic>>>
      retrieveAccountedAndUnaccountedBrokenByYears(
          {required String currentUser}) async {
    return await trackDbInstance.getAccountedAndUnaccountedBrokenByYears(
        currentUser: currentUser);
  }

  // get the accounted and unaccounted totals broken down by month
  Future<List<Map<String, dynamic>>>
      retrieveMonthDistibutionOfAccountedUnaccounted(
          {required String currentUser, required String year}) async {
    return await trackDbInstance.getMonthDistibutionOfAccountedUnaccounted(
        currentUser: currentUser, year: year);
  }

  // get yearly totals for all the main categories
  Future<List<Map<String, dynamic>>> retrieveYearlyTotalsForAllMainCatgories(
      {required String currentUser, required String year}) async {
    return await trackDbInstance.getYearlyTotalsForAllMainCatgories(
        currentUser: currentUser, year: year);
  }

  // get the totals for the 5 main categories
  Future<List<Map<String, dynamic>>> retrieveAllMainCategoryTotals(
      {required String currentUser}) async {
    return await trackDbInstance.getAllMainCategoryTotals(
        currentUser: currentUser);
  }

  // get the entire total time spent for the main category
  Future<List<Map<String, dynamic>>> retrieveEntireMainTotalTimeSpent(
      {required String currentUser}) async {
    return await trackDbInstance.getEntireMainTotalTimeSpent(
        currentUser: currentUser);
  }

  // get the daily intensity scores
  Future<List<Map<String, dynamic>>> retrieveDailyAccountedAndIntensities(
      {required String currentUser,
      String year = "",
      bool getEntireIntensity = true}) async {
    return await trackDbInstance.getDailyAccountedAndIntensities(
        currentUser: currentUser,
        year: year,
        getEntireIntensity: getEntireIntensity);
  }
}

// SUBCATEGORY TABLE
// handles database operation for the subcategory table
class SubcategoryTrackerDatabaseProvider extends ChangeNotifier {
  // a list of subcategories tracked for a specific date
  List<Subcategories> _currentDateSubcategories = [];
  List<Subcategories> get currentDateSubcategories => _currentDateSubcategories;

  // get subcategories tracked on the current date
  Future<void> retrieveCurrentDateSubcategories(
      String currentDate, String currentUser, String subcategoryName) async {
    _currentDateSubcategories = await trackDbInstance.getCurrentDateSubcategory(
      currentDate,
      currentUser,
      subcategoryName,
    );

    notifyListeners();
  }

  // retrive the total and average for each subcategory for a specific month
  Future<List<Map<String, dynamic>>> retrieveMonthTotalAndAverage(
      String currentUser,
      String startingDate,
      String endingDate,
      bool isSubcategory) async {
    return await trackDbInstance.getMonthTotalAndAverage(
        currentUser, startingDate, endingDate, isSubcategory);
  }

  // get the entire month total for all subcategories
  Future<double> retrieveMonthTotalTimeSpent(
      String currentUser, startingDate, endingDate) async {
    return await trackDbInstance.getMonthTotalTimeSpent(
        currentUser, startingDate, endingDate);
  }

  // gets the total time spent for all subcategories (current date)
  Future<double> retrieveTotalTimeSpentAllSubs(
      String currentDate, String currentUser) async {
    return await trackDbInstance.getTotalTimeForCurrentDate(
        currentDate, currentUser);
  }

  // get the total time spent for a specific subcategory
  Future<double> retrieveTotalTimeSpentSubSpecific(
      String currentDate, String currentUser, String subcategoryName) async {
    return await trackDbInstance.getTotalTimeSpentPerSubcategory(
        currentDate, currentUser, subcategoryName);
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
        currentUser: currentUser,
        isMost: isMost);
  }



  // get the subcategory totals for a specific date
  Future<List<Map<String, dynamic>>> retrieveSubcategoryTotalsForSpecificDate(
      {required String selectedDate, required String currentUser}) async {
    return await trackDbInstance.getSubcategoryTotalsForSpecificDate(
        selectedDate: selectedDate, currentUser: currentUser);
  }

  // inserting data into the subcategory table
  Future<void> insertIntoSubcategoryTable(Subcategories subcategories) async {
    await trackDbInstance.insertSubcategory(subcategories);

    notifyListeners();
  }

  // update data in the subcategory table
  Future<void> updateSubcategoryTable(Subcategories subcategories) async {
    await trackDbInstance.updateSubcategory(subcategories);

    notifyListeners();
  }

  // delete an already added subcategory
  Future<void> deleteSubcategoryEntry(int id) async {
    await trackDbInstance.deleteSubcategory(id);

    notifyListeners();
  }
}
