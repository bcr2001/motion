// minutes to respective time components
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:sqflite/sqflite.dart';

import '../../main.dart';

// returns the full time representation of minutes
// for example 150mins => 2hrs 50mins
String convertMinutesToTime(double minutes) {
  if (minutes < 60) {
    // if the minutes don't make up an hour then the format below is returned
    return '${minutes.toStringAsFixed(2)}mins';
  } else {
    // if the minutes are greater than 60 then they will be formmated
    // like below
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    // pluralism of the hr text format (hr for hour = 1 and hrs for hour > 1)
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

// converts minutes to hours if it's greater than 60
// otherwise it returns a string of minutes
String convertHoursToTimeGrid(double hours) {
  if (hours < 1) {
    double convertedHour = hours * 60;

    return "${convertedHour.toStringAsFixed(1)}M";
  } else {
    return "${hours.toStringAsFixed(2)}H";
  }
}

// converts minutes to days
String convertMinutesToDays(double minutes) {
  double toDays = minutes / (60 * 24);
  String toDaysString = toDays.toStringAsFixed(1);

  if (toDays == 1) {
    return "$toDaysString day";
  } else {
    return "$toDaysString days";
  }
}

// converts minutes to hours
String convertMinutesToHoursOnly(double minutes,
    {bool isFirstSection = false}) {
  // isFirstSection checks whether we are formatting time for regular time
  // distibution or for the accounted/ unaccounted section that appears in the
  // home page just under the daily quotes section
  final hours = minutes / 60;

  return isFirstSection
      ? "${hours.toStringAsFixed(2)}H"
      : "${hours.toStringAsFixed(2)}hrs/day";
}

// converts minutes to per month
String convertMinutesToHoursMonth(double minutes) {
  // isFirstSection checks whether we are formatting time for regular time
  // distibution or for the accounted/ unaccounted section that appears in the
  // home page just under the daily quotes section
  final hours = minutes / 60;

  return "${hours.toStringAsFixed(1)}h/day";
}

// convert hours to days
String convertHoursToDays(double minutes) {
  // takes in minutes and returns the number of days equivalent
  final days = (minutes / 60) / 24;

  return days == 1
      ? "${days.toStringAsFixed(2)} day"
      : "${days.toStringAsFixed(2)} days";
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

// Check if the date and currentLoggedInUser exist in the experience_points table
Future<bool> experiencePointsExists(String date, String currentUser) async {
  final Database db = await trackDbInstance.database;

  final expPointsExistsQuery = await db.rawQuery('''
    SELECT 1
    FROM experience_points
    WHERE date = ? AND currentLoggedInUser = ?
  ''', [date, currentUser]);
  return expPointsExistsQuery.isNotEmpty;
}
