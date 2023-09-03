import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/tracker_db.dart';

final TrackerDatabaseHelper trackDbInstance = TrackerDatabaseHelper();

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
}


class SubcategoryTrackerDatabaseProvider extends ChangeNotifier {
  List<Subcategories> _currentDateSubcategories = [];

  List<Subcategories> get currentDateSubcategories => _currentDateSubcategories;

  // get subcategories tracked on the current date
  Future<void> retrieveCurrentDateSubcategories(String currentDate) async {
    _currentDateSubcategories =
        await trackDbInstance.getCurrentDateSubcategory(currentDate);

    notifyListeners();
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
