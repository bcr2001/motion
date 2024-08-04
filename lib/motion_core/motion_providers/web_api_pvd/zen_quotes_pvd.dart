import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../motion_reusable/general_reuseable.dart';
import '../../../motion_core/mc_api/api_requests.dart';
import '../../../motion_themes/mth_app/app_strings.dart';

// this class handles fetching and
// persisting the Zen Quote of the day
class ZenQuoteProvider extends ChangeNotifier {
  // today's quote
  String _todaysQuote = AppString.zenQuotesDefault;

  // get today's quote
  String get todaysQuote => _todaysQuote;

  // shared preferences instance
  SharedPreferences? _prefs;

  // shared preference keys
  static const quoteKey = "zenQuote";
  static const dateKey = "zenQuoteDate";

  ZenQuoteProvider() {
    initializeSharedPreferences();
  }

  // initializeSharedPreferences function
  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedQuote();
  }

  // Check the date and fetch a new quote if it's a new day
  Future<void> _checkAndFetchNewQuote() async {
    final savedDate = _prefs?.getString(dateKey);
    if (savedDate == null || !_isToday(DateTime.parse(savedDate))) {
      await fetchTodaysQuote();
    }
  }

  Future<void> fetchTodaysQuote() async {
    // fetches the Future<String> returned
    // when fetchQuote() is executed
    try {
      _todaysQuote = await fetchZenQuote();

      // save preferences
      _prefs?.setString(quoteKey, _todaysQuote);
      _prefs?.setString(dateKey, DateTime.now().toIso8601String());

      // notify listeners of changes
      notifyListeners();
    } catch (e) {
      logger.e("Error: $e");
      _todaysQuote =
          "“Time is what we want most, but what we use worst.” - William Penn";
      notifyListeners();
    }
  }

  // load saved quote
  Future<void> _loadSavedQuote() async {
    final savedQuote = _prefs?.getString(quoteKey);
    final savedDate = _prefs?.getString(dateKey);

    if (savedQuote != null &&
        savedDate != null &&
        _isToday(DateTime.parse(savedDate))) {
      _todaysQuote = savedQuote;
      // notify listeners
      notifyListeners();
    } else {
      // if it's the next day, a new quote
      // of the day is fetched
      _checkAndFetchNewQuote();
      notifyListeners();
    }
  }

  // this function checks whether it's the next day
  // or still the current date
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}
