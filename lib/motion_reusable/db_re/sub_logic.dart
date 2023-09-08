// minutes to respective time components
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';

// returns the full time representation of minutes
// for example 150mins => 2hrs 50mins
String convertMinutesToTime(double minutes) {
  if (minutes < 60) {
    return '${minutes.toStringAsFixed(2)}mins';
  } else {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    final combinedResult = hours == 1
        ? '${hours}hr ${remainingMinutes.toStringAsFixed(0)}mins'
        : '${hours}hrs ${remainingMinutes.toStringAsFixed(0)}mins';

    final combinedRemainingMinutes = hours == 1 ? '${hours}hr' : '${hours}hrs';

    if (remainingMinutes == 0) {
      return combinedRemainingMinutes;
    } else {
      return combinedResult;
    }
  }
}

String convertMinutesToHoursOnly(double minutes) {
  final hours = minutes / 60;

  return "${hours.toStringAsFixed(2)}hrs/day";
}

// time measurement adder
// converts all non-mintutes time components adds them and returns a minute value
double timeAdder({required String h, required String m, required String s}) {
  double hours = double.parse(h) * 60;
  double minutes = double.parse(m);
  double seconds = double.parse(s) / 60;

  double addedTimeComponents = hours + minutes + seconds;

  // Format the result to two decimal places
  String formattedTime = addedTimeComponents.toStringAsFixed(2);

  logger.i(formattedTime);

  // Parse the formatted string back to double if needed
  return double.parse(formattedTime);
}

// Check if the date and currentLoggedInUser exist in the main category table
Future<bool> mainCategoryExists(String date, String currentUser) async {
  final Database db = await trackDbInstance.database;

  final mainCategoryExistsQuery = await db.rawQuery('''
    SELECT 1
    FROM main_category
    WHERE date = ? AND currentLoggedInUser = ?
  ''', [date, currentUser]);
  return mainCategoryExistsQuery.isNotEmpty;
}
