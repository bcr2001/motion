import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/sql_tracker_db.dart';

import '../../../motion_reusable/general_reuseable.dart';

final TrackerDatabaseHelper trackDbInstance = TrackerDatabaseHelper();

//handles database operations for the MAIN CATEGORY TABLE
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

  Future<double> retrieveEntireTotalMainCategoryTable(
      String currentUser, bool isUnaccounted) async {
    double theEntireTotal = await trackDbInstance
        .getEntireTotalMainCategoryTable(currentUser, isUnaccounted);

    return theEntireTotal;
  }
}

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

  // get the total time spent for s specific subcategory
  Future<double> retrieveTotalTimeSpentSubSpecific(
      String currentDate, String currentUser, String subcategoryName) async {
    return await trackDbInstance.getTotalTimeSpentPerSubcategory(
        currentDate, currentUser, subcategoryName);
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
