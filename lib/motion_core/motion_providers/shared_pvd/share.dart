import 'package:motion/motion_reusable/general_reuseable.dart'; // Assuming this contains your logger
import 'package:shared_preferences/shared_preferences.dart';

class DateOfBirthStorage {
  static const _keyDateOfBirth = 'date_of_birth_'; // Prefix for the key

  // Saves the date into shared preferences for the specified user
  Future<void> saveDateOfBirth(String userId, DateTime date) async {
    final key = _keyDateOfBirth + userId;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, date.toIso8601String());

    logger.i("Date Saved for user $userId: $date");
  }

  // Retrieves the date of birth from shared preferences for the specified user
  Future<DateTime?> getDateOfBirth(String userId) async {
    final key = _keyDateOfBirth + userId;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString(key);
    if (dateString != null) {
      return DateTime.parse(dateString);
    } else {
      logger.i("(getDateOfBirth): Date of birth not set for user $userId!");
      return null;
    }
  }
}
